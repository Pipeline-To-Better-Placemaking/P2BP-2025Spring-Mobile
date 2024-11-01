import 'package:flutter/material.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(45),
          child: Column(
            children: [
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Password',
                ),
              ),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Confirm Password',
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Update Password')
              )
            ],
          ),
        ),
      ),
    );
  }
}