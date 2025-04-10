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
    FocusManager.instance.primaryFocus?.unfocus();
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
