import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../widgets/touch_reader.dart';

class MemoryMatch extends StatefulWidget {
  const MemoryMatch({super.key});

  @override
  State<MemoryMatch> createState() => _MemoryMatchState();
}

class _MemoryMatchState extends State<MemoryMatch> {
  final FlutterTts _flutterTts = FlutterTts();
  final Random _rng = Random();
  bool _hasSpoken = false;
  bool _ttsReady = false;

  // Game state
  bool _gameStarted = false;
  bool _gameOver = false;
  int _score = 0;
  int _round = 1;
  int _sequenceLength = 2;

  List<String> _sequence = [];
  List<String> _userSequence = [];
  List<String> _options = [];
  bool _isShowingSequence = false;
  bool _isListening = false;

  // Word pool for random selection
  final List<String> _wordPool = [
    'Apple', 'Banana', 'Candle', 'Diamond', 'Eagle', 'Forest', 'Garden', 'Hammer',
    'Island', 'Jungle', 'Kitten', 'Ladder', 'Mountain', 'Napkin', 'Orange', 'Pencil',
    'Rabbit', 'Silver', 'Tiger', 'Umbrella', 'Violin', 'Window', 'Yellow', 'Zebra',
    'Bridge', 'Castle', 'Dragon', 'Feather', 'Guitar', 'Helmet', 'Icicle', 'Jasper',
    'Lantern', 'Mirror', 'Necklace', 'Oyster', 'Puzzle', 'Quartz', 'Rocket', 'Sunset',
    'Thunder', 'Velvet', 'Walnut', 'Anchor', 'Bubble', 'Comet', 'Dolphin', 'Emerald',
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.42);
    _flutterTts.setCompletionHandler(() {
      if (_isShowingSequence) _onSequenceShown();
    });
  }

  void _announcePage() {
    if (_hasSpoken || !_ttsReady) return;
    _hasSpoken = true;
    if (!_gameStarted) {
      _flutterTts.speak(
        'Memory Match. Listen to a sequence of words, then select them in the same order. '
        'Each round gets harder. Tap Start Game to begin.',
      );
    }
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _gameOver = false;
      _score = 0;
      _round = 1;
      _sequenceLength = 2;
      _userSequence = [];
    });
    _flutterTts.stop();
    _generateRound();
  }

  void _generateRound() {
    _sequence = [];
    _userSequence = [];
    final pool = List<String>.from(_wordPool);
    pool.shuffle(_rng);

    // Pick unique words for sequence
    for (int i = 0; i < _sequenceLength; i++) {
      _sequence.add(pool[i]);
    }

    // Generate options (sequence words + random distractors)
    _options = List<String>.from(_sequence);
    while (_options.length < 6 && _options.length < pool.length) {
      final extra = pool[_options.length + 5];
      if (!_options.contains(extra)) _options.add(extra);
    }
    _options.shuffle(_rng);

    setState(() { _isShowingSequence = true; });
    _speakSequence();
  }

  void _speakSequence() {
    _flutterTts.speak(
      'Round $_round. Listen carefully. ${_sequence.map((w) => '$w. ').join()}'
      'Now select the words in the same order.',
    );
  }

  void _onSequenceShown() {
    setState(() { _isShowingSequence = false; _isListening = true; });
  }

  void _selectWord(String word) {
    if (_gameOver || _isShowingSequence) return;
    HapticFeedback.lightImpact();
    _flutterTts.speak(word);

    setState(() {
      _userSequence.add(word);
    });

    final currentIndex = _userSequence.length - 1;

    // Check if this matches the sequence
    if (word != _sequence[currentIndex]) {
      HapticFeedback.vibrate();
      _flutterTts.speak('Wrong! The correct word was ${_sequence[currentIndex]}. Game Over.');
      setState(() {
        _gameOver = true;
        _isListening = false;
      });
      return;
    }

    // Correct so far
    _flutterTts.speak('Correct.');

    // Check if sequence complete
    if (_userSequence.length == _sequence.length) {
      _score += _sequenceLength;
      HapticFeedback.heavyImpact();
      _flutterTts.speak('Excellent! Round $_round complete. Score: $_score.');

      setState(() {
        _round++;
        _sequenceLength++;
        _userSequence = [];
        _isListening = false;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_gameOver) _generateRound();
      });
    }
  }

  String _getSelectedClass(String word) {
    if (_userSequence.contains(word)) {
      final pos = _userSequence.indexOf(word);
      if (pos < _sequence.length && _sequence[pos] == word) return 'correct';
      return 'wrong';
    }
    return '';
  }

  void _restartGame() {
    _flutterTts.stop();
    setState(() { _gameStarted = false; _gameOver = false; _isListening = false; _isShowingSequence = false; });
    _hasSpoken = false;
    _announcePage();
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
        title: const Text('Memory Match'),
        actions: [
          if (_gameStarted) ...[
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('Score: $_score', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.volume_up), tooltip: 'Repeat',
            onPressed: () { _hasSpoken = false; _announcePage(); },
          ),
        ],
      ),
      body: TouchReader(
        tts: _flutterTts,
        child: Container(
          color: const Color(0xFFF5F7FA),
          child: Column(children: [
            // Status bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _gameOver ? const Color(0xFFFFEBEE) : _isShowingSequence ? const Color(0xFFFFF3E0) : const Color(0xFFE8ECFF),
              child: Column(children: [
                Text(
                  _gameOver ? 'GAME OVER' : _isShowingSequence ? 'LISTEN CAREFULLY' : _isListening ? 'YOUR TURN — SELECT WORDS' : 'MEMORY MATCH',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: _gameOver ? const Color(0xFFE53935) : const Color(0xFF4A6CF7),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_gameStarted && !_gameOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Round $_round — ${_sequenceLength} words — Score: $_score',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF2A3F8F))),
                  ),
              ]),
            ),
            // Progress
            if (_gameStarted && _isListening)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  for (int i = 0; i < _sequenceLength; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _userSequence.length ? Colors.green : Colors.grey.shade300,
                        ),
                        child: Center(
                          child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: i < _userSequence.length ? Colors.white : Colors.grey)),
                        ),
                      ),
                    ),
                ]),
              ),
            // Word options
            Expanded(
              child: _gameStarted && _isListening
                  ? GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(16),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.0,
                      children: _options.map((word) {
                        final selClass = _getSelectedClass(word);
                        final alreadySelected = _userSequence.contains(word);
                        Color bgColor;
                        if (selClass == 'correct') {
                          bgColor = Colors.green;
                        } else if (selClass == 'wrong') {
                          bgColor = Colors.red;
                        } else if (alreadySelected) {
                          bgColor = Colors.grey.shade500;
                        } else {
                          bgColor = const Color(0xFF4A6CF7);
                        }

                        return TouchableZone(
                          label: word,
                          child: Material(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(14),
                            elevation: 3,
                            child: InkWell(
                              onTap: alreadySelected ? null : () {
                                HapticFeedback.lightImpact();
                                _selectWord(word);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Center(
                                child: Text(word, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.psychology, size: 80, color: Color(0xFF4A6CF7)),
                          const SizedBox(height: 20),
                          Text(
                            _gameOver ? 'Game Over! Score: $_score\nYou reached round $_round' : 'Listen to a sequence of words.\nThen select them in the same order.\n\nEach round adds one more word.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 17, height: 1.5, color: _gameOver ? const Color(0xFFE53935) : Colors.grey),
                          ),
                          const SizedBox(height: 30),
                          TouchableZone(
                            label: _gameOver ? 'Play again' : 'Start game',
                            child: SizedBox(
                              width: 220, height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A6CF7),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: _gameOver ? _restartGame : _startGame,
                                child: Text(
                                  _gameOver ? 'PLAY AGAIN' : 'START GAME',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
            ),
            // Restart button when game over
            if (_gameOver)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: TouchableZone(
                  label: 'Play again',
                  child: SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6CF7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _restartGame,
                      child: const Text('PLAY AGAIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
