import 'history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'settings.dart';
import 'main_feature_screen.dart';
import '../widgets/customize_appbar.dart';
import '../service/tts_service.dart'; // <-- Import global TTS service

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoadingMain = false; // Loading state for main feature

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: const CustomAppBar(),
          body: Column(
            children: [
              // Top row with Settings and History buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSquareButton(
                      icon: Icons.settings,
                      text: 'Settings',
                      onTap: () {
                        TtsService.instance.speak("You're clicking Settings");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                    _buildSquareButton(
                      icon: Icons.history,
                      text: 'History',
                      onTap: () {
                        TtsService.instance.speak("You're clicking History");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HistoryScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Main "Tap to Get Started" button
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildMainWidget(context),
                ),
              ),
            ],
          ),
        ),

        // Full-screen loading overlay
        if (_isLoadingMain)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 6,
              ),
            ),
          ),
      ],
    );
  }

  // Reusable square button with TTS
  Widget _buildSquareButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          color: const Color(0xFF004C85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 85, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // Main feature button with loading
  Widget _buildMainWidget(BuildContext context) {
    return GestureDetector(
      onTap: _isLoadingMain
          ? null
          : () async {
        setState(() => _isLoadingMain = true);
        TtsService.instance.speak("Clicking to get started");

        double progress = 0.0; // Track model progress

        // Example: simulate a feature with progress updates
        // Replace this with your real model execution logic
        while (progress < 1.0) {
          await Future.delayed(const Duration(milliseconds: 300));
          progress += 0.1;

          if (!mounted) return;
          setState(() {}); // Trigger rebuild to update loading UI
        }

        if (!mounted) return;
        setState(() => _isLoadingMain = false);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainFeatureScreen()),
        );
      },
      child: Stack(
        children: [
          // Main button
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF3198E6),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF004C85).withOpacity(0.3),
                width: 3,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, size: 120, color: Colors.white),
                SizedBox(height: 30),
                Text(
                  'Tap to Get Started',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),

          // Dynamic loading overlay
          if (_isLoadingMain)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
