import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'forgot_password_page.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: defaultGrad,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SafeArea(
            child: ListView(
              children: <Widget>[
                const SizedBox(height: 20),
                // Logo
                Center(
                  child: Image.asset(
                    'assets/logo_coin.png',
                    height: 198.07,
                  ),
                ),
                const SizedBox(height: 20),
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
                const LoginForm(),
                const SizedBox(height: 20),
                // // OR Divider
                // const Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Expanded(child: Divider(color: Colors.white)),
                //     Padding(
                //       padding: EdgeInsets.symmetric(horizontal: 10.0),
                //       child: Text(
                //         'OR',
                //         style: TextStyle(
                //           color: Colors.white,
                //           fontWeight: FontWeight.bold,
                //           fontSize: 17,
                //         ),
                //       ),
                //     ),
                //     Expanded(child: Divider(color: Colors.white)),
                //   ],
                // ),
                // const SizedBox(height: 20),
                // // Google Login Button
                // ElevatedButton(
                //   onPressed: () {
                //     // Handle Google login logic
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: const Color(0xFFF5F5F5),
                //     padding: const EdgeInsets.symmetric(vertical: 15),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(8.0),
                //     ),
                //   ),
                //   child: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Image.asset(
                //         'assets/google_icon.png',
                //         height: 24,
                //       ),
                //       const SizedBox(width: 8),
                //       const Text(
                //         'Login with Google',
                //         style: TextStyle(color: Color(0xFF5F6368)),
                //       ),
                //     ],
                //   ),
                // ),
                // const SizedBox(height: 20),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignUpScreen()),
                          );
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
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController(),
      _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _obscureText = true;
  String _fullName = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    try {
      String? emailText = _emailController.text.trim();

      // Sign in using Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailText,
        password: _passwordController.text,
      );

      // Check if the email is verified
      User? user = userCredential.user;
      if (user != null && !user.emailVerified) {
        // Log the user out immediately
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please verify your email before logging in.',
            ),
          ),
        );

        return;
      }

      // Add/Update last login time in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'lastLogin': FieldValue.serverTimestamp(), // Add last login timestamp
      }, SetOptions(merge: true)); // Merge data to avoid overwriting

      // Fetch the user's full name from Firestore
      String userId = userCredential.user!.uid;
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // Update email in Firestore to new email in Auth if they are different
      /* This is done on login because there does not seem to be a way to listen
          for when the user has verified their new email address after changing
          it in order to only change email in Firestore after verification
       */
      if (emailText != userDoc['email']) {
        print(userDoc['email']);
        await _firestore
            .collection('users')
            .doc(userCredential.user?.uid)
            .update({'email': emailText});
      }

      if (userDoc.exists) {
        // Retrieve full name from Firestore if available
        String fullName = userDoc['fullName'] ?? 'User';
        setState(() {
          _fullName = fullName;
        });

        // Successfully logged in, navigate to the home screen
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, $_fullName!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        // Handle case where user data does not exist in Firestore (shouldn't happen if user data is properly saved)
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data not found in Firestore')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      // Provide user-friendly error messages
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = 'Login failed. Please try again.';
      }

      // Clear any existing snackbars and show new one
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      // General error handling
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Email Input
          TextFormField(
            controller: _emailController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 10, right: 30),
                child: Opacity(
                  opacity: 0.75,
                  child: Icon(
                    Icons.mail_outline,
                    color: Colors.white,
                  ),
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
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          // Password Input
          PasswordTextFormField(
            controller: _passwordController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 10, right: 30),
                child: Opacity(
                  opacity: 0.75,
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                  ),
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
                icon: Icon(
                  Icons.visibility,
                  color: Colors.grey[400],
                ),
                onPressed: () {
                  // Toggle password visibility
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Handle navigation to Register screen
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage()));
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.centerLeft,
              ),
              child: const Text(
                "Forgot?",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFCC00),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          // Login Button
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _loginUser();
              }
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
        ],
      ),
    );
  }
}
