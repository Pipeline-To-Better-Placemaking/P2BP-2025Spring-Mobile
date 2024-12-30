import 'package:flutter/material.dart';
import 'widgets.dart';

const _clickableColor = Color(0xFF2D87E8);

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
        body: ListTileTheme(
          tileColor: _clickableColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          iconColor: Colors.white,
          textColor: Colors.white,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 35),
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      // TODO: Actual functionality
                      print('Test');
                      return;
                    },
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
              const Text('Appearance'),
              const DarkModeSwitch(),
              const ListTile(
                leading: Icon(Icons.format_size),
                title: Text('Font Size'),
                trailing: Icon(Icons.chevron_right),
              ),
              const Text('Account'),
              const Text('Support'),
            ],
          ),
        ),
      ),
    );
  }
}

class DarkModeSwitch extends StatefulWidget {
  const DarkModeSwitch({super.key});
  
  @override
  State<DarkModeSwitch> createState() => _DarkModeSwitchState();
}

class _DarkModeSwitchState extends State<DarkModeSwitch> {
  /* TODO: Add functionality to get initial state when opening the app from
      previous settings or account or something, and to actually change the
      app's visuals accordingly.
  */
  bool _isDarkMode = false;
// const Color(0xFF2D87E8)
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: const Icon(Icons.dark_mode_outlined),
      title: const Text('Dark Mode'),
      value: _isDarkMode,
      onChanged: (bool value) {
        setState(() {
          _isDarkMode = value;
        });
      },
    );
  }
  
}