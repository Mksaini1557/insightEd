import 'package:flutter_tts/flutter_tts.dart';

class TtsHelper {
  static final TtsHelper _instance = TtsHelper._internal();
  factory TtsHelper() => _instance;
  TtsHelper._internal();

  final FlutterTts tts = FlutterTts();
  bool ready = false;

  Future<void> init() async {
    if (ready) return;
    try {
      await tts.setLanguage('en-US');
      await tts.setPitch(1.0);
      await tts.setSpeechRate(0.45);
      ready = true;
    } catch (_) {
      // TTS not available on this device
      ready = false;
    }
  }

  Future<void> speak(String text) async {
    if (!ready) await init();
    if (!ready) return;
    try {
      await tts.stop();
      await tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try { await tts.stop(); } catch (_) {}
  }
}
