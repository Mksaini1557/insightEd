import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import '../../widgets/touch_reader.dart';

class TalkInsightEd1 extends StatefulWidget {
  const TalkInsightEd1({super.key});

  @override
  State<TalkInsightEd1> createState() => _TalkInsightEd1State();
}

class _TalkInsightEd1State extends State<TalkInsightEd1> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _hasSpoken = false;
  bool _ttsReady = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
    if (mounted) setState(() => _ttsReady = true);
  }

  void _announcePage() {
    if (_hasSpoken || !_ttsReady) return;
    _hasSpoken = true;
    _flutterTts.speak(
      'Talk with insightED. Two options. Option one: Talk to insightED Professional — coming soon. '
      'Option two: Talk to insightED Mitra — your AI voice assistant with web search. Tap or slide to select.',
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _announcePage());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Talk with insightED'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Repeat',
            onPressed: () {
              _hasSpoken = false;
              _announcePage();
            },
          ),
        ],
      ),
      body: TouchReader(
        tts: _flutterTts,
        child: Container(
          color: const Color(0xFFF5F7FA),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble, size: 80, color: Color(0xFF009688)),
                const SizedBox(height: 24),
                const Text('Choose your conversation partner',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A6CF7))),
                const SizedBox(height: 8),
                const Text('Practice speaking with different AI partners',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 48),
                SizedBox(
                  width: 280,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A6CF7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: null,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text('Talk to insightED Professional',
                              style: TextStyle(fontSize: 13, color: Colors.white70)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TouchableZone(
                  label: 'Talk to insightED Mitra - AI voice assistant',
                  child: SizedBox(
                    width: 250,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _flutterTts.stop();
                        Navigator.pushNamed(context, 'VoiceAssistant');
                      },
                      child: const Text('Talk to insightED Mitra',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
