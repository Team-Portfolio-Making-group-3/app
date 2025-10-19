import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:url_launcher/url_launcher.dart';

class MainFeatureScreen extends StatefulWidget {
  const MainFeatureScreen({super.key});

  @override
  State<MainFeatureScreen> createState() => _MainFeatureScreenState();
}

class _MainFeatureScreenState extends State<MainFeatureScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras!.isNotEmpty) {
      _cameraController =
          CameraController(cameras![0], ResolutionPreset.medium);
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cameraHeight = screenHeight * 0.8; // 80% of the screen
    final buttonSize = 70.0; // Slightly smaller buttons to fit

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Custom AppBar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF2C4B7A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFFFDC843),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Main Features",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Camera Box with buttons inside
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [
                  // Camera Container
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
                      child: isCameraInitialized
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CameraPreview(_cameraController!),
                      )
                          : const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),

                  // Buttons overlaid inside camera box
                  Positioned(
                    bottom: 70,
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
                            launchUrl(Uri.parse('https://www.google.com/maps'));
                          },
                          size: buttonSize,
                        ),
                        _buildFeatureButton(
                          icon: Icons.audiotrack,
                          label: "Audio",
                          color: Colors.green[700]!,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Audio feature clicked")),
                            );
                          },
                          size: buttonSize,
                        ),
                        _buildFeatureButton(
                          icon: Icons.wb_sunny,
                          label: "Weather",
                          color: Colors.orange[700]!,
                          onTap: () {
                            launchUrl(Uri.parse('https://weather.com'));
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
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
