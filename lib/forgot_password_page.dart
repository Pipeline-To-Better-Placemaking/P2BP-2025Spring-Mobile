import 'package:flutter/material.dart';
import 'strings.dart';
import 'widgets.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  // TODO extract so many things to a handful of custom widgets or something
  // because this seems like a nightmare to maintain already
  @override
  Widget build(BuildContext context) {
    AssetBundle bundle = DefaultAssetBundle.of(context);
    return SafeArea(
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('Forgot Password?'),
        // ),
        body: Center(
          child: GradientContainer(
            colors: const [ // light mode colors TODO extract frequently used colors
                            // to their own class along with adding dark mode
              Color(0xFF0A2A88),
              Color(0xFF62B6FF),
            ],
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 20
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 64.0, 0, 8.0),
                      child: Image(
                        image: AssetImage(
                          'assets/ForgotPasswordBanner.png',
                          bundle: bundle,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 8.0, 0, 8.0),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 40
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 4.0, 0, 4.0),
                      child: Text(Strings.forgotPasswordText),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 12.0, 0, 20.0),
                      child: TextField(
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xD8C3C3C3)
                              )
                          ),
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFFF6F6F6)
                              )
                          ),
                          hintStyle: TextStyle(
                            color: Color(0xD8C3C3C3)
                          ),
                          prefixIcon: Icon(
                            Icons.mail_outline,
                            color: Color(0xD8C3C3C3),
                          ),
                          hintText: 'Email Address',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4.0, 0, 4.0),
                      child: TextButton(
                        onPressed: () {}, // TODO actually send a reset link
                        style: const ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Color(0xFFFFCC00)),
                          foregroundColor: WidgetStatePropertyAll(Color(0xFF333333)),
                        ),
                        child: const Text(
                          'Send Reset Link',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4.0, 0, 4.0),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context), // pops current screen off nav stack
                        style: const ButtonStyle(
                          foregroundColor: WidgetStatePropertyAll(Color(0xFFFFD700)),
                        ),
                        child: const Text(
                          'Return to Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

