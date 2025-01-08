import 'package:flutter/material.dart';
import 'theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: defaultGrad,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Center(
              child: Image.asset(
                'assets/logo_coin.png',
                height: 198.07,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Login',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20),
            // Email Input
            const TextField(
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 10, right: 30),
                  child: Opacity(
                    opacity: 0.75,
                    child: ImageIcon(AssetImage('assets/mail_icon.png'),
                        color: Colors.white),
                  ),
                ),
                labelText: 'Email Address',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                filled: false,
              ),
            ),
            const SizedBox(height: 10),
            // Password Input
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 10, right: 30),
                  child: ImageIcon(
                    AssetImage('assets/Lock.png'),
                    color: Colors.white,
                  ),
                ),
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.white),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                filled: false,
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    // Toggle password visibility
                  },
                ),
              ),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Forgot?',
                style: TextStyle(
                  color: Color(0xFFFFCC00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Login Button
            ElevatedButton(
              onPressed: () {
                // Handle login logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC00),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // OR Divider
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: Divider(color: Colors.white)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'OR',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 20),
            // Google Login Button
            ElevatedButton(
                onPressed: () {
                  // Handle Google login logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F5),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/google_icon.png',
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Login with Google',
                      style: TextStyle(color: Color(0xFF5F6368)),
                    ),
                  ],
                )),
            const SizedBox(height: 20),
            // Register Redirect
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () {
                      // Handle navigation to Register screen
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFCC00),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
