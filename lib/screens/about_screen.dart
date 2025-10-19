// File: lib/screens/about_screen.dart
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // consistent background
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF), // main app theme color
        title: const Text('About'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.info_outline,
                size: 80,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 30),

            // App Name
            const Text(
              'GuideWay',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 10),

            // Tagline
            const Text(
              'Smart Stick with Real-Time Alerts',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 30),

            // About Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Text(
                      'About This App',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'GuideWay is designed to assist visually impaired users by providing real-time alerts for obstacles, potholes, and other hazards. Using advanced object detection and TTS feedback, it ensures safer navigation and enhanced independence.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Version Info
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.black45),
            ),
            const SizedBox(height: 10),

            // Contact Info
            const Text(
              'Contact: support@guideway.com',
              style: TextStyle(color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}
