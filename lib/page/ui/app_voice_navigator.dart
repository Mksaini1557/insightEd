import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../widgets/touch_reader.dart';

enum NavState { idle, waitingForWake, acceptingCommand }

class AppVoiceNavigator extends StatefulWidget {
  const AppVoiceNavigator({super.key});

  @override
  State<AppVoiceNavigator> createState() => _AppVoiceNavigatorState();
}

class _AppVoiceNavigatorState extends State<AppVoiceNavigator> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _speechEnabled = false;
  NavState _state = NavState.idle;
  String _recognizedText = '';
  String _statusText = '';
  bool _hasWelcomed = false;

  final Map<String, String> _appRoutes = {
    'home': 'home',
    'home page': 'home',
    'pronunciation guide': 'Vguide1',
    'pronunciation': 'Vguide1',
    'guide': 'Vguide1',
    'talk with insight': 'talkInsightEd1',
    'talk': 'talkInsightEd1',
    'voice assistant': 'VoiceAssistant',
    'mitra': 'VoiceAssistant',
    'insightED mitra': 'VoiceAssistant',
    'insightED gyan': 'vocogyan',
    'gyan': 'vocogyan',
    'courses': 'vocogyan',
    'technical courses': 'Technical',
    'technical': 'Technical',
    'dsa': 'dsa',
    'stories': 'StoryTelling',
    'story telling': 'StoryTelling',
    'games': 'Games',
    'login': 'login',
    'log out': 'homeDecide',
    'logout': 'homeDecide',
  };

  final List<String> _wakePhrases = [
    'hello mitra',
    'hello mitro',
    'hello metro',
    'hey mitra',
    'hi mitra',
    'ok mitra',
    'hello mira',
    'hello meetra',
  ];

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
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
  }

  void _announceWelcome() {
    if (_hasWelcomed) return;
    _hasWelcomed = true;
    _flutterTts.speak(
      'App Voice Navigator. Say Hello Mitra to wake me up. Then speak the feature you want to open. '
      'For example, say: Hello Mitra... open Games.',
    );
  }

  void _startListeningForWake() async {
    if (!_speechEnabled) { _initSpeech(); return; }
    _flutterTts.stop();
    setState(() {
      _state = NavState.waitingForWake;
      _recognizedText = '';
      _statusText = 'Say "Hello Mitra" to begin...';
    });
    await _speech.listen(
      onResult: (result) {
        setState(() => _recognizedText = result.recognizedWords);
        if (result.finalResult) {
          _speech.stop();
          _checkForWakeWord(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  void _checkForWakeWord(String text) {
    final lower = text.toLowerCase().trim();
    bool isWake = false;
    for (final phrase in _wakePhrases) {
      if (lower.contains(phrase)) {
        isWake = true;
        break;
      }
    }

    if (isWake) {
      // Wake word detected - acknowledge and switch to command mode
      setState(() {
        _state = NavState.acceptingCommand;
        _recognizedText = '';
        _statusText = 'Hello! What would you like to open?';
      });
      _flutterTts.speak('Hello! What would you like to open? Speak the name of any feature.');
      // Auto-start listening for command after acknowledgment
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _state == NavState.acceptingCommand) {
          _startListeningForCommand();
        }
      });
    } else {
      // Not a wake word
      setState(() {
        _state = NavState.idle;
        _statusText = 'Please say "Hello Mitra" first to wake me.';
      });
      _flutterTts.speak('Please say Hello Mitra first to wake me up. Then tell me what to open.');
    }
  }

  void _startListeningForCommand() async {
    if (!_speechEnabled) return;
    setState(() {
      _recognizedText = '';
      _statusText = 'Speak the feature to open...';
    });
    await _speech.listen(
      onResult: (result) {
        setState(() => _recognizedText = result.recognizedWords);
        if (result.finalResult) {
          _speech.stop();
          _processCommand(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  void _processCommand(String command) {
    final lower = command.toLowerCase().trim();
    if (lower.isEmpty) {
      setState(() { _state = NavState.idle; _statusText = 'No command heard.'; });
      _flutterTts.speak('I did not hear a command. Say Hello Mitra to try again.');
      return;
    }

    // Check if user said another wake word by itself
    bool isWakeOnly = false;
    for (final phrase in _wakePhrases) {
      if (lower == phrase || lower == phrase.replaceAll(' ', '')) {
        isWakeOnly = true;
        break;
      }
    }
    if (isWakeOnly) {
      setState(() { _state = NavState.acceptingCommand; _statusText = 'Yes? What to open?'; });
      _flutterTts.speak('Yes, I am listening. What would you like to open?');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _state == NavState.acceptingCommand) _startListeningForCommand();
      });
      return;
    }

    // Remove wake words from command to extract the actual command
    String cleanCommand = lower;
    for (final phrase in _wakePhrases) {
      cleanCommand = cleanCommand.replaceAll(phrase, '').trim();
    }
    // Remove filler words
    cleanCommand = cleanCommand.replaceAll('open ', '').replaceAll('go to ', '').replaceAll('the ', '').trim();

    if (cleanCommand.isEmpty) {
      setState(() { _state = NavState.acceptingCommand; _statusText = 'Which feature?'; });
      _flutterTts.speak('Which feature would you like to open?');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _state == NavState.acceptingCommand) _startListeningForCommand();
      });
      return;
    }

    // Match command to route
    String? bestRoute;
    int bestLen = 0;
    for (final entry in _appRoutes.entries) {
      if (cleanCommand.contains(entry.key) && entry.key.length > bestLen) {
        bestRoute = entry.value;
        bestLen = entry.key.length;
      }
    }

    if (bestRoute != null) {
      setState(() { _state = NavState.idle; _statusText = 'Opening...'; });
      _flutterTts.speak('Opening ${_appRoutes.entries.firstWhere((e) => e.value == bestRoute).key}');
      Navigator.pushNamed(context, bestRoute);
    } else {
      setState(() { _state = NavState.idle; _statusText = 'Not recognized.'; });
      _flutterTts.speak(
        'I did not recognize that feature. You can say: Games, Stories, Courses, Pronunciation Guide, Voice Assistant, or Home. Say Hello Mitra to try again.',
      );
    }
  }

  void _cancelAndReset() {
    _speech.stop();
    _flutterTts.stop();
    setState(() { _state = NavState.idle; _recognizedText = ''; _statusText = ''; });
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
        title: const Text('App Navigator'),
        actions: [
          if (_state != NavState.idle)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Cancel',
              onPressed: _cancelAndReset,
            ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Repeat',
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
              // Status indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                color: _state == NavState.acceptingCommand
                    ? const Color(0xFF4CAF50)
                    : _state == NavState.waitingForWake
                        ? const Color(0xFFFFC107)
                        : const Color(0xFFE8ECFF),
                child: Column(
                  children: [
                    Text(
                      _state == NavState.acceptingCommand
                          ? 'LISTENING FOR COMMAND'
                          : _state == NavState.waitingForWake
                              ? 'WAITING FOR "HELLO MITRA"'
                              : 'SAY "HELLO MITRA" TO BEGIN',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _state == NavState.idle ? const Color(0xFF2A3F8F) : Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_statusText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_statusText, style: TextStyle(
                          fontSize: 13,
                          color: _state == NavState.idle ? Colors.grey : Colors.white70,
                        ), textAlign: TextAlign.center),
                      ),
                  ],
                ),
              ),
              if (_recognizedText.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6CF7), borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Heard:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(_recognizedText, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500)),
                  ]),
                ),
              const Spacer(),
              // Instruction text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _state == NavState.acceptingCommand
                      ? 'Now speak the feature name'
                      : _state == NavState.waitingForWake
                          ? 'Listening for Hello Mitra...'
                          : 'Step 1: Say "Hello Mitra"\nStep 2: Say the feature to open',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // Large rectangular buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TouchableZone(
                        label: _state == NavState.idle
                            ? 'Tap to start. Say Hello Mitra'
                            : 'Tap to speak',
                        child: SizedBox(
                          height: 62,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _state == NavState.acceptingCommand
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF5722),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 6,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              if (_state == NavState.idle || _state == NavState.waitingForWake) {
                                _startListeningForWake();
                              } else if (_state == NavState.acceptingCommand) {
                                _startListeningForCommand();
                              }
                            },
                            icon: Icon(
                              _state == NavState.acceptingCommand ? Icons.mic : Icons.mic_none,
                              size: 26, color: Colors.white,
                            ),
                            label: Text(
                              _state == NavState.idle ? 'TAP TO START' : 'SPEAK NOW',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TouchableZone(
                        label: 'Reset. Say Hello Mitra again',
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
                              _cancelAndReset();
                              _flutterTts.speak('Reset. Say Hello Mitra to begin.');
                            },
                            icon: const Icon(Icons.refresh, size: 22, color: Colors.white),
                            label: const Text('RESET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  'Commands: "Games" | "Stories" | "Courses" | "Pronunciation" | "Mitra" | "Technical" | "Home"',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
