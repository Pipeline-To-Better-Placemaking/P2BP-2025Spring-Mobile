import 'package:flutter/material.dart';

class CreateProjectDetails extends StatefulWidget {
  const CreateProjectDetails({super.key});

  @override
  State<CreateProjectDetails> createState() => _CreateProjectDetailsState();
}

class _CreateProjectDetailsState extends State<CreateProjectDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Placeholder'),
      ),
      body: (const Text('Google maps API call here')),
    );
  }
}
