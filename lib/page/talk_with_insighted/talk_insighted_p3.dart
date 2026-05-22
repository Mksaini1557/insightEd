import 'package:flutter/material.dart';

class TalkInsightEd3 extends StatefulWidget {
  const TalkInsightEd3({super.key});

  @override
  State<TalkInsightEd3> createState() => _TalkInsightEd3State();
}

class _TalkInsightEd3State extends State<TalkInsightEd3> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Talk with insightED Mitra')),
      body: Container(
        color: const Color(0xFFF5F7FA),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.smart_toy, size: 80, color: Color(0xFF009688)),
              const SizedBox(height: 24),
              const Text(
                'Choose your mode',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A6CF7)),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pushNamed(context, 'ComingSoon'),
                  child: const Text('Talk to insightED Bot',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 280,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: null,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, color: Colors.white70, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Talk to insightED Friend',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
