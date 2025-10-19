import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService instance = TtsService._internal();
  factory TtsService() => instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool isTtsOn = true;

  Future<void> init() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> setTtsEnabled(bool value) async {
    isTtsOn = value;
    if (!value) {
      await _flutterTts.stop();
    }
  }

  Future<void> speak(String text) async {
    if (!isTtsOn) return; // 🧠 respect global toggle
    if (text.trim().isEmpty) return;

    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
