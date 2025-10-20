import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class AssistantHelper {
  final CameraController cameraController;
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();

  bool _isListening = false;
  bool _isSpeaking = false;

  // Gemini
  static const String GEMINI_API_KEY = "AIzaSyABa_hinTbT-zYeJsjpzU5HNZb05YE8zSQ";

  AssistantHelper({required this.cameraController}) {
    tts.setLanguage("en-US");
    tts.setPitch(1.0);
    tts.setSpeechRate(0.5);
    tts.setCompletionHandler(() {
      _isSpeaking = false;
    });
  }

  Future<void> _handlePrompt(String prompt) async {
    await tts.speak("Got it, processing your question...");
    _isSpeaking = true;

    while (_isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await sendToGemini(prompt);
  }


  Future<void> startAssistant() async {
    // Step 1: Ask user for a question
    await tts.speak("What's your question?");
    _isSpeaking = true;

    // Wait for speech to finish
    while (_isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Step 2: Initialize listening
    bool available = await speech.initialize();
    if (!available) return;

    _isListening = true;

    String lastRecognized = "";
    DateTime lastHeardTime = DateTime.now();

    // Start listening
    speech.listen(onResult: (val) async {
      if (val.recognizedWords.isEmpty) return;

      lastRecognized = val.recognizedWords;
      lastHeardTime = DateTime.now();

      // When speech ends (final result or silence timer), handle prompt
      if (val.finalResult) {
        _isListening = false;
        await _handlePrompt(lastRecognized);
      }
    });

    // Background silence checker
    while (_isListening) {
      await Future.delayed(const Duration(seconds: 1));
      final elapsed = DateTime.now().difference(lastHeardTime).inSeconds;
      if (elapsed >= 3 && lastRecognized.isNotEmpty) {
        // Stop listening due to silence
        _isListening = false;
        speech.stop();
        await _handlePrompt(lastRecognized);
        break;
      }
    }
  }


  Future<void> sendToGemini(String prompt) async {
    // Optionally capture camera image
    File? imageFile;
    try {
      final xFile = await cameraController.takePicture();
      imageFile = File(xFile.path);
    } catch (_) {
      imageFile = null;
    }

    List contents = [];
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final base64Data = base64Encode(bytes);
      contents.add({
        "parts": [
          {"inline_data": {"mime_type": "image/jpeg", "data": base64Data}}
        ]
      });
    }
    contents.add({"parts": [{"text": prompt}]});

    final payload = {"contents": contents};
    final uri = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$GEMINI_API_KEY");

    try {
      final response = await http.post(uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(payload));

      String geminiReply = "I couldn't get a response.";
      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        if (jsonResp['candidates'] != null) {
          geminiReply = (jsonResp['candidates'] as List)
              .map((c) => c['content']?['parts']?[0]?['text'] ?? "")
              .join("\n");
        }
      }

      // Step 3: Speak Gemini reply
      await tts.speak(geminiReply);
      _isSpeaking = true;
    } catch (e) {
      await tts.speak("There was an error: $e");
    }
  }
}
