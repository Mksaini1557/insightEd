import 'package:flutter/material.dart';

class StartInsightEdQuiz extends StatefulWidget {
  const StartInsightEdQuiz({super.key});

  @override
  State<StartInsightEdQuiz> createState() => _StartInsightEdQuizState();
}

class _StartInsightEdQuizState extends State<StartInsightEdQuiz> {
  final List<Map<String, bool>> _questions = const [
    {'Linked List are similar to an Array': true},
    {'Each node in a linked list has a data field and a reference to the next node': true},
    {'In a Singly Linked List, traversal is possible in both directions': false},
    {'Doubly Linked List nodes have two pointers': true},
    {'Circular Linked List\'s last node points to the first node': true},
    {'Random access is efficient in linked lists': false},
  ];

  int _currentIndex = 0;
  int _score = 0;
  bool? _lastAnswer;

  void _answer(bool userAnswer) {
    final correct = _questions[_currentIndex].values.first == userAnswer;
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
      appBar: AppBar(title: Text('DSA Quiz (${_currentIndex + 1}/${_questions.length})')),
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
                        q.keys.first,
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
                            ? (_lastAnswer == true && q.values.first == true
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
                            ? (_lastAnswer == false && q.values.first == false
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
