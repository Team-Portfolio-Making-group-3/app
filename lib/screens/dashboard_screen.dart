import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/screens/settings.dart';
import 'package:app/screens/main_feature_screen.dart';
import 'package:app/widgets/customize_appbar.dart'; // Make sure this imports CustomAppBar // Yellow circular back button

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      // Use the custom rounded blue AppBar
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 30),
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
                    // Handle history tap
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildMainWidget(context),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildMainWidget(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainFeatureScreen()),
        );
      },
      child: Container(
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
    );
  }
}
