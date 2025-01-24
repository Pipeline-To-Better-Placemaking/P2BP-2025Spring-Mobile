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
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitForm() {}

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Full Name',
            ),
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
