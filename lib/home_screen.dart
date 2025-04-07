import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p2bp_2025spring_mobile/project_card_page.dart';

import 'create_project_and_teams.dart';
import 'db_schema_classes.dart';
import 'settings_page.dart';
import 'theme.dart';

const List<String> navIcons2 = [
  'assets/Add_Icon.png',
  'assets/Home_Icon.png',
  'assets/Profile_Icon.png',
];

class HomeScreen extends StatefulWidget {
  final Member member;

  const HomeScreen({super.key, required this.member});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 1;

  void onNavItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: SafeArea(
          maintainBottomViewPadding: true,
          child: Stack(
            children: [
              IndexedStack(
                index: selectedIndex,
                children: [
                  // Screens for each tab
                  CreateProjectAndTeamsPage(member: widget.member),
                  ProjectCardPage(member: widget.member),
                  SettingsPage(member: widget.member),
                ],
              ),
            ],
          ),
        ),
        extendBody: true,
        bottomNavigationBar: _navBar(),
      ),
    );
  }

  // Widget _buildHomeContent() {
  //   return RefreshIndicator(
  //     onRefresh: () async {
  //       await _populateProjects();
  //     },
  //     child: SingleChildScrollView(
  //       physics: AlwaysScrollableScrollPhysics(),
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(
  //           horizontal: 20,
  //           vertical: 5,
  //         ),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           mainAxisSize: MainAxisSize.min,
  //           children: <Widget>[
  //             // P2BP Logo centered at the top
  //             Stack(
  //               children: [
  //                 Align(
  //                   alignment: Alignment.topCenter,
  //                   child: Image.asset(
  //                     'assets/P2BP_Logo.png',
  //                     width: 40,
  //                     height: 40,
  //                   ),
  //                 ),
  //                 Align(
  //                   alignment: Alignment.topRight,
  //                   child: Row(
  //                     mainAxisAlignment: MainAxisAlignment.end,
  //                     children: [
  //                       // Teams Button
  //                       Container(
  //                         width: 36,
  //                         height: 36,
  //                         decoration: BoxDecoration(
  //                             shape: BoxShape.circle,
  //                             color: Color(0xFF2F6DCF),
  //                             border: Border.all(
  //                                 color: Color(0xFF0A2A88), width: 3)),
  //                         child: Center(
  //                           child: IconButton(
  //                             padding: EdgeInsets.zero,
  //                             icon: const Icon(Icons.groups),
  //                             color: p2bpYellow,
  //                             onPressed: () async {
  //                               // Navigate to Teams/Invites screen
  //                               await Navigator.push(
  //                                 context,
  //                                 MaterialPageRoute(
  //                                   builder: (context) =>
  //                                       const TeamsAndInvitesPage(),
  //                                 ),
  //                               );
  //                               _populateProjects();
  //                             },
  //                             iconSize: 24,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 // "Hello, [user]" greeting, aligned to the left below the logo
  //                 Padding(
  //                   padding: const EdgeInsets.only(top: 40, left: 10),
  //                   child: Row(
  //                     mainAxisAlignment: MainAxisAlignment.start,
  //                     children: [
  //                       ShaderMask(
  //                         shaderCallback: (bounds) {
  //                           return defaultGrad.createShader(bounds);
  //                         },
  //                         child: Text(
  //                           'Hello, \n$_firstName',
  //                           style: TextStyle(
  //                             fontSize: 36,
  //                             fontWeight: FontWeight.bold,
  //                             color: Colors.white,
  //                             height: 1.2, // Masked text with gradient
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             // "Your Projects" label, aligned to the right of the screen"
  //             Padding(
  //               padding: const EdgeInsets.only(right: 5),
  //               child: Row(
  //                 mainAxisAlignment: MainAxisAlignment.end,
  //                 children: [
  //                   ShaderMask(
  //                     shaderCallback: (bounds) {
  //                       return defaultGrad.createShader(bounds);
  //                     },
  //                     child: const Text(
  //                       'Your Projects',
  //                       style: TextStyle(
  //                         fontSize: 24,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.white,
  //                         height: 1.2,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             // Project Cards
  //             _isLoading
  //                 ? const Center(child: CircularProgressIndicator())
  //                 : _projectsCount > 0
  //                     // If there are projects populate ListView
  //                     ? ListView.separated(
  //                         physics: NeverScrollableScrollPhysics(),
  //                         shrinkWrap: true,
  //                         padding: const EdgeInsets.only(
  //                           left: 15,
  //                           right: 15,
  //                           top: 5,
  //                           bottom: 25,
  //                         ),
  //                         itemCount: _projectsCount,
  //                         itemBuilder: (BuildContext context, int index) {
  //                           // Get the team name for this project
  //
  //                           return buildProjectCard(
  //                             context: context,
  //                             bannerImage:
  //                                 _bannerImages[index % _bannerImages.length],
  //                             project: _projectList[index],
  //                             teamName: 'Team: $_teamName',
  //                             index: index,
  //                           );
  //                         },
  //                         separatorBuilder: (BuildContext context, int index) =>
  //                             const SizedBox(height: 50),
  //                       )
  //                     // Else if there are no projects
  //                     : RefreshIndicator(
  //                         onRefresh: () async {
  //                           await _populateProjects();
  //                         },
  //                         child: SingleChildScrollView(
  //                           physics: AlwaysScrollableScrollPhysics(),
  //                           child: SizedBox(
  //                             height: MediaQuery.sizeOf(context).height * 2 / 3,
  //                             child: Center(
  //                               child: Text('You have no projects! Join a team '
  //                                   'or create a project first.'),
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //             SizedBox(height: 100),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _navBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(right: 24, left: 24, bottom: 24),
      decoration: BoxDecoration(
        color: p2bpBlue,
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
                    color: isSelected ? p2bpBlue : const Color(0xFFFFCC00),
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
