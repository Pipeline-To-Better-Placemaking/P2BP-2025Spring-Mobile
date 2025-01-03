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
            style: TextStyle(
              color: Colors.white,
              fontSize: 16
            ),
            child: ChangePasswordForm(),
          ),
        ),
      )
    );
  }
}

// Define a custom Form widget.
class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  ChangePasswordFormState createState() =>
      ChangePasswordFormState();
}

// Define a corresponding State class.
// This class holds data related to the form.
class ChangePasswordFormState extends State<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: <Widget>[
          const Text('Current Password'),
          PasswordTextFormField(
            decoration: InputDecoration(
                border: OutlineInputBorder()
            ),
          ),
          const Text('New Password'),
          PasswordTextFormField(
            decoration: InputDecoration(
                border: OutlineInputBorder()
            ),
          ),
          const Text('Confirm New Password'),
          PasswordTextFormField(
            decoration: InputDecoration(
                border: OutlineInputBorder()
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              // TODO: Validate form and then do password change on backend

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