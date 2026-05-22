import 'package:flutter/material.dart';

class DSA extends StatefulWidget {
  const DSA({super.key});

  @override
  State<DSA> createState() => _DSAState();
}

class _DSAState extends State<DSA> {
  final List<Map<String, dynamic>> _episodes = [
    {'title': 'Ep. 1 - Linked List', 'route': 'DsaQuiz'},
    {'title': 'Ep. 2 - C', 'route': 'ComingSoon'},
    {'title': 'Ep. 3 - C++', 'route': 'ComingSoon'},
    {'title': 'Ep. 4 - C#', 'route': 'ComingSoon'},
    {'title': 'Ep. 5 - Java', 'route': 'ComingSoon'},
    {'title': 'Ep. 6 - Python', 'route': 'ComingSoon'},
    {'title': 'Ep. 7 - Ruby', 'route': 'ComingSoon'},
    {'title': 'Ep. 8 - Fluent', 'route': 'ComingSoon'},
    {'title': 'Ep. 9 - Go', 'route': 'ComingSoon'},
    {'title': 'Ep. 10 - Dart', 'route': 'ComingSoon'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DSA Episodes')),
      body: Container(
        color: const Color(0xFFF5F7FA),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _episodes.length,
          itemBuilder: (context, index) {
            final ep = _episodes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: index == 0 ? const Color(0xFF4A6CF7) : const Color(0xFF7C4DFF),
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, ep['route'] as String),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            ep['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
