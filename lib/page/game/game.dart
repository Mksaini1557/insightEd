import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import '../../widgets/touch_reader.dart';

class Games extends StatefulWidget {
  const Games({super.key});

  @override
  State<Games> createState() => _GamesState();
}

class _GamesState extends State<Games> {
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
      'Games section. Three games available. '
      'Story Telling, Memory Match, and Number Guess. '
      'Slide your finger to explore options.',
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
        title: const Text('Games'),
        actions: [
          IconButton(icon: const Icon(Icons.volume_up), tooltip: 'Repeat',
            onPressed: () { _hasSpoken = false; _announcePage(); },
          ),
        ],
      ),
      body: TouchReader(
        tts: _flutterTts,
        child: Container(
          color: const Color(0xFFF5F7FA),
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.0,
            children: [
              _buildButton(
                label: 'Story Telling',
                icon: Icons.auto_stories,
                color: const Color(0xFF4A6CF7),
                route: 'StoryTelling',
              ),
              _buildButton(
                label: 'Memory Match',
                icon: Icons.psychology,
                color: const Color(0xFF009688),
                route: 'MemoryMatch',
              ),
              _buildButton(
                label: 'Number Guess',
                icon: Icons.casino,
                color: const Color(0xFFFF5722),
                route: 'NumberGuess',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({required String label, required IconData icon, required Color color, required String route}) {
    return TouchableZone(
      label: label,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _flutterTts.speak(label);
            _flutterTts.stop();
            Navigator.pushNamed(context, route);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(label, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3)),
            ]),
          ),
        ),
      ),
    );
  }
}
