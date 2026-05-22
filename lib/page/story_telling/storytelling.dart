import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class StoryTelling extends StatefulWidget {
  const StoryTelling({super.key});

  @override
  State<StoryTelling> createState() => _StoryTellingState();
}

class _StoryTellingState extends State<StoryTelling> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _hasSpoken = false;

  final List<Map<String, dynamic>> _stories = [
    {'title': 'The Potato, The Egg, And The Coffee Beans', 'color': const Color(0xFFFFC107)},
    {'title': 'The Lion And The Mouse', 'color': const Color(0xFF2196F3)},
    {'title': 'The MilkMaid And Her Pail', 'color': const Color(0xFF4CAF50)},
    {'title': 'Two Frogs With The Same Problem', 'color': const Color(0xFFE53935)},
  ];

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
    final titles = _stories.map((s) => s['title'] as String).join('. Story two: ');
    _flutterTts.speak(
      'Story Telling. Four stories available. Story one: $titles. Tap any story to read it.',
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
        title: const Text('Story Telling'),
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
          childAspectRatio: 0.9,
          children: _stories.map((story) {
            return Material(
              color: story['color'] as Color,
              borderRadius: BorderRadius.circular(16),
              elevation: 4,
              child: InkWell(
                onTap: () {
                  _flutterTts.stop();
                  Navigator.pushNamed(context, 'StoryTelling2');
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_stories, size: 40, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        (story['title'] as String).replaceAll('\n', ' '),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
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
          }).toList(),
        ),
      ),
    );
  }
}
