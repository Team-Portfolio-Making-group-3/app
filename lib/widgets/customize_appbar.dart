import 'package:flutter/material.dart';

class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: Colors.yellow,
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          Navigator.pop(context);
        },
        child: const Padding(
          padding: EdgeInsets.all(12.0),
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Stack(
        children: [
          // Background container with rounded bottom corners
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFF004E89), // Blue color
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          // AppBar content
          SafeArea(
            child: Stack(
              children: [
                // Back button on the left
                const Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: BackButtonWidget(),
                ),
                // Centered image + text
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // so it wraps tightly around content
                    children: [
                      Image.asset(
                        'assets/images/luma.PNG',
                        width: 50,
                        height: 50,
                      ),
                      const SizedBox(width: 6), // small space between image and text
                      const Text(
                        "Lumo",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}

// Example usage in a Scaffold
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: const Center(child: Text("Home Screen")),
    );
  }
}
