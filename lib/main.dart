import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p2bp_2025spring_mobile/db_schema_classes.dart';

import 'create_project_and_teams.dart';
import 'forgot_password_page.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'new_home_page.dart';
import 'project_comparison_page.dart';
import 'project_details_page.dart';
import 'reset_password_page.dart';
import 'results_panel.dart';
import 'settings_page.dart';
import 'signup_screen.dart';
import 'teams_and_invites_page.dart';

/// All [Test] subclass's register methods should be called here.
void registerTestTypes() {
  LightingProfileTest.register();
  SectionCutterTest.register();
  AbsenceOfOrderTest.register();
  IdentifyingAccessTest.register();
  PeopleInPlaceTest.register();
  PeopleInMotionTest.register();
  NaturePrevalenceTest.register();
  AcousticProfileTest.register();
  SpatialBoundariesTest.register();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock device orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  try {
    // Ensure Firebase is initialized correctly
    await Firebase.initializeApp(
        // options: DefaultFirebaseOptions.currentPlatform,
        );
  } catch (e) {
    print("Firebase initialization failed: $e");
    // Handle the error here, maybe show an error screen or fallback UI
  }
  registerTestTypes(); // Test class setup
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
      home: LoginScreen(),
      routes: {
        '/results': (context) => const ResultsPanel(),
        // '/edit_project': (context) => const EditProjectPanel(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/reset_password': (context) => const ResetPasswordPage(),
        '/create_project_and_teams': (context) =>
            const CreateProjectAndTeamsPage(),
        '/settings': (context) => const SettingsPage(),
        '/teams_and_invites': (context) => const TeamsAndInvitesPage(),
        '/create_project_details': (context) => ProjectDetailsPage(
              activeProject: Project.partialProject(
                  title: 'No data sent',
                  description: 'Accessed without project data',
                  address: 'No address set'),
            ),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/new_home': (context) => const BottomFloatingNavBar(),
        '/compare_projects': (context) => const ProjectComparisonPage(),
        // Commented out since you need project data to create page.
        // '/search': (context) => const SearchScreen(),
        // '/teams_settings': (context) => TeamSettingsScreen(),
      },
    );
  }
}
