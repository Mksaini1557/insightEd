import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import '../../widgets/touch_reader.dart';

class TopicQuiz extends StatefulWidget {
  const TopicQuiz({super.key});

  @override
  State<TopicQuiz> createState() => _TopicQuizState();
}

class _TopicQuizState extends State<TopicQuiz> {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _topicController = TextEditingController();
  bool _hasSpoken = false;
  bool _ttsReady = false;
  bool _isLoading = false;
  bool _quizStarted = false;
  bool _speechEnabled = false;
  bool _isVoiceListening = false;
  String _statusText = '';
  String _voiceText = '';

  List<_QuizQuestion> _questions = [];
  int _currentQ = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
    if (mounted) setState(() => _ttsReady = true);
  }

  void _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {},
      onError: (error) {},
    );
    setState(() {});
  }

  void _announcePage() {
    if (_hasSpoken || !_ttsReady) return;
    _hasSpoken = true;
    if (!_quizStarted) {
      _flutterTts.speak(
        'Topic Quiz. Type a topic in the text field at the top, or use the voice button at the bottom right to speak a topic. '
        'Then tap Generate Quiz. I will fetch 10 questions from the web.',
      );
    } else {
      final q = _questions[_currentQ];
      _flutterTts.speak('Question ${_currentQ + 1} of 10: ${q.question}. Options: ${q.options.join(", ")}');
    }
  }

  // --- VOICE TOPIC INPUT ---

  void _startVoiceTopic() async {
    if (!_speechEnabled) { _initSpeech(); return; }
    _flutterTts.stop();
    setState(() { _isVoiceListening = true; _voiceText = ''; });
    await _speech.listen(
      onResult: (result) {
        setState(() => _voiceText = result.recognizedWords);
        if (result.finalResult) {
          _speech.stop();
          setState(() {
            _isVoiceListening = false;
            _topicController.text = result.recognizedWords;
          });
          _flutterTts.speak('Topic set to: ${result.recognizedWords}');
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  void _stopVoiceTopic() async {
    await _speech.stop();
    setState(() => _isVoiceListening = false);
    if (_voiceText.isNotEmpty) {
      _topicController.text = _voiceText;
    }
  }

  // --- WEB SCRAPING FOR QUIZ QUESTIONS ---

  Future<void> _generateQuiz() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      setState(() => _statusText = 'Please enter a topic');
      _flutterTts.speak('Please enter a topic first');
      return;
    }
    setState(() { _isLoading = true; _statusText = 'Searching web for "$topic"...'; });
    _flutterTts.speak('Searching the web for 10 questions about $topic');

    try {
      final questions = await _fetchAndGenerateQuestions(topic);
      if (questions.isNotEmpty && mounted) {
        setState(() {
          _questions = questions;
          _quizStarted = true;
          _isLoading = false;
          _currentQ = 0;
          _score = 0;
          _selectedIndex = null;
          _answered = false;
          _statusText = '';
        });
        _hasSpoken = false;
        _announcePage();
      } else {
        setState(() { _isLoading = false; _statusText = 'No questions found. Try another topic.'; });
        _flutterTts.speak('Could not find enough information. Please try a different topic.');
      }
    } catch (e) {
      setState(() { _isLoading = false; _statusText = 'Error: $e'; });
      _flutterTts.speak('An error occurred. Please try again.');
    }
  }

  Future<List<_QuizQuestion>> _fetchAndGenerateQuestions(String topic) async {
    final facts = await _fetchFacts(topic);
    if (facts.isEmpty) return [];
    return _generateMcqs(facts, topic);
  }

  Future<List<String>> _fetchFacts(String topic) async {
    final facts = <String>[];

    try {
      final words = topic.split(' ').where((w) => w.length > 2).take(5).join('_');
      final url = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(words)}');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final extract = data['extract']?.toString() ?? '';
        if (extract.isNotEmpty) facts.addAll(_splitIntoSentences(extract));
      }
    } catch (_) {}

    try {
      final url = Uri.parse('https://api.duckduckgo.com/?q=${Uri.encodeComponent(topic)}&format=json&no_html=1&skip_disambig=1');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['AbstractText'] != null && data['AbstractText'].toString().isNotEmpty) {
          facts.addAll(_splitIntoSentences(data['AbstractText'].toString()));
        }
        if (data['RelatedTopics'] != null) {
          for (var t in (data['RelatedTopics'] as List).take(15)) {
            if (t is Map && t['Text'] != null) {
              final text = t['Text'].toString().split(' - ').first.trim();
              if (text.length > 20) facts.add(text);
            }
          }
        }
      }
    } catch (_) {}

    return facts.toSet().toList();
  }

  List<String> _splitIntoSentences(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.split(' ').length >= 6 && s.split(' ').length <= 40)
        .toList();
  }

  List<_QuizQuestion> _generateMcqs(List<String> facts, String topic) {
    final questions = <_QuizQuestion>[];
    final rng = Random();
    facts.shuffle(rng);

    final allKeywords = <String>{};
    for (final fact in facts) {
      allKeywords.addAll(_extractKeywords(fact, topic));
    }
    final distractorPool = allKeywords.where((k) => k.length > 3).toList();

    for (final fact in facts.take(10)) {
      final keywords = _extractKeywords(fact, topic);
      if (keywords.isEmpty) continue;

      final answer = keywords[rng.nextInt(keywords.length)];
      final question = fact.replaceFirst(answer, '_____');

      final distractors = <String>{};
      final pool = [...distractorPool.where((d) => d != answer)];
      pool.shuffle(rng);
      for (final d in pool) {
        if (distractors.length >= 3) break;
        if (d != answer) distractors.add(d);
      }
      final fallbackDistractors = [
        topic, 'the system', 'a process', 'an element',
        'the structure', 'a function', 'the method', 'an object',
      ];
      for (final fb in fallbackDistractors) {
        if (distractors.length >= 3) break;
        if (fb != answer) distractors.add(fb);
      }

      final options = [answer, ...distractors];
      options.shuffle(rng);
      final correctIndex = options.indexOf(answer);

      questions.add(_QuizQuestion(
        question: _cleanQuestion(question),
        options: options,
        correctIndex: correctIndex,
      ));
    }

    return questions;
  }

  List<String> _extractKeywords(String sentence, String topic) {
    final words = sentence
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .split(' ')
        .where((w) => w.length > 3 && !_isStopWord(w) && w.toLowerCase() != topic.toLowerCase())
        .toSet()
        .toList();
    return words.length > 6 ? words.sublist(0, 6) : words;
  }

  bool _isStopWord(String word) {
    const stopWords = {
      'that', 'this', 'with', 'from', 'they', 'have', 'been', 'were', 'their',
      'which', 'about', 'also', 'into', 'more', 'some', 'than', 'when', 'them',
      'other', 'first', 'after', 'most', 'over', 'only', 'very', 'between',
    };
    return stopWords.contains(word.toLowerCase());
  }

  String _cleanQuestion(String q) {
    return q.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // --- ANSWER HANDLING ---

  void _selectOption(int index) {
    if (_answered) return;
    setState(() { _selectedIndex = index; _answered = true; });

    final q = _questions[_currentQ];
    final correct = index == q.correctIndex;
    if (correct) {
      _score++;
      HapticFeedback.heavyImpact();
      _flutterTts.speak('Excellent! That is the right answer.');
      setState(() => _statusText = 'Correct!');
    } else {
      HapticFeedback.vibrate();
      _flutterTts.speak('Wrong. The correct answer is: ${q.options[q.correctIndex]}.');
      setState(() => _statusText = 'Wrong. Correct: ${q.options[q.correctIndex]}');
    }

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (_currentQ + 1 < _questions.length) {
        setState(() {
          _currentQ++;
          _selectedIndex = null;
          _answered = false;
          _statusText = '';
        });
        _hasSpoken = false;
        _announcePage();
      } else {
        _showResult();
      }
    });
  }

  void _showResult() {
    final total = _questions.length;
    final percentage = ((_score / total) * 100).round();
    _flutterTts.speak('Quiz complete! Your score: $_score out of $total. That is $percentage percent.');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Quiz Complete!', style: TextStyle(color: Color(0xFF4A6CF7), fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(percentage >= 70 ? Icons.emoji_events : Icons.school, size: 60,
              color: percentage >= 70 ? const Color(0xFFFFC107) : const Color(0xFF4A6CF7)),
          const SizedBox(height: 12),
          Text('Score: $_score / $total', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$percentage%', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _quizStarted = false;
                _questions = [];
                _topicController.clear();
                _statusText = '';
              });
            },
            child: const Text('New Topic'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    _topicController.dispose();
    super.dispose();
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _announcePage());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Quiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Repeat',
            onPressed: () { _hasSpoken = false; _announcePage(); },
          ),
        ],
      ),
      body: TouchReader(
        tts: _flutterTts,
        child: Container(
          color: const Color(0xFFF5F7FA),
          child: _quizStarted ? _buildQuizBody() : _buildTopicInput(),
        ),
      ),
    );
  }

  Widget _buildTopicInput() {
    return Column(
      children: [
        // Upper 75% - topic display and generate button
        Expanded(
          flex: 3,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.quiz, size: 60, color: Color(0xFF4A6CF7)),
                const SizedBox(height: 12),
                const Text('Topic Quiz',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF4A6CF7))),
                const SizedBox(height: 6),
                const Text('Enter a topic — I generate 10 MCQs from the web',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 20),
                TextField(
                  controller: _topicController,
                  decoration: InputDecoration(
                    labelText: 'Your topic',
                    hintText: 'e.g., Solar System, Python, AI...',
                    prefixIcon: const Icon(Icons.topic, color: Color(0xFF4A6CF7)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4A6CF7), width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                  ),
                  onSubmitted: (_) => _generateQuiz(),
                ),
                const SizedBox(height: 14),
                TouchableZone(
                  label: 'Generate quiz',
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6CF7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isLoading ? null : _generateQuiz,
                      icon: _isLoading
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.auto_awesome, color: Colors.white),
                      label: Text(_isLoading ? 'Generating...' : 'GENERATE QUIZ',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
                if (_statusText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_statusText, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
              ]),
            ),
          ),
        ),
        // Bottom 25% - Two large rectangular input options
        Container(
          height: MediaQuery.of(context).size.height * 0.25,
          decoration: const BoxDecoration(
            color: Color(0xFFE8ECFF),
            border: Border(top: BorderSide(color: Color(0xFF4A6CF7), width: 2)),
          ),
          child: Row(
            children: [
              // Left: Type Topic
              Expanded(
                child: TouchableZone(
                  label: 'Type a topic in the text field above',
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _flutterTts.speak('Type your topic in the text field above');
                      FocusScope.of(context).requestFocus(FocusNode());
                      // Focus the text field
                      Future.delayed(const Duration(milliseconds: 100), () {
                        FocusScope.of(context).nextFocus();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF4A6CF7), width: 2),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.keyboard, size: 40, color: Color(0xFF4A6CF7)),
                          SizedBox(height: 8),
                          Text('TYPE TOPIC',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF4A6CF7))),
                          SizedBox(height: 2),
                          Text('Use keyboard above',
                              style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Right: Speak Topic
              Expanded(
                child: TouchableZone(
                  label: _isVoiceListening ? 'Stop voice input' : 'Speak your topic',
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (_isVoiceListening) {
                        _stopVoiceTopic();
                      } else {
                        _flutterTts.speak('Speak your topic now');
                        _startVoiceTopic();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isVoiceListening ? Colors.red.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isVoiceListening ? Colors.red : const Color(0xFF4A6CF7),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isVoiceListening ? Icons.mic : Icons.mic_none,
                            size: 40,
                            color: _isVoiceListening ? Colors.red : const Color(0xFF4A6CF7),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isVoiceListening ? 'LISTENING...' : 'SPEAK TOPIC',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _isVoiceListening ? Colors.red : const Color(0xFF4A6CF7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isVoiceListening
                                ? (_voiceText.isNotEmpty ? _voiceText : 'Speak now...')
                                : 'Voice input',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizBody() {
    final q = _questions[_currentQ];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(children: [
          Text('Q ${_currentQ + 1}/10',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4A6CF7))),
          const Spacer(),
          Text('Score: $_score',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: LinearProgressIndicator(
          value: (_currentQ + 1) / _questions.length,
          backgroundColor: Colors.grey.shade300,
          color: const Color(0xFF4A6CF7),
          minHeight: 4,
        ),
      ),
      if (_statusText.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_statusText, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.bold,
            color: _statusText.startsWith('Correct') ? Colors.green : Colors.red,
          )),
        ),
      Expanded(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(q.question,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, height: 1.5, color: Color(0xFF212121))),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: List.generate(4, (i) {
            final option = q.options[i];
            final isSelected = _selectedIndex == i;
            final isCorrect = i == q.correctIndex;
            Color bgColor;
            if (!_answered) {
              bgColor = const Color(0xFF4A6CF7);
            } else if (isSelected && isCorrect) {
              bgColor = Colors.green;
            } else if (isSelected && !isCorrect) {
              bgColor = Colors.red;
            } else if (isCorrect && _answered) {
              bgColor = Colors.green;
            } else {
              bgColor = Colors.grey.shade400;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TouchableZone(
                label: 'Option ${i + 1}: $option',
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bgColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _flutterTts.speak(option);
                      Future.delayed(const Duration(milliseconds: 500), () => _selectOption(i));
                    },
                    child: Text(
                      option,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ]);
  }
}

class _QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}
