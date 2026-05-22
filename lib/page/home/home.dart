import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import '../../widgets/touch_reader.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      'insightED home. Four options. Top-left: Topic Quiz. Top-right: insightED Mitra. '
      'Bottom-left: insightED Gyan. Bottom-right: Games.',
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
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset('assets/logo.jpg'),
        ),
        title: const Text('insightED'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Repeat',
            onPressed: () {
              _hasSpoken = false;
              _announcePage();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _flutterTts.stop();
              if (mounted) await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: TouchReader(
        tts: _flutterTts,
        child: Container(
          color: const Color(0xFFF5F7FA),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFE8ECFF),
                child: const Text(
                  'insightED — Learn Without Limits',
                  style: TextStyle(fontSize: 14, color: Color(0xFF2A3F8F), height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                  children: [
                    _buildButton(
                      label: 'Topic Quiz',
                      icon: Icons.quiz,
                      color: const Color(0xFF4A6CF7),
                      onTap: () {
                        _flutterTts.stop();
                        Navigator.pushNamed(context, 'TopicQuiz');
                      },
                    ),
                    _buildButton(
                      label: 'insightED Mitra',
                      icon: Icons.headset_mic,
                      color: const Color(0xFF009688),
                      onTap: () {
                        _flutterTts.stop();
                        Navigator.pushNamed(context, 'VoiceAssistant');
                      },
                    ),
                    _buildButton(
                      label: 'insightED Gyan',
                      icon: Icons.menu_book,
                      color: const Color(0xFFFF5722),
                      onTap: () {
                        _flutterTts.stop();
                        Navigator.pushNamed(context, 'vocogyan');
                      },
                    ),
                    _buildButton(
                      label: 'Games',
                      icon: Icons.sports_esports,
                      color: const Color(0xFF7C4DFF),
                      onTap: () {
                        _flutterTts.stop();
                        Navigator.pushNamed(context, 'Games');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
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
            Future.delayed(const Duration(milliseconds: 300), onTap);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
