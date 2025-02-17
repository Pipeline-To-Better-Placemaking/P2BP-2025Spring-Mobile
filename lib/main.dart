import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:p2bp_2025spring_mobile/db_schema_classes.dart';
import 'create_project_details.dart';
import 'results_panel.dart';
import 'edit_project_panel.dart';
import 'forgot_password_page.dart';
import 'reset_password_page.dart';
import 'create_project_and_teams.dart';
import 'settings_page.dart';
import 'teams_and_invites_page.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'new_home_page.dart';
import 'project_comparison_page.dart';
import 'teams_settings_screen.dart';
import 'search_location_screen.dart';
import 'lighting_profile_test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Ensure Firebase is initialized correctly
    await Firebase.initializeApp(
        // options: DefaultFirebaseOptions.currentPlatform,
        );
  } catch (e) {
    print("Firebase initialization failed: $e");
    // Handle the error here, maybe show an error screen or fallback UI
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
    );
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: colorScheme,
      ),
      debugShowCheckedModeBanner: false,
      home: LoginScreen(), // const HomePage(title: 'Home Page'),
      routes: {
        '/results': (context) => const ResultsPanel(),
        '/edit_project': (context) => const EditProjectPanel(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/reset_password': (context) => const ResetPasswordPage(),
        '/create_project_and_teams': (context) =>
            const CreateProjectAndTeamsPage(),
        '/settings': (context) => const SettingsPage(),
        '/teams_and_invites': (context) => const TeamsAndInvitesPage(),
        '/create_project_details': (context) => CreateProjectDetails(
              projectData: Project.partialProject(
                  title: 'No data sent',
                  description: 'Accessed without project data'),
            ),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/new_home': (context) => const BottomFloatingNavBar(),
        '/compare_projects': (context) => const ProjectComparisonPage(),
        // Commented out since you need project data to create page.
        // '/search': (context) => const SearchScreen(),
        '/teams_settings': (context) => TeamSettingsScreen(),
        '/lighting_profile_test': (context) => LightingProfileTestPage(),
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
                version: 0,
              ),
              // Button 2: Results
              buildTempButton(
                context: context,
                route: '/results',
                name: 'Results',
                version: 1,
              ),
              // Button 3: Forgot Password
              buildTempButton(
                context: context,
                route: '/forgot_password',
                name: 'Forgot Password',
                version: 0,
              ),
              // Button 4: Reset Password
              buildTempButton(
                context: context,
                route: '/reset_password',
                name: 'Reset Password',
                version: 1,
              ),
              // Button 5: Create Project/Teams
              buildTempButton(
                context: context,
                route: '/create_project_and_teams',
                name: 'Create Project and Teams',
                version: 0,
              ),
              // Button 6: Settings
              buildTempButton(
                context: context,
                route: '/settings',
                name: 'Settings',
                version: 1,
              ),
              // Button 7: Teams and Invites
              buildTempButton(
                context: context,
                route: '/teams_and_invites',
                name: 'Teams and Invite',
                version: 0,
              ),
              // Button 8: Login
              buildTempButton(
                context: context,
                route: '/login',
                name: 'Login',
                version: 1,
              ),
              // Button 9: Sign Up
              buildTempButton(
                context: context,
                route: '/signup',
                name: 'Sign Up',
                version: 0,
              ),
              // Button 10: Home
              buildTempButton(
                context: context,
                route: '/home',
                name: 'Home',
                version: 1,
              ),
              buildTempButton(
                context: context,
                route: '/new_home',
                name: 'New Home Page',
                version: 0,
              ),
              buildTempButton(
                context: context,
                route: '/compare_projects',
                name: 'Compare Projects',
                version: 1,
              ),
              // Button 13: Team Settings
              buildTempButton(
                context: context,
                route: '/teams_settings',
                name: 'Team Settings',
                version: 0,
              ),
              // Button 14: Project Details
              buildTempButton(
                context: context,
                route: '/create_project_details',
                name: 'Create Project Details',
                version: 1,
              ),
              buildTempButton(
                context: context,
                route: '/lighting_profile_test',
                name: 'Lighting Profile Test',
                version: 0,
              ),
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
