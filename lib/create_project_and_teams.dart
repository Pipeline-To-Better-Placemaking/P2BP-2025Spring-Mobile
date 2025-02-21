import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:p2bp_2025spring_mobile/project_map_creation.dart';
import 'package:p2bp_2025spring_mobile/teams_and_invites_page.dart';
import 'firestore_functions.dart';
import 'home_screen.dart';
import 'widgets.dart';
import 'theme.dart';
import 'package:p2bp_2025spring_mobile/db_schema_classes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:p2bp_2025spring_mobile/newscreen.dart';
import 'search_location_screen.dart';
import 'dart:io';

class CreateProjectAndTeamsPage extends StatefulWidget {
  const CreateProjectAndTeamsPage({super.key});

  @override
  State<CreateProjectAndTeamsPage> createState() =>
      _CreateProjectAndTeamsPageState();
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
User? loggedInUser = FirebaseAuth.instance.currentUser;

class _CreateProjectAndTeamsPageState extends State<CreateProjectAndTeamsPage> {
  // Track the currently selected tab
  CustomTab currentTab = CustomTab.projects;

  @override
  Widget build(BuildContext context) {
    // Pages to show based on which tab is selected
    final List<Widget> pages = [
      CreateProjectWidget(),
      CreateTeamWidget(),
    ];
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: <Widget>[
                // Segmented tab to swap between teams/projects view
                CustomSegmentedTab(
                  selectedTab: currentTab,
                  onTabSelected: (CustomTab newTab) {
                    setState(() {
                      currentTab = newTab;
                    });
                  },
                ),

                const SizedBox(height: 10),

                // Show the appropriate page based on the currentTab
                pages[currentTab.index],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreateProjectWidget extends StatelessWidget {
  CreateProjectWidget({super.key});

  String projectDescription = '';
  String projectTitle = '';
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Stack(children: [
        // Gray-blue background
        Container(
          decoration: BoxDecoration(color: Color(0xFFDDE6F2)),
        ),

        // Content
        SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: 10),
            child: Column(
              children: [
                Container(
                  // width: 400,
                  // height: 500,
                  margin: EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Color(0xFFDDE6F2),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 40),
                    child: Column(
                      children: <Widget>[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Cover Photo',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: Color(0xFF2F6DCF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        PhotoUpload(
                          width: 380,
                          height: 125,
                          backgroundColor: Colors.grey,
                          icon: Icons.add_photo_alternate,
                          circular: false,
                          onTap: () async {
                            print('Test');
                            final XFile? pickedFile = await ImagePicker()
                                .pickImage(source: ImageSource.gallery);
                            if (pickedFile != null) {
                              final File imageFile = File(pickedFile.path);
                              // Now you have the image file, and you can submit or process it.
                              print("Image selected: ${imageFile.path}");
                            } else {
                              print("No image selected.");
                            }
                          },
                        ),
                        const SizedBox(height: 15.0),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Project Name',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: Color(0xFF2F6DCF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const CreationTextBox(
                          maxLength: 60,
                          labelText: 'Project Name',
                          maxLines: 1,
                          minLines: 1,
                        ),
                        const SizedBox(height: 10.0),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Project Description',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: Color(0xFF2F6DCF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const CreationTextBox(
                          maxLength: 240,
                          labelText: 'Project Description',
                          maxLines: 3,
                          minLines: 3,
                        ),
                        const SizedBox(height: 10.0),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: EditButton(
                            text: 'Next',
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF2F6DCF),
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () async {
                              if (await getCurrentTeam() == null) {
                                // TODO: Display error for creating project before team
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'You are not in a team! Join a team first.')),
                                );
                              } else if (_formKey.currentState!.validate()) {
                                Project partialProject = Project.partialProject(
                                    title: projectTitle,
                                    description: projectDescription);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ProjectMapCreation(
                                                partialProjectData:
                                                    partialProject)));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      ]),
    );
  }
}

class CreateTeamWidget extends StatefulWidget {
  const CreateTeamWidget({super.key});

  @override
  State<CreateTeamWidget> createState() => _CreateTeamWidgetState();
}

class _CreateTeamWidgetState extends State<CreateTeamWidget> {
  List<Member> _membersList = [];

  List<Member> membersSearch = [];

  List<Member> invitedMembers = [];

  bool _isLoading = false;

  String teamName = '';

  int itemCount = 0;

  final _formKey = GlobalKey<FormState>();

  String teamID = '';

  @override
  initState() {
    super.initState();
    _getMembersList();
  }

  // Retrieves membersList and puts it in variable
  Future<void> _getMembersList() async {
    try {
      _membersList = await getMembersList();
    } catch (e, stacktrace) {
      print("Error in create_project_and_teams, _getMembersList(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  // Searches member list for given String
  List<Member> searchMembers(List<Member> membersList, String text) {
    setState(() {
      _isLoading = true;

      membersList = membersList
          .where((member) =>
              member.getFullName().toLowerCase().startsWith(text.toLowerCase()))
          .toList();

      _isLoading = false;
    });

    return membersList.isNotEmpty ? membersList : [];
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(color: Color(0xFFDDE6F2)),
          ),

          // Content
          SafeArea(
            child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE6F2),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 40,
                        ),
                        child: Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // First column: Team Photo
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Team Photo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                        color: Color(0xFF2F6DCF),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    PhotoUpload(
                                      width: 75,
                                      height: 75,
                                      backgroundColor: Colors.grey,
                                      icon: Icons.add_photo_alternate,
                                      circular: true,
                                      onTap: () {
                                        print('Team photo tapped');
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(width: 60),
                                // Second column: Team Color
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Team Color',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                        color: Color(0xFF2F6DCF),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        ColorSelectCircle(
                                            gradient: defaultGrad),
                                        ColorSelectCircle(
                                            gradient: defaultGrad),
                                        ColorSelectCircle(
                                            gradient: defaultGrad),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        ColorSelectCircle(
                                            gradient: defaultGrad),
                                        ColorSelectCircle(
                                            gradient: defaultGrad),
                                        ColorSelectCircle(
                                            gradient: defaultGrad),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Team Name',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                  color: Color(0xFF2F6DCF),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            const CreationTextBox(
                              maxLength: 60,
                              labelText: 'Team Name',
                              maxLines: 1,
                              minLines: 1,
                            ),
                            const SizedBox(height: 10.0),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Members',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                  color: Color(0xFF2F6DCF),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            CreationTextBox(
                              maxLength: 60,
                              labelText: 'Members',
                              maxLines: 1,
                              minLines: 1,
                              icon: const Icon(
                                Icons.search,
                                color: Color(0xFF757575),
                              ),
                              onChanged: (text) {
                                print('Members text field: $text');
                              },
                            ),
                            const SizedBox(height: 10.0),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: EditButton(
                                text: 'Create',
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFF2F6DCF),
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    // TODO: If the form is valid, display a snackbar, await database
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Processing Data')),
                                    );
                                    await saveTeam(
                                        membersList: invitedMembers,
                                        teamName: teamName);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const HomeScreen(),
                                      ),
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TeamsAndInvitesPage(),
                                      ),
                                    );
                                  }
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                )),
          )
        ],
      ),
    );
  }
}

class ColorSelectCircle extends StatelessWidget {
  final Gradient gradient;

  const ColorSelectCircle({
    super.key,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
        ),
        width: 30,
        height: 30,
      ),
    );
  }
}
// Old Project Creation Code
// // For page selection switch. 0 = project, 1 = team.
// enum PageView { project, team }

// class CreateProjectAndTeamsPage extends StatefulWidget {
//   const CreateProjectAndTeamsPage({super.key});

//   @override
//   State<CreateProjectAndTeamsPage> createState() =>
//       _CreateProjectAndTeamsPageState();
// }

// // TODO: Align labels, standardize colors. Create teams page.
// class _CreateProjectAndTeamsPageState extends State<CreateProjectAndTeamsPage> {
//   PageView page = PageView.project;
//   PageView pageSelection = PageView.project;
//   final pages = [
//     const CreateProjectWidget(),
//     const CreateTeamWidget(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         // Top switch between Projects/Teams
//         // Creation screens
//         body: SingleChildScrollView(
//           child: Center(
//             child: Column(
//               children: <Widget>[
//                 // Switch at top to switch between create project and team pages.
//                 SegmentedButton(
//                   selectedIcon: const Icon(Icons.check_circle),
//                   style: SegmentedButton.styleFrom(
//                     backgroundColor: const Color(0xFF3664B3),
//                     foregroundColor: Colors.white70,
//                     selectedForegroundColor: Colors.white,
//                     selectedBackgroundColor: const Color(0xFF2E5598),
//                     side: const BorderSide(
//                       width: 0,
//                       color: Color(0xFF2F6DCF),
//                     ),
//                     elevation: 100,
//                     visualDensity:
//                         const VisualDensity(vertical: 1, horizontal: 1),
//                   ),
//                   segments: const <ButtonSegment>[
//                     ButtonSegment(
//                         value: PageView.project,
//                         label: Text('Project'),
//                         icon: Icon(Icons.developer_board)),
//                     ButtonSegment(
//                         value: PageView.team,
//                         label: Text('Team'),
//                         icon: Icon(Icons.people)),
//                   ],
//                   selected: {pageSelection},
//                   onSelectionChanged: (Set newSelection) {
//                     setState(() {
//                       // By default there is only a single segment that can be
//                       // selected at one time, so its value is always the first
//                       // item in the selected set.
//                       pageSelection = newSelection.first;
//                     });
//                   },
//                 ),

//                 // Spacing between button and container w/ pages.
//                 const SizedBox(height: 100),

//                 // Changes page between two widgets: The CreateProjectWidget and CreateTeamWidget.
//                 // These widgets display their respective screens to create either a project or team.
//                 pages[pageSelection.index],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class CreateProjectWidget extends StatelessWidget {
//   const CreateProjectWidget({
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 400,
//       height: 500,
//       decoration: const BoxDecoration(
//         color: Colors.white30,
//         borderRadius: BorderRadius.all(Radius.circular(10)),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10),
//         child: Column(
//           children: <Widget>[
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 'Cover Photo',
//                 textAlign: TextAlign.left,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16.0,
//                   color: Color(0xFF1A3C70),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 5),
//             PhotoUpload(
//               width: 380,
//               height: 125,
//               backgroundColor: Colors.grey,
//               icon: Icons.add_photo_alternate,
//               circular: false,
//               onTap: () {
//                 // TODO: Actual function
//                 print('Test');
//                 return;
//               },
//             ),
//             const SizedBox(height: 15.0),
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 'Project Name',
//                 textAlign: TextAlign.left,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16.0,
//                   color: Colors.blue[900],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 5),
//             const CreationTextBox(
//               maxLength: 60,
//               labelText: 'Project Name',
//               maxLines: 1,
//               minLines: 1,
//             ),
//             const SizedBox(height: 10.0),
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 'Project Description',
//                 textAlign: TextAlign.left,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16.0,
//                   color: Colors.blue[900],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 5),
//             const CreationTextBox(
//               maxLength: 240,
//               labelText: 'Project Description',
//               maxLines: 3,
//               minLines: 3,
//             ),
//             const SizedBox(height: 10.0),
//             Align(
//               alignment: Alignment.bottomRight,
//               child: EditButton(
//                 text: 'Next',
//                 foregroundColor: Colors.white,
//                 backgroundColor: const Color(0xFF2F6DCF),
//                 icon: const Icon(Icons.chevron_right),
//                 onPressed: () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => SearchScreen()));
//                   // function
//                 },
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CreateTeamWidget extends StatelessWidget {
//   const CreateTeamWidget({
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 400,
//       height: 500,
//       decoration: const BoxDecoration(
//         color: Colors.white30,
//         borderRadius: BorderRadius.all(Radius.circular(10)),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10),
//         child: Column(
//           children: <Widget>[
//             Row(
//               children: <Widget>[
//                 Padding(
//                   padding: const EdgeInsets.only(left: 75.0, bottom: 5),
//                   child: Text(
//                     'Team Photo',
//                     textAlign: TextAlign.left,
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16.0,
//                       color: Colors.blue[900],
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(left: 75.0, bottom: 5),
//                   child: Text(
//                     'Team Color',
//                     textAlign: TextAlign.left,
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16.0,
//                       color: Colors.blue[900],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             Padding(
//               padding: const EdgeInsets.only(bottom: 15.0),
//               child: Row(
//                 children: <Widget>[
//                   Padding(
//                     padding: const EdgeInsets.only(left: 75.0),
//                     child: PhotoUpload(
//                       width: 75,
//                       height: 75,
//                       backgroundColor: Colors.grey,
//                       icon: Icons.add_photo_alternate,
//                       circular: true,
//                       onTap: () {
//                         // TODO: Actual function
//                         print('Test');
//                         return;
//                       },
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(left: 75.0),
//                     child: Column(
//                       children: <Widget>[
//                         Row(
//                           children: <Widget>[
//                             ColorSelectCircle(
//                               gradient: defaultGrad,
//                             ),
//                             ColorSelectCircle(
//                               gradient: defaultGrad,
//                             ),
//                             ColorSelectCircle(
//                               gradient: defaultGrad,
//                             ),
//                           ],
//                         ),
//                         Row(
//                           children: <Widget>[
//                             ColorSelectCircle(
//                               gradient: defaultGrad,
//                             ),
//                             ColorSelectCircle(
//                               gradient: defaultGrad,
//                             ),
//                             ColorSelectCircle(
//                               gradient: defaultGrad,
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 'Team Name',
//                 textAlign: TextAlign.left,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16.0,
//                   color: Colors.blue[900],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 5.0),
//             const CreationTextBox(
//               maxLength: 60,
//               labelText: 'Team Name',
//               maxLines: 1,
//               minLines: 1,
//             ),
//             const SizedBox(height: 10.0),
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 'Members',
//                 textAlign: TextAlign.left,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16.0,
//                   color: Colors.blue[900],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 5.0),
//             CreationTextBox(
//               maxLength: 60,
//               labelText: 'Members',
//               maxLines: 1,
//               minLines: 1,
//               icon: const Icon(Icons.search),
//               onChanged: (text) {
//                 print('Members text field: $text');
//               },
//             ),
//             const SizedBox(height: 10.0),
//             Align(
//               alignment: Alignment.bottomRight,
//               child: EditButton(
//                 text: 'Create',
//                 foregroundColor: Colors.white,
//                 backgroundColor: const Color(0xFF4871AE),
//                 icon: const Icon(Icons.chevron_right),
//                 onPressed: () {
//                   // function
//                 },
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ColorSelectCircle extends StatelessWidget {
//   final Gradient gradient;

//   const ColorSelectCircle({
//     super.key,
//     required this.gradient,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(5.0),
//       child: Container(
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           gradient: gradient,
//         ),
//         width: 30,
//         height: 30,
//       ),
//     );
//   }
// }
