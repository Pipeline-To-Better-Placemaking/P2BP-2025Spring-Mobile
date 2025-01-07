import 'package:flutter/material.dart';
import 'widgets.dart';
import 'theme.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Change Password'),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: defaultGrad,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: DefaultTextStyle(
            style: TextStyle(color: Colors.white, fontSize: 16),
            child: ChangePasswordForm(),
          ),
        ),
      ),
    );
  }
}

class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController // this comment is for fixing formatting
      _currentPasswordController = TextEditingController(),
      _newPasswordController = TextEditingController(),
      _confirmPasswordController = TextEditingController();
  String? _currentPassErrorText, _newPassErrorText, _confirmPassErrorText;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: <Widget>[
          const Text('Current Password'),
          PasswordTextFormField(
            controller: _currentPasswordController,
            forceErrorText: _currentPassErrorText,
            decoration: InputDecoration(border: OutlineInputBorder()),
          ),
          const Text('New Password'),
          PasswordTextFormField(
            controller: _newPasswordController,
            forceErrorText: _newPassErrorText,
            decoration: InputDecoration(border: OutlineInputBorder()),
          ),
          const Text('Confirm New Password'),
          PasswordTextFormField(
            controller: _confirmPasswordController,
            forceErrorText: _confirmPassErrorText,
            decoration: InputDecoration(border: OutlineInputBorder()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              setState(() {
                // All validation logic is here
                String currentPass = _currentPasswordController.text,
                    newPass = _newPasswordController.text,
                    confirmPass = _confirmPasswordController.text;
                // Resets all error states to null before checking
                _currentPassErrorText = null;
                _newPassErrorText = null;
                _confirmPassErrorText = null;
                if (currentPass.isEmpty) {
                  _currentPassErrorText = 'Please enter some text.';
                }
                if (newPass.isEmpty) {
                  _newPassErrorText = 'Please enter some text.';
                }
                if (confirmPass.isEmpty) {
                  _confirmPassErrorText = 'Please enter some text.';
                }
                // TODO: Add check/error text for if current pass is wrong
                if (newPass.isNotEmpty &&
                    confirmPass.isNotEmpty &&
                    newPass != confirmPass) {
                  _newPassErrorText = 'Passwords do not match.';
                  _confirmPassErrorText = 'Passwords do not match.';
                }
                // Only succeeds if none of the fields had an error
                if (_currentPassErrorText == null &&
                    _newPassErrorText == null &&
                    _confirmPassErrorText == null) {
                  // TODO: Change password on backend here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Processing Data...')),
                  );
                }
              });
            },
            child: const Text(
              'Submit',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
