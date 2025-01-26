import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'strings.dart';

class ChangeNamePage extends StatelessWidget {
  const ChangeNamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Change Name'),
        ),
        body: DefaultTextStyle(
          style: TextStyle(
            color: Colors.blue[800],
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          child: ListView(
            padding: const EdgeInsets.all(30),
            children: <Widget>[
              const Text(Strings.changeNameText),
              const SizedBox(height: 16),
              ChangeNameForm(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangeNameForm extends StatefulWidget {
  const ChangeNameForm({super.key});

  @override
  State<ChangeNameForm> createState() => _ChangeNameFormState();
}

class _ChangeNameFormState extends State<ChangeNameForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  User? _currentUser = FirebaseAuth.instance.currentUser;
  String _currentFullName = 'Loading...';
  StreamSubscription? _userChangesListener;

  bool _isNameChanged = false;

  @override
  void initState() {
    super.initState();
    _getUserFullName();

    // Meant to listen for auth update after changing email to update displayed
    // current email address. But it doesn't work, the email never updates
    // except sometimes to null.
    _userChangesListener = FirebaseAuth.instance.userChanges().listen((user) {
      _currentUser = user;
      _getUserFullName();
    });
  }

  Future<void> _getUserFullName() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser?.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _currentFullName = userDoc['fullName'] ?? 'User';
        });
      } else {
        setState(() {
          _currentFullName = 'User';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred while retrieving your name: $e',
          ),
        ),
      );
    }
  }

  Future<void> _submitNameChange() async {
    if (_formKey.currentState!.validate()) {
      try {
        String newName = _fullNameController.text.trim();
        print(newName);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser?.uid)
            .update({'fullName': newName});
        setState(() {
          _isNameChanged = true;
        });
        // Refresh current name being displayed
        _getUserFullName();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing name: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _userChangesListener?.cancel();
    super.dispose();
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
            'Your current name is:\n$_currentFullName',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fullNameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Full Name',
            ),
            keyboardType: TextInputType.name,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your new name';
              }
              if (value == _currentFullName) {
                return 'This is already your name';
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
            onPressed: _submitNameChange,
            child: const Text(
              'Submit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isNameChanged)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 16),
                Text(
                  'Your name has been changed successfully.',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
