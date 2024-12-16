import 'package:flutter/material.dart';
import 'results_panel.dart';
import 'edit_project_panel.dart';
import 'forgot_password_page.dart';
import 'reset_password_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          // Insert theme here
          ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(title: 'Home Page'),
      routes: {
        '/results': (context) => const ResultsPanel(),
        '/edit_project': (context) => const EditProjectPanel(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/reset_password': (context) => const ResetPasswordPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageStates();
}

class _HomePageStates extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Button 1: Edit Project
            Expanded(
              child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue[800],
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/edit_project');
                  },
                  child: const Text('Edit Project')),
            ),

            // Button 2: Results
            Expanded(
              child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.yellow[600],
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/results');
                  },
                  child: const Text('Results')),
            ),

            // Button 3: Forgot Password
            Expanded(
              child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue[800],
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot_password');
                  },
                  child: const Text('Forgot Password')),
            ),

            // Button 4: Reset Password
            Expanded(
              child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.yellow[600],
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/reset_password');
                  },
                  child: const Text('Reset Password')),
            ),
          ],
        ),
      ),
    );
  }
}
