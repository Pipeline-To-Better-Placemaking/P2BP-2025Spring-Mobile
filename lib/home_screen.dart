import 'package:flutter/material.dart';
import 'theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

List<String> navIcons2 = [
  'assets/Home_Icon.png',
  'assets/Add_Icon.png',
  'assets/Compare_Icon.png',
  'assets/Profile_Icon.png',
];

int selectedIndex = 0;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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
                            },
                            iconSize: 24,
                          ),
                          // Teams Button
                          IconButton(
                            icon: const Icon(Icons.group),
                            color: const Color(0xFF0A2A88),
                            onPressed: () {
                              // Handle teams button action
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
                            child: const Text(
                              'Hello,\nMichael',
                              style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2 // Masked text with gradient
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
              Column(
                children: [
                  // First Project Card
                  buildProjectCard(
                    context,
                    'assets/RedHouse.png',
                    'Project Eola',
                    'Team: Eola Design Group',
                  ),
                  const SizedBox(height: 20),
                  // Second Project Card
                  buildProjectCard(
                    context,
                    'assets/PinkHouse.png',
                    'Project Neocity',
                    'Team: New Horizons Placemakers',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Bottom Navigation Bar
              _navBar()
            ],
          ),
        ),
      ),
    );
  }

  Widget buildProjectCard(
    BuildContext context,
    String bannerImage, // Image path for banner
    String projectName, // Project name
    String teamName, // Team name
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12) // Match the container's corner radius
          ),
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
                    projectName,
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
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: navIcons2.map((iconPath) {
          int index = navIcons2.indexOf(iconPath);
          bool isSelected = selectedIndex == index;
          return Material(
            color: Colors.transparent,
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