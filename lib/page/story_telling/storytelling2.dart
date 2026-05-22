import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Storytelling2 extends StatefulWidget {
  const Storytelling2({super.key});

  @override
  State<Storytelling2> createState() => _Storytelling2State();
}

class _Storytelling2State extends State<Storytelling2> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _ttsReady = false;

  final String _story = '''
The Potato, The Egg, And The Coffee Beans

Once upon a time, a daughter complained to her father that her life was miserable and that she didn't know how she was going to make it.

Her father, a chef, took her to the kitchen. He filled three pots with water and placed each on a high fire.

Once the three pots began to boil, he placed potatoes in one pot, eggs in the second pot, and ground coffee beans in the third pot.

After 20 minutes, he turned off the burners. He took the potatoes out of the pot and placed them in a bowl. He pulled the eggs out and placed them in a bowl. He then ladled the coffee out and placed it in a cup.

Turning to her, he asked: "Daughter, what do you see?"

"Potatoes, eggs, and coffee," she hastily replied.

"Look closer," he said, "and touch the potatoes." She did and noted that they were soft.

He then asked her to take an egg and break it. After pulling off the shell, she observed the hard-boiled egg.

Finally, he asked her to sip the coffee. Its rich aroma brought a smile to her face.

"Father, what does this mean?" she asked.

He then explained that the potatoes, the eggs, and the coffee beans had each faced the same adversity — the boiling water. However, each one reacted differently.

The potato went in strong, hard, and unrelenting, but in boiling water, it became soft and weak.

The egg was fragile, with the thin outer shell protecting its liquid interior until it was put in the boiling water. Then the inside of the egg became hard.

However, the ground coffee beans were unique. After they were exposed to the boiling water, they changed the water and created something new.

"Which are you?" he asked his daughter. "When adversity knocks on your door, how do you respond? Are you a potato, an egg, or a coffee bean?"

Moral: In life, things happen around us, things happen to us, but the only thing that truly matters is how you choose to react to it and what you make out of it. Life is all about learning, adopting and converting all the struggles that we experience into something positive.
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

  Future<void> _speakStory() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await _flutterTts.speak(_story);
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
        title: const Text('Story'),
        actions: [
          IconButton(
            icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
            onPressed: _speakStory,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            color: const Color(0xFFE8ECFF),
            child: const Center(
              child: Icon(Icons.auto_stories, size: 80, color: Color(0xFF4A6CF7)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                _story,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF212121),
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
                  'Would you like to play a story quiz?',
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
