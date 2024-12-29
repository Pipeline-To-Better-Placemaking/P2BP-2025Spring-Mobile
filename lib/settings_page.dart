import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        bottomNavigationBar: const BottomFloatingNavBar(),
      ),
    );
  }
}
