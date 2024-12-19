import 'package:flutter/material.dart';
import 'theme.dart';

// For page selection switch. 0 = project, 1 = team.
enum PageView { project, team }

class CreateProjectAndTeamsPage extends StatefulWidget {
  const CreateProjectAndTeamsPage({super.key});

  @override
  State<CreateProjectAndTeamsPage> createState() =>
      _CreateProjectAndTeamsPageState();
}

class _CreateProjectAndTeamsPageState extends State<CreateProjectAndTeamsPage> {
  PageView pageSelection = PageView.project;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // Top switch between Projects/Teams
        appBar: AppBar(
          title: const Text('Placeholder'),
        ),
        // Creation screens
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: <Widget>[
                SegmentedButton(
                  selectedIcon: Icon(Icons.check_circle),
                  style: SegmentedButton.styleFrom(
                    backgroundColor: const Color(0xFF2180EA),
                    foregroundColor: Colors.white70,
                    selectedForegroundColor: Colors.white,
                    selectedBackgroundColor: const Color(0xFF1F78DC),
                    side: const BorderSide(
                      width: 0,
                      color: Color(0xFF2180EA),
                    ),
                    elevation: 100,
                    visualDensity:
                        const VisualDensity(vertical: 1, horizontal: 1),
                  ),
                  segments: const <ButtonSegment>[
                    ButtonSegment(
                        value: PageView.project,
                        label: Text('Project'),
                        icon: Icon(Icons.developer_board)),
                    ButtonSegment(
                        value: PageView.team,
                        label: Text('Team'),
                        icon: Icon(Icons.people)),
                  ],
                  selected: {pageSelection},
                  onSelectionChanged: (Set newSelection) {
                    setState(() {
                      // By default there is only a single segment that can be
                      // selected at one time, so its value is always the first
                      // item in the selected set.
                      pageSelection = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 100),
                Container(
                  width: 400,
                  height: 500,
                  decoration: const BoxDecoration(color: Colors.white70),
                  child: Column(
                    children: <Widget>[
                      const Text(
                        'Cover Photo',
                        textAlign: TextAlign.left,
                      ),
                      Container(
                        decoration: const BoxDecoration(color: Colors.white70),
                      ),
                      const Text(
                        'Project Name',
                        textAlign: TextAlign.left,
                      ),
                      const Text(
                        'Project Description',
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Container(height: 1000.0, child: Text('Placeholder 3')),
        ),
      ),
    );
  }
}
