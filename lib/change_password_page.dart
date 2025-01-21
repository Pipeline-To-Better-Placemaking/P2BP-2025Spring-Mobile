import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Change Password'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: DefaultTextStyle(
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController // this comment is for fixing formatting
      _currentPasswordController = TextEditingController(),
      _newPasswordController = TextEditingController(),
      _confirmPasswordController = TextEditingController();
  String? _currentPassErrorText, _newPassErrorText, _confirmPassErrorText;
  bool _currentPassObscureText = true;
  bool _newPassObscureText = true;
  bool _confirmPassObscureText = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Returns true if current password matches, otherwise false and/or throws error.
  Future<bool> _validateCurrentPassword(String password) async {
    try {
      // Verify given password matches user
      UserCredential? userCredential =
          await _currentUser?.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: _currentUser.email!,
          password: password,
        ),
      );
      // If credential exists and matches current user, returns true
      if (userCredential != null &&
          userCredential.user?.uid == _currentUser?.uid) {
        return true;
      } else {
        _currentPassErrorText = 'Current password given is not correct.';
        return false;
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = e.code;
      _currentPassErrorText = 'An error occurred: $errorMessage';
      return false;
    } catch (e) {
      _currentPassErrorText = 'An error occurred: $e';
      return false;
    }
  }

  // Validates data and then updates the password if everything validates.
  Future<void> _submitForm() async {
    String currentPass = _currentPasswordController.text,
        newPass = _newPasswordController.text,
        confirmPass = _confirmPasswordController.text;
    bool isCurrentPassValid = false;

    // Resets all error states to null before validating
    _currentPassErrorText = null;
    _newPassErrorText = null;
    _confirmPassErrorText = null;

    // Verify current password given matches this account's password.
    isCurrentPassValid = await _validateCurrentPassword(currentPass);

    // Checks that none of the fields are empty
    if (currentPass.isEmpty) {
      _currentPassErrorText = 'Please enter some text.';
    }
    if (newPass.isEmpty) {
      _newPassErrorText = 'Please enter some text.';
    }
    if (confirmPass.isEmpty) {
      _confirmPassErrorText = 'Please enter some text.';
    }

    // Verify new and confirm password fields are not empty and they match.
    if (_newPassErrorText == null &&
        _confirmPassErrorText == null &&
        newPass != confirmPass) {
      _newPassErrorText = 'Passwords do not match.';
      _confirmPassErrorText = 'Passwords do not match.';
    }

    // Only succeeds if none of the fields had an error and current pass was valid.
    if (_currentPassErrorText == null &&
        _newPassErrorText == null &&
        _confirmPassErrorText == null &&
        isCurrentPassValid) {
      try {
        await _currentUser?.updatePassword(newPass);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password changed successfully.')),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = e.code;
        _currentPassErrorText = 'An error occurred: $errorMessage';
      }
    }

    setState(() {});
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
            obscureText: _currentPassObscureText,
            forceErrorText: _currentPassErrorText,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  // Toggle password visibility
                  setState(
                      () => _currentPassObscureText = !_currentPassObscureText);
                },
              ),
            ),
          ),
          SizedBox(height: 12),
          const Text('New Password'),
          PasswordTextFormField(
            controller: _newPasswordController,
            obscureText: _newPassObscureText,
            forceErrorText: _newPassErrorText,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  // Toggle password visibility
                  setState(() => _newPassObscureText = !_newPassObscureText);
                },
              ),
            ),
          ),
          SizedBox(height: 12),
          const Text('Confirm New Password'),
          PasswordTextFormField(
            controller: _confirmPasswordController,
            obscureText: _confirmPassObscureText,
            forceErrorText: _confirmPassErrorText,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  // Toggle password visibility
                  setState(
                      () => _confirmPassObscureText = !_confirmPassObscureText);
                },
              ),
            ),
          ),
          SizedBox(height: 12),
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
          ),
        ],
      ),
    );
  }
}
