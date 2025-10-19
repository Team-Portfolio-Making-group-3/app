// File: lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'welcome_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isTtsOn = false;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
  }

  void _toggleTts(bool value) {
    setState(() {
      isTtsOn = value;
    });
    if (isTtsOn) {
      flutterTts.speak("Text to Speech is turned on");
    } else {
      flutterTts.stop();
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double cardHeight = 120;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Rounded AppBar without extra whitespace
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
                  "Settings",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cards
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildSettingsOption(
                  color: const Color(0xFF6C63FF),
                  icon: Icons.record_voice_over,
                  title: "Text to Speech",
                  height: cardHeight,
                  trailingWidget: Switch(
                    value: isTtsOn,
                    onChanged: _toggleTts,
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.grey,
                  ),
                  isToggle: true, // toggles when card tapped
                ),
                _buildSettingsOption(
                  color: Colors.grey[700]!,
                  icon: Icons.info,
                  title: "About",
                  height: cardHeight,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),
                _buildSettingsOption(
                  color: Colors.red[700]!,
                  icon: Icons.logout,
                  title: "Log Out",
                  height: cardHeight,
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption({
    required Color color,
    required IconData icon,
    required String title,
    double height = 120,
    Widget? trailingWidget,
    VoidCallback? onTap,
    bool isToggle = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isToggle) {
          _toggleTts(!isTtsOn);
        } else if (onTap != null) {
          onTap();
        }
      },
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: double.infinity,
              width: 90,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            if (trailingWidget != null)
              trailingWidget
            else
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.arrow_forward_ios),
              ),
          ],
        ),
      ),
    );
  }
}
