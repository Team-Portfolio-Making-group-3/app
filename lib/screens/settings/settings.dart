// File: lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/customize_appbar.dart';
import '../authentication/welcome_screen.dart';
import 'about_screen.dart';
import '../../service/tts_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isTtsOn = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initialize TTS
    TtsService.instance.init().then((_) {
      setState(() {
        isTtsOn = TtsService.instance.isTtsOn;
      });
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleTts(bool value) async {
    setState(() {
      isTtsOn = value;
    });
    await TtsService.instance.setTtsEnabled(value);

    if (value) {
      await TtsService.instance.speak("Text to Speech is turned on");
    } else {
      await TtsService.instance.stop();
    }
  }

  void _logout() async {
    await TtsService.instance.speak("Logging out");
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 120;

    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                // Text to Speech Card
                _buildSettingsOption(
                  iconPath: "assets/images/gemini-icon.png", // Replace with your PNG
                  color: const Color(0xFF6C63FF),
                  title: "Text to Speech",
                  height: cardHeight,
                  trailingWidget: Switch(
                    value: isTtsOn,
                    onChanged: _toggleTts,
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.grey,
                  ),
                  isToggle: true,
                ),

                // About Card
                _buildSettingsOption(
                  iconPath: "assets/images/about.png", // Replace with your PNG
                  color: Colors.grey[700]!,
                  title: "About",
                  height: cardHeight,
                  onTap: () {
                    TtsService.instance.speak("Opening About Page");
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),

                // Logout Card
                _buildSettingsOption(
                  iconPath: "assets/images/logout-icon.png", // Replace with your PNG
                  color: Colors.red[700]!,
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
    required String iconPath,
    required Color color,
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
          TtsService.instance.speak("Opening $title");
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
            // PNG icon container
            Container(
              height: double.infinity,
              width: 90,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    iconPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            trailingWidget ??
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
