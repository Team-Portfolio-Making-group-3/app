import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthOptionScreen extends StatefulWidget {
  const AuthOptionScreen({super.key});

  @override
  State<AuthOptionScreen> createState() => _AuthOptionScreenState();
}

class _AuthOptionScreenState extends State<AuthOptionScreen>
    with SingleTickerProviderStateMixin {
  bool _logoAtTop = false;

  @override
  void initState() {
    super.initState();
    // Animate logo to top after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _logoAtTop = true;
      });
    });
  }

  // Build button with optional color
  Widget _buildButton(String text, Widget targetScreen, {Color? buttonColor}) {
    return Container(
      width: 300,
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: buttonColor ?? Colors.yellow[700],
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 600),
              pageBuilder: (_, __, ___) => targetScreen,
              transitionsBuilder: (_, animation, __, child) {
                final tween =
                Tween(begin: const Offset(0, 1), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeOut));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ),
          );
        },
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004E89),
      body: Stack(
        children: [
          // Animated logo at top center
          AnimatedAlign(
            alignment: _logoAtTop ? const Alignment(0, -0.9) : Alignment.center,
            duration: const Duration(seconds: 1),
            curve: Curves.easeOut,
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Image.asset(
                'assets/images/luma.PNG',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Buttons remain centered
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100), // spacing so logo doesn't overlap
                _buildButton(
                  'Sign Up',
                  const SignUpScreen(),
                  buttonColor: const Color(0xFFFAE59E), // custom yellow for Sign Up
                ),
                _buildButton(
                  'Login',
                  const LoginScreen(), // default yellow
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
