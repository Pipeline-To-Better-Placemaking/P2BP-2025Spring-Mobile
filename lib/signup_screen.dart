import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';
import 'theme.dart';
import 'login_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: defaultGrad,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: <Widget>[
            // Logo Illustration
            Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                Image.asset('assets/landscape_weather.png', height: 301),
                const Positioned(
                  bottom: 0,
                  left: 0,
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Google Sign Up Button
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
                    'assets/custom_icons/google_icon.png',
                    width: 28,
                    height: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sign Up with Google',
                    style: TextStyle(
                      color: Color(0xFF5F6368),
                      fontSize: 17,
                    ),
                  ),
                ],
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
                      fontSize: 17,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 20),
            SignUpForm(),
            const SizedBox(height: 20),
            // Already have an account redirect
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Handle navigation to the Login screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    child: const Text(
                      "Login",
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

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController(),
      _emailController = TextEditingController(),
      _passwordController = TextEditingController(),
      _confirmPasswordController = TextEditingController();
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Validation feedback variables
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasDigits = false;
  bool _hasSpecialCharacter = false;
  bool _isLengthValid = false;
  bool _isTypingPassword = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Register user with Firebase
  Future<void> _registerUser() async {
    print(_auth.toString());
    if (_formKey.currentState!.validate()) {
      try {
        // Create user with email and password
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Update the user's displayName with the full name entered during registration
        await userCredential.user
            ?.updateProfile(displayName: _fullNameController.text.trim());

        // Add user data to Firestore
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'creationTime': FieldValue.serverTimestamp(),
        });

        // Send email verification
        if (userCredential.user != null) {
          await userCredential.user!.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registration successful! A verification email has been sent to ${_emailController.text.trim()}. Please verify your email before logging in.',
              ),
            ),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User Registered Successfully!')),
        );

        Navigator.pop(context);
      } catch (e, stacktrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register: $e')),
        );
        print('Exception: $e');
        print('Stacktrace: $stacktrace');
      }
    }
  }

  void _checkPasswordConditions(String value) {
    setState(() {
      _isTypingPassword = true;
      _hasUpperCase = value.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = value.contains(RegExp(r'[a-z]'));
      _hasDigits = value.contains(RegExp(r'[0-9]'));
      _hasSpecialCharacter = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _isLengthValid = value.length >= 12;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Full Name Input
          TextFormField(
            controller: _fullNameController,
            cursorColor: Colors.white,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 10, right: 30),
                child: ImageIcon(
                  AssetImage('assets/custom_icons/User_box.png'),
                  color: Colors.white,
                ),
              ),
              labelText: 'Full Name',
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
          // Email Address Input
          TextFormField(
            controller: _emailController,
            cursorColor: Colors.white,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 10, right: 30),
                child: Opacity(
                  opacity: 0.75,
                  child: ImageIcon(
                    AssetImage('assets/custom_icons/mail_icon.png'),
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          // Password Input
          PasswordTextFormField(
            controller: _passwordController,
            obscureText: _obscureText,
            cursorColor: Colors.white,
            style: TextStyle(color: Colors.white),
            onChanged: _checkPasswordConditions,
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(
                  left: 10,
                  right: 30,
                ),
                child: ImageIcon(
                  AssetImage('assets/custom_icons/Unlock.png'),
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
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Confirm Password Input
          PasswordTextFormField(
            controller: _confirmPasswordController,
            cursorColor: Colors.white,
            style: TextStyle(color: Colors.white),
            obscureText: _obscureConfirmText,
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(
                  left: 10,
                  right: 30,
                ),
                child: ImageIcon(
                  AssetImage('assets/custom_icons/Lock.png'),
                  color: Colors.white,
                ),
              ),
              labelText: 'Confirm Password',
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
                icon: const Icon(Icons.visibility, color: Colors.grey),
                onPressed: () {
                  // Toggle password visibility
                  setState(() {
                    _obscureConfirmText = !_obscureConfirmText;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Sign Up Button
          ElevatedButton(
            onPressed: _registerUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFFCC00),
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'Sign Up',
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
