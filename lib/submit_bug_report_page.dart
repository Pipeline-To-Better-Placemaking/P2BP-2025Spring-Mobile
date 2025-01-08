import 'package:flutter/material.dart';
import 'theme.dart';
import 'strings.dart';

class SubmitBugReportPage extends StatelessWidget {
  const SubmitBugReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Submit a bug report'),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: defaultGrad,
          ),
          padding: const EdgeInsets.all(30),
          child: DefaultTextStyle(
            style: TextStyle(color: Colors.white, fontSize: 16),
            child: SubmitBugReportForm(),
          ),
        ),
      ),
    );
  }
}

class SubmitBugReportForm extends StatefulWidget {
  const SubmitBugReportForm({super.key});

  @override
  State<SubmitBugReportForm> createState() => _SubmitBugReportFormState();
}

class _SubmitBugReportFormState extends State<SubmitBugReportForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: <Widget>[
          const Text(Strings.submitBugReportText),
        ],
      ),
    );
  }
}
