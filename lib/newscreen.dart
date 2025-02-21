import 'package:flutter/material.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';

class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  CustomTab _currentTab = CustomTab.projects;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Basic app bar (without the pill as title)
      appBar: AppBar(
        title: Text('Testing Pill in Body'),
        backgroundColor: Colors.blue,
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 40), // extra vertical space from top

          // Place your pill widget here
          CustomSegmentedTab(
            selectedTab: _currentTab,
            onTabSelected: (newTab) {
              setState(() => _currentTab = newTab);
            },
          ),

          // The rest of your page...
          SizedBox(height: 20),
          Expanded(
            child: _buildBodyContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_currentTab) {
      case CustomTab.projects:
        return Center(child: Text('Projects Page'));
      case CustomTab.team:
        return Center(child: Text('Team Page'));
    }
  }
}
