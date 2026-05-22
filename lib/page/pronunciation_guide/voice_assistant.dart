import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import '../../widgets/touch_reader.dart';

class VoiceAssistant extends StatefulWidget {
  const VoiceAssistant({super.key});

  @override
  State<VoiceAssistant> createState() => _VoiceAssistantState();
}

class _VoiceAssistantState extends State<VoiceAssistant> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _ttsReady = false;
  bool _speechEnabled = false;
  bool _isSearching = false;
  String _userText = '';
  String _assistantResponse = '';
  String _source = '';
  bool _hasWelcomed = false;

  final Map<String, String> _greetings = {
    'hello': 'Hello! I am insightED Mitra. I search the web to answer your questions. Ask me anything!',
    'hi': 'Hi there! What would you like to learn about today?',
    'what is your name': 'I am insightED Mitra, your AI voice assistant.',
    'thank you': 'You are welcome! Keep learning and growing.',
    'bye': 'Goodbye! Come back anytime.',
    'help': 'Tap the Speak button and ask any question. I will search the web and speak the answer.',
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  void _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {},
      onError: (error) {},
    );
    setState(() {});
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.1);
    await _flutterTts.setSpeechRate(0.48);
    if (mounted) setState(() => _ttsReady = true);
  }

  void _announceWelcome() {
    if (_hasWelcomed || !_ttsReady) return;
    _hasWelcomed = true;
    _flutterTts.speak(
      'insightED Mitra. Tap the large Speak button to ask a question. '
      'I will search the web and read the answer aloud. Use the Stop button to interrupt.',
    );
  }

  void _stopAndReset() {
    _flutterTts.stop();
    _speech.stop();
    setState(() {
      _isListening = false;
      _isSearching = false;
      _assistantResponse = '';
      _userText = '';
      _source = '';
    });
    _flutterTts.speak('Ready for a new question.');
  }

  void _startListening() async {
    if (!_speechEnabled) {
      _initSpeech();
      return;
    }
    _flutterTts.stop();
    setState(() {
      _isListening = true;
      _isSearching = false;
      _userText = '';
      _assistantResponse = '';
      _source = '';
    });
    await _speech.listen(
      onResult: (result) {
        setState(() => _userText = result.recognizedWords);
        if (result.finalResult) {
          _stopListening();
          _processQuery(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      localeId: 'en_US',
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _processQuery(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    setState(() => _isSearching = true);
    final lowerQ = q.toLowerCase();

    for (final entry in _greetings.entries) {
      if (lowerQ.contains(entry.key) && entry.key.length > 2) {
        setState(() { _assistantResponse = entry.value; _isSearching = false; });
        _speakResponse();
        return;
      }
    }

    String? answer = await _searchDuckDuckGo(q);
    if (answer != null && answer.isNotEmpty) {
      setState(() { _assistantResponse = answer!; _isSearching = false; });
      _speakResponse();
      return;
    }

    answer = await _searchWikipedia(q);
    if (answer != null && answer.isNotEmpty) {
      setState(() { _assistantResponse = answer!; _source = 'Source: Wikipedia'; _isSearching = false; });
      _speakResponse();
      return;
    }

    setState(() {
      _assistantResponse = 'I could not find an answer for "$q". Please try rephrasing.';
      _isSearching = false;
    });
    _speakResponse();
  }

  Future<String?> _searchDuckDuckGo(String query) async {
    try {
      final url = Uri.parse(
        'https://api.duckduckgo.com/?q=${Uri.encodeComponent(query)}&format=json&no_html=1&skip_disambig=1',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body);

      if (data['Answer'] != null && data['Answer'].toString().isNotEmpty) {
        _source = 'Source: DuckDuckGo';
        return data['Answer'].toString();
      }
      if (data['AbstractText'] != null && data['AbstractText'].toString().isNotEmpty) {
        _source = 'Source: ${data['AbstractURL'] ?? 'DuckDuckGo'}';
        return _cleanText(data['AbstractText'].toString());
      }
      if (data['RelatedTopics'] != null && (data['RelatedTopics'] as List).isNotEmpty) {
        final topics = data['RelatedTopics'] as List;
        final results = <String>[];
        for (var topic in topics) {
          if (topic is Map && topic['Text'] != null) results.add(topic['Text'].toString());
          if (results.length >= 3) break;
        }
        if (results.isNotEmpty) { _source = 'Source: DuckDuckGo'; return results.join('. '); }
      }
      return null;
    } catch (_) { return null; }
  }

  Future<String?> _searchWikipedia(String query) async {
    try {
      final words = query.split(' ').where((w) => w.length > 2).take(5).join('_');
      if (words.isEmpty) return null;
      final url = Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(words)}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body);
      final extract = data['extract']?.toString();
      if (extract != null && extract.isNotEmpty) {
        return _cleanText(extract.length > 500 ? '${extract.substring(0, 500)}...' : extract);
      }
      return null;
    } catch (_) { return null; }
  }

  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _speakResponse() async {
    if (_assistantResponse.isEmpty) return;
    await _flutterTts.speak(_assistantResponse);
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceWelcome());

    return Scaffold(
      appBar: AppBar(
        title: const Text('insightED Mitra'),
        actions: [
          if (_assistantResponse.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.red, size: 30),
              tooltip: 'Stop and reset',
              onPressed: _stopAndReset,
            ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Repeat instructions',
            onPressed: () { _hasWelcomed = false; _announceWelcome(); },
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
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFE8ECFF),
                child: const Text('Ask any question — I search the web and speak the answer',
                    style: TextStyle(fontSize: 14, color: Color(0xFF2A3F8F)), textAlign: TextAlign.center),
              ),
              if (_userText.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6CF7), borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Your question: $_userText',
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)),
                ),
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(children: [
                    SizedBox(width: 30, height: 30,
                        child: CircularProgressIndicator(color: Color(0xFF4A6CF7), strokeWidth: 3)),
                    SizedBox(height: 10),
                    Text('Searching the web...', style: TextStyle(fontSize: 15, color: Colors.grey)),
                  ]),
                ),
              if (_assistantResponse.isNotEmpty && !_isSearching)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009688), borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        const Text('ANSWER:', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(_assistantResponse,
                            style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w500, height: 1.6)),
                        if (_source.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(_source, style: const TextStyle(fontSize: 11, color: Colors.white54, fontStyle: FontStyle.italic)),
                          ),
                      ]),
                    ),
                  ),
                ),
              if (_assistantResponse.isEmpty && !_isSearching) const Spacer(),
              Text(
                _isListening ? 'Listening... Speak your question'
                    : _isSearching ? 'Searching the web...'
                    : 'Tap the large button below to ask',
                style: TextStyle(fontSize: 15, color: _isListening ? Colors.red : Colors.grey, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Large rectangular buttons instead of circular
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TouchableZone(
                        label: _isListening ? 'Stop recording' : 'Tap to speak your question',
                        child: SizedBox(
                          height: 62,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isListening ? Colors.red : const Color(0xFF4A6CF7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 6,
                            ),
                            onPressed: _isListening ? _stopListening : (_isSearching ? null : _startListening),
                            icon: Icon(_isListening ? Icons.stop : Icons.mic, size: 26, color: Colors.white),
                            label: Text(
                              _isListening ? 'STOP' : 'SPEAK',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_assistantResponse.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TouchableZone(
                          label: 'Stop and reset. Ask a new question',
                          child: SizedBox(
                            height: 62,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 6,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _stopAndReset();
                              },
                              icon: const Icon(Icons.refresh, size: 22, color: Colors.white),
                              label: const Text('NEW', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _chip('What is AI', 'What is artificial intelligence'),
                    _chip('Solar system', 'What is the solar system'),
                    _chip('Photosynthesis', 'What is photosynthesis'),
                    _chip('Climate change', 'What is climate change'),
                    _chip('Albert Einstein', 'Who was Albert Einstein'),
                    _chip('World War 2', 'What was World War 2'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String query) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TouchableZone(
        label: 'Ask: $label',
        child: ActionChip(
          label: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF4A6CF7), fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFE8ECFF),
          side: const BorderSide(color: Color(0xFF4A6CF7)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          onPressed: () {
            HapticFeedback.lightImpact();
            _flutterTts.speak('Searching: $label');
            _processQuery(query);
          },
        ),
      ),
    );
  }
}
