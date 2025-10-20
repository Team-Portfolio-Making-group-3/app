import 'package:flutter/material.dart';
import '../../widgets/customize_appbar.dart'; // adjust if path differs

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Lumo logo
            Image.asset(
              "assets/images/img.png",
              height: 140,
            ),
            const SizedBox(height: 20),

            // About Lumo title
            const Text(
              "About Lumo",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              "Lumo is an innovative AI-powered smart stick designed to assist visually impaired individuals with safer and more independent mobility. Using real-time object detection powered by YOLOv11n and TensorFlow Lite, Lumo identifies obstacles, potholes, vehicles, and other hazards. Through voice alerts and vibration feedback, users are instantly notified of nearby dangers. Integrated with Flutter and Firebase, it enables route tracking, caregiver monitoring, and hazard reporting — building a smarter, safer navigation experience for everyone.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 30),

            // Mission Section
            _buildCardSection(
              title: "Mission",
              content:
              "To empower visually impaired individuals with real-time environmental awareness through intelligent assistive technology. "
                  "Lumo’s mission is to reduce navigation-related risks, enhance mobility confidence, and promote independent, inclusive, and safe movement for every user.",
            ),
            const SizedBox(height: 20),

            // Vision Section
            _buildCardSection(
              title: "Vision",
              content:
              "To create a world where technology removes barriers, enabling every person — regardless of visual ability — to navigate freely, confidently, and safely. "
                  "Lumo envisions a connected community supported by AI-powered tools that make streets smarter, caregivers more informed, and society more inclusive.",
            ),
            const SizedBox(height: 30),

            // Developers Section
            const Text(
              "Developers",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Meet the team behind Lumo — a group of developers, designers, and innovators dedicated to accessibility, AI, and human-centered design.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 30),

            // Row 1: Arron + Francoise
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDeveloperCard(
                  name: "Arron Kian Parejas",
                  role: "Full Stack & AI/ML Engineer",
                  image: "assets/images/arron.jpeg",
                ),
                _buildDeveloperCard(
                  name: "Francoise Christine Gurango",
                  role: "UI/UX & Front-End Developer",
                  image: "assets/images/coise.jpg",
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row 2: Graciella + Prince
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDeveloperCard(
                  name: "Graciella Mhervie Jimenez",
                  role: "Project Manager & UI/UX Designer",
                  image: "assets/images/ella.JPG",
                ),
                _buildDeveloperCard(
                  name: "Prince Pamintuan",
                  role: "UI Designer",
                  image: "assets/images/prince.jpg",
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row 3: Kalel (centered)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDeveloperCard(
                  name: "Kalel Marquez",
                  role: "Front-End Developer",
                  image: "assets/images/kalel.jpg",
                ),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // Mission/Vision Card widget
  static Widget _buildCardSection({
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF3B5B92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style:
            const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  // Developer Card
  static Widget _buildDeveloperCard({
    required String name,
    required String role,
    required String image,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFF3B5B92),
            backgroundImage: AssetImage(image),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            role,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
