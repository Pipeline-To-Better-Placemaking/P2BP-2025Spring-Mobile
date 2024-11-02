import 'package:flutter/material.dart';
import 'widgets.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: Center(
        child: GradientContainer(
          colors: const [ // light mode colors
            Color(0xFF0A2A88),
            Color(0xFF62B6FF),
          ],
          child: Padding(
            padding: const EdgeInsets.all(45),
            child: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(
                    hintStyle: TextStyle(
                        color: Color(0xD8B1B1B1)
                    ),
                    prefixIcon: Icon(
                      Icons.lock_open,
                      color: Color(0xD8B1B1B1),
                    ),
                    hintText: 'Password',
                  ),
                ),
                const TextField(
                  decoration: InputDecoration(
                    hintStyle: TextStyle(
                        color: Color(0xD8B1B1B1)
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Color(0xD8B1B1B1),
                    ),
                    hintText: 'Confirm Password',
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Color(0xFFFFCC00)),
                    foregroundColor: WidgetStatePropertyAll(Color(0xFF333333)),
                  ),
                  child: const Text('Update Password'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}