import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import '../widgets/customize_appbar.dart';
import 'map_screen.dart';


class MainFeatureScreen extends StatefulWidget {
  const MainFeatureScreen({super.key});

  @override
  State<MainFeatureScreen> createState() => _MainFeatureScreenState();
}

class _MainFeatureScreenState extends State<MainFeatureScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  bool isCameraInitialized = false;

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

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModel();
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras!.isNotEmpty) {
      _cameraController =
          CameraController(cameras![0], ResolutionPreset.medium);
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
    _cameraController = CameraController(
      cameras![selectedCameraIndex],
      ResolutionPreset.medium,
    );
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
    for (var obj in objects) if (!ttsQueue.contains(obj)) ttsQueue.add(obj);
    if (isSpeaking) return;
    while (ttsQueue.isNotEmpty && ttsEnabled) {
      isSpeaking = true;
      final obj = ttsQueue.removeAt(0);
      await flutterTts.speak(obj);
      await flutterTts.awaitSpeakCompletion(true);
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
          // Camera preview with overlay buttons
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

                  // Draw detected objects
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ObjectPainter(objects: detectedObjects),
                    ),
                  ),

                  // Feature buttons inside camera
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
                          icon: Icons.audiotrack,
                          label: "Audio",
                          color: Colors.green[700]!,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Audio clicked")),
                            );
                          },
                          size: buttonSize,
                        ),
                        _buildFeatureButton(
                          icon: Icons.wb_sunny,
                          label: "Weather",
                          color: Colors.orange[700]!,
                          onTap: () => launchUrl(Uri.parse('https://weather.com')),
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

// Simple painter for object detection
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
