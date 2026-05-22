import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRegister extends StatefulWidget {
  const MyRegister({super.key});

  @override
  State<MyRegister> createState() => _MyRegisterState();
}

class _MyRegisterState extends State<MyRegister> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        message = 'Password should be at least 6 characters.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lightbulb, size: 80, color: Color(0xFF4A6CF7)),
                const SizedBox(height: 16),
                const Text(
                  'Join insightED',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4A6CF7)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create an account to start your journey',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF4A6CF7)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4A6CF7), width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4A6CF7)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4A6CF7), width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4A6CF7)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4A6CF7), width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688)),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('SIGN UP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Sign In', style: TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
