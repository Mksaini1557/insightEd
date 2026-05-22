import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, 'homeDecide');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A6CF7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb, size: 120, color: Colors.white),
            const SizedBox(height: 32),
            const Text(
              'Welcome to\ninsightED',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Empowering learning through voice',
              style: TextStyle(fontSize: 16, color: Colors.white70, letterSpacing: 1),
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
