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
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          iconColor: Colors.white,
          textColor: Colors.white,
          child: DefaultTextStyle(
            style: const TextStyle(
              color: _clickableColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
                        backgroundColor: _clickableColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        // TODO: Actual functionality
                        print('Test');
                        return;
                      },
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(
                    top: 20,
                    bottom: 10,
                  ),
                  child: Text('Appearance'),
                ),
                const DarkModeSwitch(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.format_size),
                  title: Text('Font Size'),
                  trailing: Icon(Icons.chevron_right),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(
                    top: 20,
                    bottom: 10,
                  ),
                  child: Text('Account'),
                ),
                const ListTile(
                  leading: Icon(Icons.gpp_maybe),
                  title: Text('Change Password'),
                  trailing: Icon(Icons.chevron_right),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Account Privacy'),
                  trailing: Icon(Icons.chevron_right),
                ),
                const ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Delete Account'),
                  iconColor: Colors.redAccent,
                  textColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(
                    top: 20,
                    bottom: 10,
                  ),
                  child: Text('Support'),
                ),
                const ListTile(
                  leading: Icon(Icons.help),
                  title: Text('Help Center'),
                  trailing: Icon(Icons.chevron_right),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Submit a bug report'),
                  trailing: Icon(Icons.chevron_right),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Log Out'),
                  iconColor: Colors.redAccent,
                  textColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DarkModeSwitch extends StatefulWidget {
  final ShapeBorder shape;

  const DarkModeSwitch({super.key, required this.shape});
  
  @override
  State<DarkModeSwitch> createState() => _DarkModeSwitchState();
}

class _DarkModeSwitchState extends State<DarkModeSwitch> {
  /* TODO: Add functionality to get initial state when opening the app from
      previous settings or account or something, and to actually change the
      app's visuals accordingly.
  */
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      shape: widget.shape,
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