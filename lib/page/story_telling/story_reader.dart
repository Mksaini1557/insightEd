import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import '../../widgets/touch_reader.dart';

class StoryReader extends StatefulWidget {
  final Map<String, dynamic> storyData;
  const StoryReader({super.key, required this.storyData});

  @override
  State<StoryReader> createState() => _StoryReaderState();
}

class _StoryReaderState extends State<StoryReader> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _hasSpoken = false;
  bool _ttsReady = false;
  bool _isReading = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isReading = false);
    });
  }

  void _announcePage() {
    if (_hasSpoken || !_ttsReady) return;
    _hasSpoken = true;
    final title = widget.storyData['title'] ?? 'Untitled';
    _flutterTts.speak('$title. Tap Read Aloud to listen to this story.');
  }

  void _readStory() {
    if (_isReading) {
      _flutterTts.stop();
      setState(() => _isReading = false);
      return;
    }
    final title = widget.storyData['title'] as String? ?? '';
    final content = widget.storyData['content'] as String? ?? '';
    if (content.isEmpty) {
      _flutterTts.speak('No story content available.');
      return;
    }
    _flutterTts.stop();
    setState(() => _isReading = true);
    _flutterTts.speak('$title. $content');
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.storyData['title'] as String? ?? 'Untitled Story';
    final content = widget.storyData['content'] as String? ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _announcePage());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Story'),
        actions: [
          IconButton(
            icon: Icon(_isReading ? Icons.stop : Icons.volume_up),
            tooltip: _isReading ? 'Stop' : 'Read aloud',
            onPressed: _readStory,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Repeat info',
            onPressed: () { _hasSpoken = false; _announcePage(); },
          ),
        ],
      ),
      body: TouchReader(
        tts: _flutterTts,
        child: Container(
          color: const Color(0xFFF5F7FA),
          child: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A6CF7), height: 1.3)),
                  const SizedBox(height: 24),
                  Text(content.isNotEmpty ? content : 'No content available.',
                      style: const TextStyle(fontSize: 18, height: 1.8, color: Color(0xFF212121))),
                ]),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE8ECFF),
                border: Border(top: BorderSide(color: Color(0xFF4A6CF7))),
              ),
              child: Row(children: [
                Expanded(
                  child: TouchableZone(
                    label: _isReading ? 'Stop reading' : 'Read story aloud',
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isReading ? Colors.red : const Color(0xFF4A6CF7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () { HapticFeedback.lightImpact(); _readStory(); },
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(_isReading ? Icons.stop : Icons.volume_up, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(_isReading ? 'STOP' : 'READ ALOUD',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TouchableZone(
                    label: 'Go back to stories',
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('BACK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
