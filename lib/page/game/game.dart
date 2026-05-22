import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Games extends StatefulWidget {
  const Games({super.key});

  @override
  State<Games> createState() => _GamesState();
}

class _GamesState extends State<Games> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _hasSpoken = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
  }

  void _announcePage() {
    if (_hasSpoken) return;
    _hasSpoken = true;
    _flutterTts.speak(
      'Games section. Four games available. '
      'Story Telling, Animal Sounds, Word Puzzle, and Memory Match. '
      'Some games are coming soon. Tap any game to play.',
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
      body: Container(
        color: const Color(0xFFF5F7FA),
        child: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0,
          children: [
            _GameButton(
              title: 'Story Telling',
              icon: Icons.auto_stories,
              color: const Color(0xFF4A6CF7),
              onTap: () {
                _flutterTts.stop();
                Navigator.pushNamed(context, 'StoryTelling2');
              },
            ),
            _GameButton(
              title: 'Animal Sounds',
              icon: Icons.pets,
              color: const Color(0xFF009688),
              onTap: () {
                _flutterTts.stop();
                Navigator.pushNamed(context, 'ComingSoon');
              },
            ),
            _GameButton(
              title: 'Word Puzzle',
              icon: Icons.extension,
              color: const Color(0xFFFF5722),
              onTap: () {
                _flutterTts.stop();
                Navigator.pushNamed(context, 'ComingSoon');
              },
            ),
            _GameButton(
              title: 'Memory Match',
              icon: Icons.memory,
              color: const Color(0xFF7C4DFF),
              onTap: () {
                _flutterTts.stop();
                Navigator.pushNamed(context, 'ComingSoon');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GameButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GameButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
