import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'strings.dart';

class ChangeEmailPage extends StatelessWidget {
  const ChangeEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Change Email Address'),
        ),
        body: DefaultTextStyle(
          style: TextStyle(
            color: Colors.blue[800],
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              const Text(Strings.changeEmailText1),
              const SizedBox(height: 16),
              ChangeEmailForm(),
              const SizedBox(height: 16),
              const Text(Strings.changeEmailText2),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangeEmailForm extends StatefulWidget {
  const ChangeEmailForm({super.key});

  @override
  State<ChangeEmailForm> createState() => _ChangeEmailFormState();
}

class _ChangeEmailFormState extends State<ChangeEmailForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  User? _currentUser = FirebaseAuth.instance.currentUser;
  String? currentEmail;
  StreamSubscription? _userChangesListener;

  @override
  void initState() {
    super.initState();
    currentEmail = _currentUser?.email;
    _userChangesListener = FirebaseAuth.instance.userChanges().listen((user) {
      setState(() {
        _currentUser = user;
        currentEmail = _currentUser?.email;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _userChangesListener?.cancel();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        String newEmail = _emailController.text.trim();
        await _currentUser?.verifyBeforeUpdateEmail(newEmail);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification email sent successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing email: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            style: TextStyle(
              fontSize: 20,
              color: Colors.black87,
            ),
            'Your current email address is: $currentEmail',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Email Address',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              if (value == _currentUser?.email) {
                return 'This is your current email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _submitForm,
            child: const Text(
              'Submit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }
}
