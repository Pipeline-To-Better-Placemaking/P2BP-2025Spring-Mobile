import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';

import 'db_schema_classes.dart';
import 'strings.dart';

class ChangeEmailPage extends StatelessWidget {
  final Member member;

  const ChangeEmailPage({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark
            .copyWith(statusBarColor: Colors.transparent),
        title: const Text('Change Email Address'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0) +
            MediaQuery.viewInsetsOf(context),
        child: DefaultTextStyle(
          style: TextStyle(
            color: p2bpBlue,
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          child: SafeArea(child: ChangeEmailForm(member: member)),
        ),
      ),
    );
  }
}

class ChangeEmailForm extends StatefulWidget {
  final Member member;

  const ChangeEmailForm({super.key, required this.member});

  @override
  State<ChangeEmailForm> createState() => _ChangeEmailFormState();
}

class _ChangeEmailFormState extends State<ChangeEmailForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isEmailSent = false;

  Future<void> _submitEmailChange() async {
    if (_formKey.currentState!.validate()) {
      try {
        String newEmail = _emailController.text.trim();
        await _currentUser?.verifyBeforeUpdateEmail(newEmail);

        setState(() {
          _isEmailSent = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification email sent successfully!')),
          );
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing email: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: <Widget>[
          const Text(Strings.changeEmailText1),
          const SizedBox(height: 16),
          Text(
            style: TextStyle(
              fontSize: 20,
              color: Colors.black87,
            ),
            'Your current email address is:\n${widget.member.email}',
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
                return 'Please enter your new email address';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              if (value == widget.member.email) {
                return 'This is your current email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: p2bpBlue,
              padding: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _submitEmailChange,
            child: const Text(
              'Submit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isEmailSent)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 16),
                Text(
                  'The verification email sent successfully.',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  Strings.changeEmailText2,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
