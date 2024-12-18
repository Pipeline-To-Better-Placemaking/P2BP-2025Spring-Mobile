import 'package:flutter/material.dart';
import 'theme.dart';

class CreateProjectAndTeamsPage extends StatefulWidget {
  const CreateProjectAndTeamsPage({super.key});

  @override
  State<CreateProjectAndTeamsPage> createState() =>
      _CreateProjectAndTeamsPageState();
}

class _CreateProjectAndTeamsPageState extends State<CreateProjectAndTeamsPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // Top switch between Projects/Teams
        appBar: AppBar(
          title: const Text('Placeholder'),
        ),
        // Creation screens
        body: Center(
          child: Container(child: Text('Placeholder 2')),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Container(height: 1000.0, child: Text('Placeholder 3')),
        ),
      ),
    );
  }
}
