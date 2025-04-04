import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'strings.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    AssetBundle bundle = DefaultAssetBundle.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: Center(
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 20,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: defaultGrad,
              ),
              padding: const EdgeInsets.all(30),
              child: ListView(
                children: <Widget>[
                  Image(
                    image: AssetImage(
                      'assets/ForgotPasswordBanner.png',
                      bundle: bundle,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    Strings.forgotPasswordText,
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  ForgotPasswordForm(),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: const ButtonStyle(
                      foregroundColor: WidgetStatePropertyAll(
                        Color(0xFFFFD700),
                      ),
                    ),
                    child: const Text(
                      'Return to Login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
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

class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  String _message = '';
  bool _isEmailValid = true;
  bool _isRequestSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> sendForgotEmail() async {
    final email = _emailController.text.trim(); // Trim to avoid trailing spaces

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _isRequestSent = true;
        _message = 'A reset email has been sent to $email.';
      });
    } catch (error) {
      setState(() {
        _isRequestSent = false;
        _message = error.toString(); // Provide error details
      });
    }
  }

  void handleSubmit() {
    final email = _emailController.text.trim();

    if (!RegExp(r"^[^@]+@[^@]+\.[^@]+").hasMatch(email)) {
      setState(() {
        _isEmailValid = false;
        _message = 'Please provide a valid email address.';
      });
    } else {
      setState(() {
        _isEmailValid = true;
        _message = '';
      });
      sendForgotEmail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          if (_message.isNotEmpty)
            Text(
              _message,
              style: TextStyle(
                  color: !_isEmailValid ? Colors.red : Colors.green,
                  fontWeight: FontWeight.normal),
            ),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xD8C3C3C3),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFF6F6F6),
                ),
              ),
              hintStyle: TextStyle(
                color: Color(0xD8C3C3C3),
              ),
              prefixIcon: Icon(
                Icons.mail_outline,
                color: Color(0xD8C3C3C3),
              ),
              hintText: 'Email Address',
              errorText: _isEmailValid ? null : 'Invalid email format',
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: handleSubmit,
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                Color(0xFFFFCC00),
              ),
              foregroundColor: WidgetStatePropertyAll(
                Color(0xFF333333),
              ),
            ),
            child: const Text(
              'Send Reset Link',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
