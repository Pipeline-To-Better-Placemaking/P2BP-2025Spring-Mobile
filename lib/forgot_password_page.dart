import 'package:flutter/material.dart';
import 'strings.dart';
import 'widgets.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password?'),
      ),
      body: Center(
        child: GradientContainer(
          colors: const [ // light mode colors TODO extract frequently used colors to their own class
            Color(0xFF0A2A88),
            Color(0xFF62B6FF),
          ],
          child: Padding(
            padding: const EdgeInsets.all(45),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Color(0xFFFFFFFF)
              ),
              child: Column(
                children: [
                  const Text(Strings.forgotPasswordText),
                  const TextField(
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                        color: Color(0xD8B1B1B1)
                      ),
                      prefixIcon: Icon(
                        Icons.mail_outline,
                        color: Color(0xD8B1B1B1),
                      ),
                      hintText: 'Email Address',
                    ),
                  ),
                  TextButton(
                    onPressed: () {}, // TODO actually send a reset link
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Color(0xFFFFCC00)),
                      foregroundColor: WidgetStatePropertyAll(Color(0xFF333333)),
                    ),
                    child: const Text('Send Reset Link'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context), // pops current screen off nav stack
                    style: ButtonStyle(
                      foregroundColor: WidgetStatePropertyAll(Color(0xFFFFD700)),
                    ),
                    child: const Text('Return to Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

