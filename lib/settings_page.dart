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

        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          children: <Widget>[
            Column(
              children: <Widget>[
                PhotoUpload(
                  width: 60,
                  height: 60,
                  icon: Icons.add_photo_alternate,
                  circular: true,
                  onTap: () {
                    // TODO: Actual functionality
                    print('Test');
                    return;
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('Edit Profile'),
                  onPressed: () {
                    // TODO: Actual functionality
                    print('Test');
                    return;
                  },
                ),
              ],
            ),
            const Text('Appearance'),

          ],
        ),

        bottomNavigationBar: const BottomFloatingNavBar(),
      ),
    );
  }
}