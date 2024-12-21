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

// TODO: Align labels, standardize colors. Create teams page.s
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
                  selectedIcon: const Icon(Icons.check_circle),
                  style: SegmentedButton.styleFrom(
                    backgroundColor: const Color(0xFF3664B3),
                    foregroundColor: Colors.white70,
                    selectedForegroundColor: Colors.white,
                    selectedBackgroundColor: const Color(0xFF2E5598),
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
                  decoration: const BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: <Widget>[
                        const Text(
                          'Cover Photo',
                          textAlign: TextAlign.left,
                        ),
                        // TODO: Extract to themes? move themes back to respective files
                        InkWell(
                          child: Container(
                            width: 380,
                            height: 125,
                            decoration: BoxDecoration(
                              color: const Color(0x2A000000),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              border:
                                  Border.all(color: const Color(0xFF6A89B8)),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate,
                              size: 50,
                            ),
                          ),
                          onTap: () {
                            // Function
                          },
                        ),
                        const Text(
                          'Project Name',
                          textAlign: TextAlign.left,
                        ),
                        const CreationTextBox(
                            maxLength: 60,
                            labelText: 'Project Name',
                            maxLines: 1,
                            minLines: 1),
                        const Text(
                          'Project Description',
                          textAlign: TextAlign.left,
                        ),
                        const CreationTextBox(
                            maxLength: 240,
                            labelText: 'Project Description',
                            maxLines: 3,
                            minLines: 3),
                        Align(
                          alignment: Alignment.centerRight,
                          child: EditButton(
                            text: 'Next',
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF4871AE),
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              // function
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Container(
              decoration: const BoxDecoration(),
              child: const Text('Placeholder 3')),
        ),
      ),
    );
  }
}
