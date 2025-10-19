import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ For environment variables
import 'firebase_options.dart';

// MAIN FUNCTION
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter engine is ready

  // ✅ Load environment variables from .env before Firebase initialization
  await dotenv.load(fileName: ".env");

  // ✅ Initialize Firebase using environment-aware configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Launch your app
  runApp(const MyApp());
}

// SIMPLE APP WIDGET
class MyApp extends StatelessWidget {
  const MyApp({super.key}); // ✅ Add a key constructor for best practice

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Portfolio Making Group 3',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Firebase Connection Test'),
          backgroundColor: Colors.deepPurple, // Optional: add theme color
        ),
        body: const Center(
          child: Text(
            '✅ Firebase Connected Successfully!',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
