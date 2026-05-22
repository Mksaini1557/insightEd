import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../../widgets/touch_reader.dart';

class Pronunciation2 extends StatefulWidget {
  const Pronunciation2({super.key});

  @override
  State<Pronunciation2> createState() => _Pronunciation2State();
}

class _Pronunciation2State extends State<Pronunciation2> {
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordingPath;
  String _currentQuote = '';
  int _pageNo = 0;
  late List<String> _quotes;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _recordingPath = args['path'] as String?;
      _currentQuote = args['quote'] as String? ?? '';
      _pageNo = args['pageNo'] as int? ?? 0;
      _quotes = (args['quotes'] as List<dynamic>?)?.cast<String>() ?? [_currentQuote];
    }
  }

  void _announcePage() {
    if (_hasSpoken) return;
    _hasSpoken = true;
    _flutterTts.speak(
      'Review your pronunciation. Four options available. Back, Next, Listen to insightED, and Listen to your recording. '
      'Slide your finger to explore options.',
    );
  }

  Future<void> _speakQuote() async {
    if (_currentQuote.isNotEmpty) {
      await _flutterTts.speak(_currentQuote);
    }
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(_recordingPath!));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to play recording'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _goToNext() {
    if (_pageNo + 1 < _quotes.length) {
      Navigator.pushReplacementNamed(context, 'Vguide1', arguments: _quotes);
    } else {
      Navigator.pushNamed(context, 'home');
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _announcePage());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Pronunciation'),
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
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6CF7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      _currentQuote,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white, height: 1.6),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildButton('Back', Icons.arrow_back, const Color(0xFF757575), () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  }),
                  _buildButton('Next', Icons.arrow_forward, const Color(0xFF4A6CF7), () {
                    HapticFeedback.lightImpact();
                    _goToNext();
                  }),
                  _buildButton('Listen to insightED', Icons.volume_up, const Color(0xFF009688), () {
                    HapticFeedback.lightImpact();
                    _speakQuote();
                  }),
                  _buildButton('Listen to your recording', Icons.play_circle_fill, const Color(0xFFFF5722), () {
                    HapticFeedback.lightImpact();
                    _playRecording();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return TouchableZone(
      label: label,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 36, color: Colors.white),
                const SizedBox(height: 8),
                Text(label, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
