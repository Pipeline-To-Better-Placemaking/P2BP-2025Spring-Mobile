import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';

import 'firestore_functions.dart';
import 'strings.dart';

class ChangeNamePage extends StatelessWidget {
  const ChangeNamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark
            .copyWith(statusBarColor: Colors.transparent),
        title: const Text('Change Name'),
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
          child: SafeArea(child: ChangeNameForm()),
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
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _currentFullName = 'Loading...';
  StreamSubscription? _userChangesListener;

  bool _isNameChanged = false;

  @override
  void initState() {
    super.initState();
    _getUserFullName();
  }

  // Gets name from DB and then sets local field _currentFullName to that
  Future<void> _getUserFullName() async {
    try {
      String name = await getUserFullName(_currentUser?.uid);

      if (_currentFullName != name) {
        setState(() {
          _currentFullName = name;
        });
      }
    } catch (e) {
      if (!mounted) return;
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
        if (!mounted) return;
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
      child: ListView(
        children: <Widget>[
          const Text(Strings.changeNameText),
          const SizedBox(height: 16),
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
              backgroundColor: p2bpBlue,
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
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
