import 'package:flutter/material.dart';
import 'widgets.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    AssetBundle bundle = DefaultAssetBundle.of(context);
    return SafeArea(
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('Reset Password'),
        // ),
        body: Center(
          child: GradientContainer(
            colors: const [ // light mode colors
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
                          'assets/ResetPasswordBanner.png',
                          bundle: bundle
                        )
                      )
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 8.0, 0, 8.0),
                      child: Text(
                        'Reset Password',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 40
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 12.0, 0, 12.0),
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
                            Icons.lock_open,
                            color: Color(0xD8C3C3C3),
                          ),
                          hintText: 'Password',
                        ),
                      ),
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
                            Icons.lock_outline,
                            color: Color(0xD8C3C3C3),
                          ),
                          hintText: 'Confirm Password',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4.0, 0, 4.0),
                      child: TextButton(
                        onPressed: () {}, // TODO actual updating of password
                        style: const ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Color(0xFFFFCC00)),
                          foregroundColor: WidgetStatePropertyAll(Color(0xFF333333)),
                        ),
                        child: const Text(
                          'Update Password',
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