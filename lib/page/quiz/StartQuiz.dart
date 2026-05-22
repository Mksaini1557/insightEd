import 'package:flutter/material.dart';
import 'question.dart';

class StartQuiz extends StatefulWidget {
  const StartQuiz({super.key});

  @override
  State<StartQuiz> createState() => _StartQuizState();
}

class _StartQuizState extends State<StartQuiz> {
  final List<Questions> _questions = [
    Questions(que: 'The potato became soft in boiling water.', ans: true),
    Questions(que: 'The egg became soft in boiling water.', ans: false),
    Questions(que: 'The coffee beans changed the water.', ans: true),
    Questions(que: 'The father was a doctor by profession.', ans: false),
    Questions(que: 'The story teaches us about handling adversity.', ans: true),
    Questions(que: 'There were four pots of boiling water.', ans: false),
  ];

  int _currentIndex = 0;
  int _score = 0;
  bool? _lastAnswer;

  void _answer(bool userAnswer) {
    final correct = _questions[_currentIndex].ans == userAnswer;
    setState(() {
      _lastAnswer = userAnswer;
      if (correct) _score++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correct ? 'Correct!' : 'Wrong!'),
        backgroundColor: correct ? Colors.green : Colors.red,
        duration: const Duration(milliseconds: 800),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (_currentIndex + 1 < _questions.length) {
        setState(() {
          _currentIndex++;
          _lastAnswer = null;
        });
      } else {
        _showResult();
      }
    });
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Quiz Complete!', style: TextStyle(color: Color(0xFF4A6CF7))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 60, color: Color(0xFFFFC107)),
            const SizedBox(height: 12),
            Text(
              'Your Score: $_score / ${_questions.length}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _lastAnswer = null;
              });
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushNamed(context, 'home');
            },
            child: const Text('Go Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text('Quiz (${_currentIndex + 1}/${_questions.length})')),
      body: Container(
        color: const Color(0xFFF5F7FA),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Score: $_score',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7C4DFF)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                backgroundColor: Colors.grey.shade300,
                color: const Color(0xFF4A6CF7),
                minHeight: 6,
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        q.que,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, height: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _lastAnswer == true
                            ? (_lastAnswer == true && _questions[_currentIndex].ans == true
                                ? Colors.green
                                : Colors.red)
                            : const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _lastAnswer != null ? null : () => _answer(true),
                      child: const Text('TRUE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 32),
                  SizedBox(
                    width: 120,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _lastAnswer == false
                            ? (_lastAnswer == false && _questions[_currentIndex].ans == false
                                ? Colors.green
                                : Colors.red)
                            : const Color(0xFFE53935),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _lastAnswer != null ? null : () => _answer(false),
                      child: const Text('FALSE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
