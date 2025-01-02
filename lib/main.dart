import 'package:flutter/material.dart';
import 'create_project_details.dart';
import 'results_panel.dart';
import 'edit_project_panel.dart';
import 'forgot_password_page.dart';
import 'reset_password_page.dart';
import 'create_project_and_teams.dart';
import 'settings_page.dart';
import 'teams_and_invites_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          // Insert theme here
          ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(title: 'Home Page'),
      routes: {
        '/results': (context) => const ResultsPanel(),
        '/edit_project': (context) => const EditProjectPanel(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/reset_password': (context) => const ResetPasswordPage(),
        '/create_project_and_teams': (context) =>
            const CreateProjectAndTeamsPage(),
        '/settings': (context) => const SettingsPage(),
        '/teams_and_invites': (context) => const TeamsAndInvitesPage(),
        '/create_project_details': (context) => const CreateProjectDetails(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageStates();
}

class _HomePageStates extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Button 1: Edit Project
              buildTempButton(
                  context: context,
                  route: '/edit_project',
                  name: 'Edit Project',
                  version: 0),

              // Button 2: Results
              buildTempButton(
                  context: context,
                  route: '/results',
                  name: 'Results',
                  version: 1),

              // Button 3: Forgot Password
              buildTempButton(
                  context: context,
                  route: '/forgot_password',
                  name: 'Forgot Password',
                  version: 0),

              // Button 4: Reset Password
              buildTempButton(
                  context: context,
                  route: '/reset_password',
                  name: 'Reset Password',
                  version: 1),

              // Button 5: Create Project/Teams
              buildTempButton(
                  context: context,
                  route: '/create_project_and_teams',
                  name: 'Create Project and Teams',
                  version: 0),

              // Button 6: Settings
              buildTempButton(
                  context: context,
                  route: '/settings',
                  name: 'Settings',
                  version: 1),
              buildTempButton(
                  context: context,
                  route: '/teams_and_invites',
                  name: 'Teams and Invite',
                  version: 0),
            ],
          ),
        ),
      ),
    );
  }

  // Function to create temp buttons for main page
  Expanded buildTempButton({
    required BuildContext context,
    required String route,
    required String name,
    required int version,
  }) {
    Color foregroundColor;
    Color backgroundColor;

    if (version == 0) {
      foregroundColor = Colors.black;
      backgroundColor = const Color(0xFFFFCC00);
    } else {
      foregroundColor = Colors.white;
      backgroundColor = Colors.blue;
    }

    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        onPressed: () {
          Navigator.pushNamed(context, route);
        },
        child: Text(name),
      ),
    );
  }
}
