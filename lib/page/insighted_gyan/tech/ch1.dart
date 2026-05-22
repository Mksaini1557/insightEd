import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import '../../../widgets/touch_reader.dart';

class Technical extends StatefulWidget {
  const Technical({super.key});

  @override
  State<Technical> createState() => _TechnicalState();
}

class _TechnicalState extends State<Technical> {
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
      'Technical Courses. Four courses available. DSA, C plus plus, C, and Flutter. Slide your finger to explore options.',
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
        title: const Text('Technical Courses'),
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
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.0,
            children: [
              _buildButton('DSA - Data Structures', Icons.account_tree, const Color(0xFF4A6CF7),
                  () => Navigator.pushNamed(context, 'dsa')),
              _buildButton('C plus plus', Icons.code, const Color(0xFF009688),
                  () => Navigator.pushNamed(context, 'ComingSoon')),
              _buildButton('C', Icons.terminal, const Color(0xFFFF5722),
                  () => Navigator.pushNamed(context, 'ComingSoon')),
              _buildButton('Flutter', Icons.flutter_dash, const Color(0xFF7C4DFF),
                  () => Navigator.pushNamed(context, 'ComingSoon')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return TouchableZone(
      label: label,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _flutterTts.stop();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(label.replaceAll(' - ', '\n'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
