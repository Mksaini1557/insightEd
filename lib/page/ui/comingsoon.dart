import 'package:flutter/material.dart';

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Coming Soon')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Color(0xFF009688)),
            const SizedBox(height: 24),
            const Text(
              'Coming Soon',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF4A6CF7)),
            ),
            const SizedBox(height: 12),
            const Text(
              'We\'re working on something amazing!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'home'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
