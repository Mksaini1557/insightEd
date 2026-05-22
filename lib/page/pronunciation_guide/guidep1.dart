import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../../widgets/touch_reader.dart';

class PronunciationGuide extends StatefulWidget {
  const PronunciationGuide({super.key});

  @override
  State<PronunciationGuide> createState() => _PronunciationGuideState();
}

class _PronunciationGuideState extends State<PronunciationGuide> {
  final FlutterTts _flutterTts = FlutterTts();
  final FlutterSoundRecord _recorder = FlutterSoundRecord();
  bool _isRecording = false;
  bool _ttsReady = false;
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
    if (mounted) setState(() => _ttsReady = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is List<String> && args.isNotEmpty) {
      _quotes = args;
    } else {
      _quotes = ['Welcome to insightED. Let us start learning together.'];
    }
  }

  void _announcePage() {
    if (_hasSpoken || !_ttsReady) return;
    _hasSpoken = true;
    final currentQuote = _pageNo < _quotes.length ? _quotes[_pageNo] : 'No quote available';
    _flutterTts.speak(
      'Pronunciation Guide. The sentence is: $currentQuote. '
      'Tap the microphone button to record yourself. Slide your finger to explore options.',
    );
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.start(path: path);
      setState(() => _isRecording = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path != null && mounted) {
        _flutterTts.stop();
        Navigator.pushNamed(context, 'Vguide2', arguments: {
          'path': path,
          'quote': _quotes[_pageNo],
          'pageNo': _pageNo,
          'quotes': _quotes,
        });
      }
    } catch (e) {
      setState(() => _isRecording = false);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQuote = _pageNo < _quotes.length ? _quotes[_pageNo] : 'No quote available';
    WidgetsBinding.instance.addPostFrameCallback((_) => _announcePage());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pronunciation Guide'),
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
            icon: const Icon(Icons.headset_mic),
            tooltip: 'Voice Assistant',
            onPressed: () {
              _flutterTts.stop();
              Navigator.pushNamed(context, 'VoiceAssistant');
            },
          ),
        ],
      ),
      body: TouchReader(
        tts: _flutterTts,
        child: Container(
          color: const Color(0xFFE8ECFF),
          child: Column(
            children: [
              Expanded(
                flex: 3,
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
                        currentQuote,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white, height: 1.6),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Read the sentence and record yourself',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 24),
                    TouchableZone(
                      label: _isRecording ? 'Stop recording' : 'Tap to start recording',
                      child: SizedBox(
                        width: 220,
                        height: 60,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording ? Colors.red : const Color(0xFF009688),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (_isRecording) {
                              _stopRecording();
                            } else {
                              _startRecording();
                            }
                          },
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 26, color: Colors.white),
                          label: Text(
                            _isRecording ? 'STOP RECORDING' : 'START RECORDING',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isRecording ? 'Recording... Tap to stop' : 'Tap the mic to start recording',
                      style: TextStyle(fontSize: 16, color: _isRecording ? Colors.red : Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_pageNo > 0)
                          TouchableZone(
                            label: 'Previous quote',
                            child: TextButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _pageNo--;
                                  _hasSpoken = false;
                                });
                              },
                              icon: const Icon(Icons.arrow_back, color: Color(0xFF4A6CF7)),
                              label: const Text('Previous', style: TextStyle(color: Color(0xFF4A6CF7))),
                            ),
                          ),
                        const SizedBox(width: 24),
                        if (_pageNo < _quotes.length - 1)
                          TouchableZone(
                            label: 'Next quote',
                            child: TextButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _pageNo++;
                                  _hasSpoken = false;
                                });
                              },
                              icon: const Icon(Icons.arrow_forward, color: Color(0xFF4A6CF7)),
                              label: const Text('Next', style: TextStyle(color: Color(0xFF4A6CF7))),
                            ),
                          ),
                      ],
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
}
