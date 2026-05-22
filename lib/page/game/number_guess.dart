import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../widgets/touch_reader.dart';

class NumberGuess extends StatefulWidget {
  const NumberGuess({super.key});

  @override
  State<NumberGuess> createState() => _NumberGuessState();
}

class _NumberGuessState extends State<NumberGuess> {
  final FlutterTts _flutterTts = FlutterTts();
  final Random _rng = Random();
  bool _hasSpoken = false;
  bool _ttsReady = false;
  bool _gameStarted = false;
  int _targetNumber = 0;
  int _attempts = 0;
  int _currentGuess = 50;
  String _hint = '';
  bool _gameOver = false;

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
    if (!_gameStarted) {
      _flutterTts.speak('Number Guess. I will think of a number between 1 and 100. Use the plus and minus buttons to adjust your guess, or tap the quick guess buttons. Tap Start Game to begin.');
    } else {
      _flutterTts.speak('Your guess is $_currentGuess. ${_hint.isNotEmpty ? _hint : ""} Use buttons to change your guess.');
    }
  }

  void _startGame() {
    _flutterTts.stop();
    setState(() {
      _gameStarted = true;
      _gameOver = false;
      _targetNumber = _rng.nextInt(100) + 1;
      _attempts = 0;
      _currentGuess = 50;
      _hint = '';
    });
    _flutterTts.speak('I have a number between 1 and 100. Your current guess is 50. Use plus and minus to change it, then tap Submit.');
  }

  void _changeGuess(int delta) {
    if (_gameOver) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentGuess = (_currentGuess + delta).clamp(1, 100);
    });
    _flutterTts.speak('$_currentGuess');
  }

  void _submitGuess() {
    if (_gameOver || !_gameStarted) return;
    _attempts++;

    if (_currentGuess == _targetNumber) {
      HapticFeedback.heavyImpact();
      setState(() {
        _gameOver = true;
        _hint = '';
      });
      _flutterTts.speak('Correct! The number is $_targetNumber. You found it in $_attempts attempts. Excellent! Tap Play Again to try again.');
    } else if (_currentGuess < _targetNumber) {
      HapticFeedback.lightImpact();
      setState(() { _hint = 'Too low, go higher'; });
      _flutterTts.speak('Higher than $_currentGuess. Try again.');
    } else {
      HapticFeedback.lightImpact();
      setState(() { _hint = 'Too high, go lower'; });
      _flutterTts.speak('Lower than $_currentGuess. Try again.');
    }
  }

  void _setQuickGuess(int val) {
    if (_gameOver) return;
    HapticFeedback.lightImpact();
    setState(() { _currentGuess = val; _hint = ''; });
    _flutterTts.speak('Guess set to $val. Tap Submit when ready.');
  }

  void _restart() {
    _flutterTts.stop();
    setState(() { _gameStarted = false; _gameOver = false; _hint = ''; _attempts = 0; _currentGuess = 50; });
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
        title: const Text('Number Guess'),
        actions: [
          if (_gameStarted)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('Tries: $_attempts', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          IconButton(icon: const Icon(Icons.volume_up), tooltip: 'Repeat',
            onPressed: () { _hasSpoken = false; _announcePage(); },
          ),
        ],
      ),
      body: TouchReader(
        tts: _flutterTts,
        child: Container(
          color: const Color(0xFFF5F7FA),
          child: _gameStarted ? _buildGame() : _buildStartScreen(),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.casino, size: 64, color: Color(0xFF009688)),
          const SizedBox(height: 16),
          const Text('Number Guess', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
          const SizedBox(height: 8),
          const Text('I think of a number from 1 to 100.\nGuess it. I say Higher or Lower.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5)),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 70,
            child: TouchableZone(
              label: 'Start game. Guess a number between 1 and 100',
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: _startGame,
                child: const Text('START GAME', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildGame() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(children: [
        // Number display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: _gameOver ? const Color(0xFFE8F5E9) : const Color(0xFFE8ECFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gameOver ? Colors.green : const Color(0xFF4A6CF7), width: 3),
          ),
          child: Column(children: [
            Text(_gameOver ? 'CORRECT!' : 'YOUR GUESS',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _gameOver ? Colors.green : const Color(0xFF4A6CF7))),
            const SizedBox(height: 2),
            Text('$_currentGuess', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Color(0xFF4A6CF7))),
            if (_hint.isNotEmpty && !_gameOver)
              Padding(padding: const EdgeInsets.only(top: 2),
                child: Text(_hint, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)))),
            if (_gameOver)
              Padding(padding: const EdgeInsets.only(top: 2),
                child: Text('Found in $_attempts tries!', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green))),
          ]),
        ),
        const SizedBox(height: 10),
        // Step buttons row - 75px each
        Row(children: [
          Expanded(child: _stepBtn('-10', 'Minus 10', const Color(0xFFC62828), -10)),
          const SizedBox(width: 8),
          Expanded(child: _stepBtn('-1', 'Minus 1', const Color(0xFFFF5722), -1)),
          const SizedBox(width: 8),
          Expanded(child: _stepBtn('+1', 'Plus 1', const Color(0xFF2E7D32), 1)),
          const SizedBox(width: 8),
          Expanded(child: _stepBtn('+10', 'Plus 10', const Color(0xFF1B5E20), 10)),
        ]),
        const SizedBox(height: 10),
        // Quick jump chips
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _buildChip('Jump to 25', 25),
            _buildChip('Jump to 50', 50),
            _buildChip('Jump to 75', 75),
          ]),
        ),
        const SizedBox(height: 16),
        // Submit / Restart
        _fullBtn(
          _gameOver ? 'PLAY AGAIN' : 'SUBMIT GUESS',
          _gameOver ? const Color(0xFF4A6CF7) : const Color(0xFF009688),
          _gameOver ? 'Play again' : 'Submit your guess',
          _gameOver ? _restart : _submitGuess,
        ),
      ]),
    );
  }

  Widget _stepBtn(String label, String speak, Color color, int delta) {
    return TouchableZone(
      label: speak,
      child: SizedBox(
        height: 75,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: EdgeInsets.zero,
          ),
          onPressed: _gameOver ? null : () => _changeGuess(delta),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          ]),
        ),
      ),
    );
  }

  Widget _fullBtn(String label, Color color, String speak, VoidCallback onTap) {
    return TouchableZone(
      label: speak,
      child: SizedBox(
        width: double.infinity, height: 75,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildChip(String label, int value) {
    return TouchableZone(
      label: label,
      child: GestureDetector(
        onTap: _gameOver ? null : () => _setQuickGuess(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8ECFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4A6CF7), width: 2),
          ),
          child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A6CF7))),
        ),
      ),
    );
  }
}
