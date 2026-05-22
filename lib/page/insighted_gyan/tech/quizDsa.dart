import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DsaQuiz extends StatefulWidget {
  const DsaQuiz({super.key});

  @override
  State<DsaQuiz> createState() => _DsaQuizState();
}

class _DsaQuizState extends State<DsaQuiz> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _ttsReady = false;

  final String _lessonText = '''
Linked List

A linked list is a linear data structure, in which the elements are not stored at contiguous memory locations.

The elements in a linked list are linked using pointers.

In simple words, a linked list consists of nodes where each node contains a data field and a reference (link) to the next node in the list.

Types of Linked Lists:

1. Singly Linked List: Each node points to the next node in the sequence. Traversal is possible only in one direction.

2. Doubly Linked List: Each node has two pointers - one to the next node and one to the previous node. Traversal is possible in both directions.

3. Circular Linked List: The last node points back to the first node, forming a circle.

Advantages:
- Dynamic size (no need to specify size initially)
- Ease of insertion and deletion
- Efficient memory utilization

Disadvantages:
- Random access is not allowed
- Extra memory space for pointers
- Not cache friendly
''';

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

  Future<void> _speakLesson() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await _flutterTts.speak(_lessonText);
      setState(() => _isSpeaking = false);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linked List'),
        actions: [
          IconButton(
            icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
            onPressed: _speakLesson,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: InkWell(
                onTap: _speakLesson,
                child: Text(
                  _lessonText,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: Color(0xFF212121),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFE8ECFF),
            child: Column(
              children: [
                const Text(
                  'Ready for a quiz on this lesson?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF2A3F8F)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                        onPressed: () => Navigator.pushNamed(context, 'StartQuiz'),
                        child: const Text('YES'),
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
                        onPressed: () => Navigator.pushNamed(context, 'home'),
                        child: const Text('NO'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
