import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'weather_screen.dart';
import 'dart:math' as math;
import '../../widgets/customize_appbar.dart';
import 'map_screen.dart';
import 'assistant_screen.dart';

class MainFeatureScreen extends StatefulWidget {
  final String? destinationName;
  final LatLng? destinationLatLng;

  const MainFeatureScreen({super.key, this.destinationName, this.destinationLatLng});

  @override
  State<MainFeatureScreen> createState() => _MainFeatureScreenState();
}

class _MainFeatureScreenState extends State<MainFeatureScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  bool isCameraInitialized = false;
  bool _assistantActive = false;

  // Object detection
  final FlutterVision vision = FlutterVision();
  List<Map<String, dynamic>> detectedObjects = [];
  bool isDetecting = false;
  bool isStreaming = false;

  // TTS
  final FlutterTts flutterTts = FlutterTts();
  bool ttsEnabled = true;
  List<String> ttsQueue = [];
  bool isSpeaking = false;

  // Vibration
  bool vibrationEnabled = true;
  bool isVibrating = false;

  // Camera switching
  int selectedCameraIndex = 0;

  // Confidence threshold
  double confThreshold = 0.4;

  // Tracking
  LatLng? currentLocation;
  double distance = 0;
  String direction = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModel();
    if (widget.destinationLatLng != null) _startTracking();
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras!.isNotEmpty) {
      _cameraController = CameraController(cameras![0], ResolutionPreset.medium);
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => isCameraInitialized = true);
    }
  }

  Future<void> _loadModel() async {
    await vision.loadYoloModel(
      modelPath: "assets/models/yolov11n.tflite",
      labels: "assets/models/labels.txt",
      modelVersion: "yolov11",
      quantization: false,
      numThreads: 2,
      useGpu: true,
    );
  }

  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.isEmpty) return;
    selectedCameraIndex = (selectedCameraIndex + 1) % cameras!.length;
    await _cameraController?.dispose();
    _cameraController = CameraController(cameras![selectedCameraIndex], ResolutionPreset.medium);
    await _cameraController!.initialize();
    if (isStreaming) _startDetection();
    setState(() {});
  }

  void _startDetection() {
    if (_cameraController?.value.isStreamingImages ?? false) return;
    setState(() => isStreaming = true);

    _cameraController?.startImageStream((CameraImage image) async {
      if (isDetecting) return;
      isDetecting = true;

      try {
        final results = await vision.yoloOnFrame(
          bytesList: image.planes.map((e) => e.bytes).toList(),
          imageHeight: image.height,
          imageWidth: image.width,
          iouThreshold: 0.4,
          confThreshold: confThreshold,
          classThreshold: 0.5,
        );

        if (!mounted) return;

        // Flip bounding boxes for front camera
        if (selectedCameraIndex == 1) {
          for (var res in results) {
            final box = res['box'];
            final x1 = box[0];
            final x2 = box[2];
            box[0] = image.width - x2;
            box[2] = image.width - x1;
          }
        }

        setState(() => detectedObjects = List<Map<String, dynamic>>.from(results));

        _speakObjects(detectedObjects.map((e) => e['tag'] as String).toList());

        // Vibrate on large objects
        bool largeDetected = false;
        for (var obj in detectedObjects) {
          final box = obj['box'];
          final boxHeight = (box[3] - box[1]) / image.height;
          if (boxHeight > 0.9) {
            largeDetected = true;
            break;
          }
        }
        if (largeDetected && vibrationEnabled && !isVibrating) {
          isVibrating = true;
          _continuousVibrate();
        } else if (!largeDetected && isVibrating) {
          isVibrating = false;
        }
      } catch (e) {
        print("Detection error: $e");
      } finally {
        isDetecting = false;
      }
    });
  }

  Future<void> _stopDetection() async {
    if (_cameraController?.value.isStreamingImages ?? false) {
      await _cameraController?.stopImageStream();
      setState(() {
        isStreaming = false;
        detectedObjects.clear();
        ttsQueue.clear();
        isVibrating = false;
      });
    }
  }

  Future<void> _speakObjects(List<String> objects) async {
    if (!ttsEnabled || objects.isEmpty) return;

    for (var obj in objects) {
      if (!ttsQueue.contains(obj)) ttsQueue.add(obj);
    }

    if (isSpeaking) return;

    while (ttsQueue.isNotEmpty && ttsEnabled) {
      isSpeaking = true;
      final obj = ttsQueue.removeAt(0);
      if (ttsEnabled) {
        await flutterTts.speak(obj);
        await flutterTts.awaitSpeakCompletion(true);
      }
    }

    isSpeaking = false;
  }


  Future<void> _continuousVibrate() async {
    while (isVibrating && isStreaming) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 100);
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  void _startTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position pos) {
      if (widget.destinationLatLng == null) return;
      setState(() {
        currentLocation = LatLng(pos.latitude, pos.longitude);
        distance = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          widget.destinationLatLng!.latitude,
          widget.destinationLatLng!.longitude,
        );
        direction = _calculateDirection(currentLocation!, widget.destinationLatLng!);
      });
    });
  }

  String _calculateDirection(LatLng start, LatLng end) {
    final dy = end.latitude - start.latitude;
    final dx = end.longitude - start.longitude;
    final angle = (math.atan2(dy, dx) * 180 / math.pi) % 360;

    if (angle >= 45 && angle < 135) return "N";
    if (angle >= 135 && angle < 225) return "W";
    if (angle >= 225 && angle < 315) return "S";
    return "E";
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    vision.closeYoloModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cameraHeight = screenHeight * 0.65;
    final buttonSize = 70.0;

    if (!isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: cameraHeight,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  ),
                  // Object detection overlay
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ObjectPainter(objects: detectedObjects),
                    ),
                  ),
                  // Tracking overlay
                  if (widget.destinationName != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tracking: ${widget.destinationName}",
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if (currentLocation != null)
                              Text(
                                "Distance: ${distance.toStringAsFixed(1)} m | Direction: $direction",
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              )
                            else
                              const Text(
                                "Getting location...",
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                          ],
                        ),
                      ),
                    ),
                  // Feature buttons
                  Positioned(
                    bottom: 150,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeatureButton(
                          icon: Icons.map,
                          label: "Map",
                          color: Colors.blue[700]!,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MapScreen()),
                            );
                          },
                          size: buttonSize,
                        ),
                        _buildFeatureButton(
                          icon: ttsEnabled ? Icons.volume_up : Icons.volume_off,
                          label: ttsEnabled ? "Audio On" : "Muted",
                          color: ttsEnabled ? Colors.green[700]! : Colors.grey[700]!,
                          onTap: () async {
                            setState(() => ttsEnabled = !ttsEnabled);

                            if (!ttsEnabled) {
                              // Stop current speech if muting
                              await flutterTts.stop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("🔇 Audio muted")),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("🔊 Audio enabled")),
                              );
                            }
                          },
                          size: buttonSize,
                        ),

                        _buildFeatureButton(
                          icon: Icons.wb_sunny,
                          label: "Weather",
                          color: Colors.orange[700]!,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const WeatherScreen()),
                            );
                          },
                          size: buttonSize,
                        ),
// 2️⃣ Update your button
                  _buildFeatureButton(
                  icon: Icons.smart_toy,
                    label: "Assistant",
                    color: _assistantActive ? Colors.green : Colors.red,
                    onTap: () async {
                      setState(() => _assistantActive = true); // Turn button green

                      // Create the assistant helper using the existing camera controller
                      AssistantHelper helper = AssistantHelper(cameraController: _cameraController!);

                      // Start the assistant
                      await helper.startAssistant();

                      // After finishing, turn the button back to red
                      setState(() => _assistantActive = false);
                    },
                    size: buttonSize,
                  ),

                ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isStreaming ? _stopDetection : _startDetection,
        backgroundColor: isStreaming ? Colors.red : Colors.green,
        child: Icon(isStreaming ? Icons.stop : Icons.play_arrow),
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: size / 2, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// Object painter stays the same
class ObjectPainter extends CustomPainter {
  final List<Map<String, dynamic>> objects;
  ObjectPainter({required this.objects});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var obj in objects) {
      final box = obj['box'];
      final label = obj['tag'];
      final conf = obj['confidence'] ?? 0.0;
      final confidence = (conf * 100).toStringAsFixed(1);

      final left = box[0].toDouble();
      final top = box[1].toDouble();
      final right = box[2].toDouble();
      final bottom = box[3].toDouble();

      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);

      final bgPaint = Paint()..color = Colors.green.withOpacity(0.6);
      final span = TextSpan(
        text: '$label $confidence%',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      );
      textPainter.text = span;
      textPainter.layout();

      canvas.drawRect(
          Rect.fromLTWH(left, top - 18, textPainter.width + 6, 16), bgPaint);
      textPainter.paint(canvas, Offset(left + 3, top - 16));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
