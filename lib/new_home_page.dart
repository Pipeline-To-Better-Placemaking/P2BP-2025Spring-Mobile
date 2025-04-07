// import 'package:flutter/material.dart';
// import 'results_panel.dart';
// import 'settings_page.dart';
// import 'teams_and_invites_page.dart';
// import 'create_project_and_teams.dart';
// import 'home_screen.dart';
// import 'theme.dart';
//
// // Floating bottom navigation bar to be invoked with every page that has a navigation bar.
// class BottomFloatingNavBar extends StatefulWidget {
//   const BottomFloatingNavBar({
//     super.key,
//   });
//
//   @override
//   State<BottomFloatingNavBar> createState() => _BottomFloatingNavBarState();
// }
//
// class _BottomFloatingNavBarState extends State<BottomFloatingNavBar> {
//   int _selectedIndex = 0;
//
//   final List<Widget> pageWidgets = [
//     HomeScreen(),
//     TeamsAndInvitesPage(),
//     CreateProjectAndTeamsPage(),
//     ResultsPanel(),
//     SettingsPage(),
//   ];
//   final List<String> pages = [
//     '/home',
//     '/teams_and_invites',
//     '/create_project_and_teams',
//     '/results',
//     '/settings',
//   ];
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: pageWidgets[_selectedIndex],
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.only(top: 0, bottom: 20, left: 10, right: 10),
//         child: Container(
//           decoration: const BoxDecoration(
//             color: Colors.transparent,
//             borderRadius: BorderRadius.all(
//               Radius.circular(50.0),
//             ),
//           ),
//           child: ClipRRect(
//             borderRadius: const BorderRadius.all(
//               Radius.circular(50.0),
//             ),
//             child: BottomNavigationBar(
//               // TODO: Fix colors
//               type: BottomNavigationBarType.fixed,
//               backgroundColor: Colors.blue,
//               selectedItemColor: Colors.yellow,
//               showSelectedLabels: false,
//               showUnselectedLabels: false,
//               items: [
//                 BottomNavigationBarItem(
//                   backgroundColor: p2bpBlue,
//                   icon: Icon(Icons.home),
//                   label: 'Home',
//                 ),
//                 BottomNavigationBarItem(
//                   backgroundColor: p2bpBlue,
//                   // TODO: which icon?
//                   icon: Icon(Icons.short_text),
//                   label: 'Projects',
//                 ),
//                 BottomNavigationBarItem(
//                   backgroundColor: p2bpBlue,
//                   icon: Icon(Icons.add_circle_outline),
//                   label: 'Add Project or Team',
//                 ),
//                 BottomNavigationBarItem(
//                   backgroundColor: p2bpBlue,
//                   icon: Icon(Icons.bar_chart),
//                   label: 'Results',
//                 ),
//                 BottomNavigationBarItem(
//                   backgroundColor: p2bpBlue,
//                   icon: Icon(Icons.person),
//                   label: 'Profile',
//                 ),
//               ],
//               currentIndex: _selectedIndex,
//               onTap: _onItemTapped,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
