import 'package:flutter/material.dart';
import 'widgets.dart';
import 'theme.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    AssetBundle bundle = DefaultAssetBundle.of(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reset Password'),
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
                      'assets/ResetPasswordBanner.png',
                      bundle: bundle,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                    ),
                  ),
                  SizedBox(height: 10),
                  ResetPasswordForm(),
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
                        fontSize: 18,
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

class ResetPasswordForm extends StatefulWidget {
  const ResetPasswordForm({super.key});

  @override
  ResetPasswordFormState createState() => ResetPasswordFormState();
}

class ResetPasswordFormState extends State<ResetPasswordForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          PasswordTextFormField(
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
                Icons.lock_open,
                color: Color(0xD8C3C3C3),
              ),
              hintText: 'Password',
            ),
          ),
          SizedBox(height: 10),
          PasswordTextFormField(
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
                Icons.lock_outline,
                color: Color(0xD8C3C3C3),
              ),
              hintText: 'Confirm Password',
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {}, // TODO actual updating of password
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                Color(0xFFFFCC00),
              ),
              foregroundColor: WidgetStatePropertyAll(
                Color(0xFF333333),
              ),
            ),
            child: const Text(
              'Update Password',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }
}
