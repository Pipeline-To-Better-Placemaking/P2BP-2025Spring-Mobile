import 'package:flutter/material.dart';
import 'strings.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgor Password?'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(45),
          child: Column(
            children: [
              const Text(Strings.forgotPasswordText),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Email Address',
                ),
              ),
              TextButton(
                onPressed: () {}, // TODO actually send a reset link
                child: const Text('Send Reset Link')
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Return to Login')
              ),
            ],
          ),
        ),
      ),
    );
  }
}