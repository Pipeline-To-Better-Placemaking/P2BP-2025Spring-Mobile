import 'package:flutter/material.dart';
import 'theme.dart';
import 'strings.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  // TODO extract so many things to a handful of custom widgets or something
  // because this seems like a nightmare to maintain already
  @override
  Widget build(BuildContext context) {
    AssetBundle bundle = DefaultAssetBundle.of(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Forgot Password?'),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
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
            ),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: () {
              // TODO: actually send a reset link
            },
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
