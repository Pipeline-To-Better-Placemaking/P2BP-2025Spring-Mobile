import 'package:flutter/material.dart';
import 'login_screen.dart'; // Import your LoginScreen file
import 'signup_screen.dart'; // Import your SignUpScreen file
import 'home_screen.dart'; // Import your HomeScreen file

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // Define the initial route
      routes: {
        '/': (context) =>
            LoginScreen(), // Change this to the screen you want to test first
        '/signup': (context) => SignUpScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
