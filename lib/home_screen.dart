import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:p2bp_2025spring_mobile/create_project_details.dart';
import 'db_schema_classes.dart';
import 'theme.dart';
import 'create_project_and_teams.dart';
import 'project_comparison_page.dart';
import 'settings_page.dart';
import 'teams_and_invites_page.dart';
import 'results_panel.dart';
import 'edit_project_panel.dart';
import 'main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_functions.dart';

List<String> navIcons2 = [
  'assets/Home_Icon.png',
  'assets/Add_Icon.png',
  'assets/Compare_Icon.png',
  'assets/Profile_Icon.png',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  List<Project> _projectList = [];
  DocumentReference? teamRef;
  int _projectsCount = 0;
  bool _isLoading = true;
  int selectedIndex = 0;
  String _firstName = 'User';

  @override
  void initState() {
    super.initState();
    _getUserFirstName();
    _populateProjects();
  }

  Future<void> _populateProjects() async {
    try {
      teamRef = await getCurrentTeam();
      if (teamRef == null) {
        print(
            "Error populating projects in home_screen.dart. No selected team available.");
      } else {
        _projectList = await getTeamProjects(teamRef!);
      }
      setState(() {
        _projectsCount = _projectList.length;
        _isLoading = false;
      });
    } catch (e) {
      print("Error in _populateProjects(): $e");
    }
  }

  // Gets name from DB, get the first word of that, then sets _firstName to it
  Future<void> _getUserFirstName() async {
    try {
      String fullName = await getUserFullName(_currentUser?.uid);

      // Get first name from full name
      String firstName = fullName.split(' ').first;

      if (_firstName != firstName) {
        setState(() {
          _firstName = firstName;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred while retrieving your name: $e',
          ),
        ),
      );
    }
  }

  void onNavItemTapped(int index) {
    setState(() {
      selectedIndex = index; // Update the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: selectedIndex,
            children: [
              // Screens for each tab
              _buildHomeContent(),
              CreateProjectAndTeamsPage(),
              ProjectComparisonPage(),
              SettingsPage(),
            ],
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _navBar(),
    );
  }

  Widget buildProjectCard({
    required BuildContext context,
    required String bannerImage, // Image path for banner
    required Project project, // Project name
    required String teamName, // Team name
    required int index,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12) // Match the container's corner radius
          ),
      child: InkWell(
        onTap: () async {
          // TODO: Navigation to project details page
          Project tempProject = await getProjectInfo(project.projectID);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreateProjectDetails(projectData: tempProject),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3874CB), Color(0xFF183769)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner image at the top
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.asset(
                  bannerImage,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              // Project details section
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project name
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFCC00),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Team name
                    Text(
                      teamName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFCC00),
                      ),
                    ),
                  ],
                ),
              ),
              // Row with Edit and Results buttons in the bottom right corner
              Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                  right: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit Info button
                    OutlinedButton(
                      onPressed: () {
                        // Handle navigation to Edit menu
                        showEditProjectModalSheet(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFFFCC00),
                          width: 2.0,
                        ),
                        foregroundColor: const Color(0xFFFFCC00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Edit Info',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Results button
                    ElevatedButton(
                      onPressed: () {
                        // Handle navigation to Results menu
                        showResultsModalSheet(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Results',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1D4076),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await _populateProjects();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // P2BP Logo centered at the top
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        'assets/P2BP_Logo.png',
                        width: 40,
                        height: 40,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Notification button
                          IconButton(
                            icon: Image.asset('assets/bell-03.png'),
                            onPressed: () {
                              // Handle notification button action
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(
                                    title: '/home',
                                  ),
                                ),
                              );
                            },
                            iconSize: 24,
                          ),
                          // Teams Button
                          IconButton(
                            icon: const Icon(Icons.group),
                            color: const Color(0xFF0A2A88),
                            onPressed: () async {
                              // Navigate to Teams/Invites screen
                              await Navigator.pushNamed(
                                  context, '/teams_and_invites');
                              _populateProjects();
                            },
                            iconSize: 24,
                          ),
                        ],
                      ),
                    ),
                    // "Hello, [user]" greeting, aligned to the left below the logo
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return defaultGrad.createShader(bounds);
                            },
                            child: Text(
                              'Hello, $_firstName',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2, // Masked text with gradient
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // "Your Projects" label, aligned to the right of the screen"
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return defaultGrad.createShader(bounds);
                      },
                      child: const Text(
                        'Your Projects',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Project Cards
              _projectsCount > 0
                  // If there are projects populate ListView
                  ? ListView.separated(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(
                        left: 15,
                        right: 15,
                        top: 25,
                        bottom: 25,
                      ),
                      itemCount: _projectsCount,
                      itemBuilder: (BuildContext context, int index) {
                        return buildProjectCard(
                          context: context,
                          bannerImage: 'assets/RedHouse.png',
                          project: _projectList[index],
                          teamName: 'Team: Eola Design Group',
                          index: index,
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(
                        height: 50,
                      ),
                    )
                  // Else if there are no projects
                  : _isLoading == true
                      // If loading display loading indicator
                      ? const Center(child: CircularProgressIndicator())
                      // Else display text to create new project
                      : RefreshIndicator(
                          onRefresh: () async {
                            await _populateProjects();
                          },
                          child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 3,
                              child: Center(
                                child: Text(
                                    "You have no projects! Join a team or create a project first."),
                              ),
                            ),
                          ),
                        ),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(right: 24, left: 24, bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2F6DCF),
        borderRadius: BorderRadius.circular(120),
        boxShadow: [
          BoxShadow(
            color: Color.alphaBlend(
              Colors.black.withAlpha(102), // 40% opacity for the shadow
              Colors.transparent, // Transparent background blending
            ),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: navIcons2.map((iconPath) {
          int index = navIcons2.indexOf(iconPath);
          bool isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onNavItemTapped(index), // Update selectedIndex
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFFE6A800)
                        : Colors.transparent,
                  ),
                  child: Image.asset(
                    iconPath,
                    width: 30,
                    height: 30,
                    color: isSelected
                        ? const Color(0xFF2F6DCF)
                        : const Color(0xFFFFCC00),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
