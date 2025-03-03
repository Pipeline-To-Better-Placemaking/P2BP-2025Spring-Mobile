import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:p2bp_2025spring_mobile/people_in_place_test.dart';
import 'package:p2bp_2025spring_mobile/project_map_creation.dart';
import 'package:p2bp_2025spring_mobile/project_map_creation_v2.dart';
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
  // Using the new custom tab design from the front-end merge.
  CustomTab currentTab = CustomTab.projects;

  @override
  Widget build(BuildContext context) {
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
                // Custom segmented tab to switch views.
                CustomSegmentedTab(
                  selectedTab: currentTab,
                  onTabSelected: (CustomTab newTab) {
                    setState(() {
                      currentTab = newTab;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Display the current page.
                pages[currentTab.index],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreateProjectWidget extends StatefulWidget {
  CreateProjectWidget({super.key});

  @override
  _CreateProjectWidgetState createState() => _CreateProjectWidgetState();
}

class _CreateProjectWidgetState extends State<CreateProjectWidget> {
  String projectDescription = '';
  String projectTitle = '';
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Stack(
        children: [
          // Background color
          Container(
            decoration: BoxDecoration(color: const Color(0xFFDDE6F2)),
          ),
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE6F2),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 40),
                      child: Column(
                        children: <Widget>[
                          // Cover photo section with new image picker functionality.
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Cover Photo',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: const Color(0xFF2F6DCF),
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
                                print("Image selected: ${imageFile.path}");
                              } else {
                                print("No image selected.");
                              }
                            },
                          ),
                          const SizedBox(height: 15.0),
                          // Project Name field with state update.
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Project Name',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: const Color(0xFF2F6DCF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          CreationTextBox(
                            maxLength: 60,
                            labelText: 'Project Name',
                            maxLines: 1,
                            minLines: 1,
                            errorMessage:
                                'Project names must be at least 3 characters long.',
                            onChanged: (titleText) {
                              setState(() {
                                projectTitle = titleText;
                              });
                            },
                          ),
                          const SizedBox(height: 10.0),
                          // Project Description field with state update.
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Project Description',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: const Color(0xFF2F6DCF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          CreationTextBox(
                            maxLength: 240,
                            labelText: 'Project Description',
                            maxLines: 3,
                            minLines: 3,
                            errorMessage:
                                'Project descriptions must be at least 3 characters long.',
                            onChanged: (descriptionText) {
                              setState(() {
                                projectDescription = descriptionText;
                              });
                            },
                          ),
                          const SizedBox(height: 10.0),
                          // Next button that validates and navigates.
                          Align(
                            alignment: Alignment.bottomRight,
                            child: EditButton(
                              text: 'Next',
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF2F6DCF),
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () async {
                                if (await getCurrentTeam() == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'You are not in a team! Join a team first.')),
                                  );
                                } else if (_formKey.currentState!.validate()) {
                                  Project partialProject =
                                      Project.partialProject(
                                          title: projectTitle,
                                          description: projectDescription);
                                  print(
                                      'project title: ${partialProject.title}');
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ProjectMapCreationV2(
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
        ],
      ),
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
  void initState() {
    super.initState();
    _getMembersList();
  }

  // Retrieve the list of members from the backend.
  Future<void> _getMembersList() async {
    try {
      _membersList = await getMembersList();
    } catch (e, stacktrace) {
      print(
          "Error in create_project_and_teams, _getMembersList(): $e\nStacktrace: $stacktrace");
    }
  }

  // Search for members whose full names start with the search text.
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE6F2),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 40),
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Team Photo column
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Team Photo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                      color: const Color(0xFF2F6DCF),
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
                              const SizedBox(width: 60),
                              // Team Color column
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Team Color',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                      color: const Color(0xFF2F6DCF),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ColorSelectCircle(gradient: defaultGrad),
                                      ColorSelectCircle(gradient: defaultGrad),
                                      ColorSelectCircle(gradient: defaultGrad),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      ColorSelectCircle(gradient: defaultGrad),
                                      ColorSelectCircle(gradient: defaultGrad),
                                      ColorSelectCircle(gradient: defaultGrad),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Team Name field with state update.
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Team Name',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: const Color(0xFF2F6DCF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5.0),
                          CreationTextBox(
                            maxLength: 60,
                            labelText: 'Team Name',
                            maxLines: 1,
                            minLines: 1,
                            // Error mesasge field includes validation (3 characters min)
                            errorMessage:
                                'Team names must be at least 3 characters long.',
                            onChanged: (teamText) {
                              setState(() {
                                teamName = teamText;
                              });
                            },
                          ),
                          const SizedBox(height: 10.0),
                          // Members search field with live search.
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Members',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: const Color(0xFF2F6DCF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5.0),
                          CreationTextBox(
                            maxLength: 60,
                            labelText: 'Members',
                            maxLines: 1,
                            minLines: 1,
                            icon: const Icon(Icons.search,
                                color: Color(0xFF757575)),
                            onChanged: (memberText) {
                              setState(() {
                                if (memberText.length > 2) {
                                  membersSearch =
                                      searchMembers(_membersList, memberText);
                                  itemCount = membersSearch.length;
                                } else {
                                  itemCount = 0;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 10.0),
                          // Display search results (invite cards) if any.
                          SizedBox(
                            height: 250,
                            child: itemCount > 0
                                ? ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: itemCount,
                                    padding: const EdgeInsets.only(
                                        left: 5, right: 5),
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return buildInviteCard(
                                          member: membersSearch[index],
                                          index: index);
                                    },
                                    separatorBuilder:
                                        (BuildContext context, int index) =>
                                            const SizedBox(
                                      height: 10,
                                    ),
                                  )
                                : _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : const Center(
                                        child: Text(
                                            'No users matching criteria. Enter at least 3 characters to search.'),
                                      ),
                          ),
                          const SizedBox(height: 10.0),
                          // Create button to save team and navigate.
                          Align(
                            alignment: Alignment.bottomRight,
                            child: EditButton(
                              text: 'Create',
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF2F6DCF),
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Processing Data')));
                                  await saveTeam(
                                      membersList: invitedMembers,
                                      teamName: teamName);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const HomeScreen()),
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            TeamsAndInvitesPage()),
                                  );
                                }
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // Widget to build a card for each member in search results.
  Card buildInviteCard({required Member member, required int index}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: <Widget>[
            const CircleAvatar(),
            const SizedBox(width: 15),
            Expanded(child: Text(member.getFullName())),
            Align(
              alignment: Alignment.centerRight,
              child: memberInviteButton(
                  teamID: teamID, index: index, member: member),
            ),
          ],
        ),
      ),
    );
  }

  // Button widget for inviting a member.
  InkWell memberInviteButton(
      {required int index, required String teamID, required Member member}) {
    return InkWell(
      child: Text(member.getInvited() == true ? "Invite sent!" : "Invite"),
      onTap: () {
        setState(() {
          if (member.getInvited() == false) {
            member.setInvited(true);
            invitedMembers.add(member);
          }
        });
      },
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


// Broken Code 
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:p2bp_2025spring_mobile/project_map_creation.dart';
// import 'package:p2bp_2025spring_mobile/teams_and_invites_page.dart';
// import 'firestore_functions.dart';
// import 'home_screen.dart';
// import 'widgets.dart';
// import 'theme.dart';
// import 'package:p2bp_2025spring_mobile/db_schema_classes.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:p2bp_2025spring_mobile/newscreen.dart';
// import 'search_location_screen.dart';
// import 'dart:io';

// class CreateProjectAndTeamsPage extends StatefulWidget {
//   const CreateProjectAndTeamsPage({super.key});

//   @override
//   State<CreateProjectAndTeamsPage> createState() =>
//       _CreateProjectAndTeamsPageState();
// }

// final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// User? loggedInUser = FirebaseAuth.instance.currentUser;

// class _CreateProjectAndTeamsPageState extends State<CreateProjectAndTeamsPage> {
//   // Track the currently selected tab
//   CustomTab currentTab = CustomTab.projects;

//   @override
//   Widget build(BuildContext context) {
//     // Pages to show based on which tab is selected
//     final List<Widget> pages = [
//       CreateProjectWidget(),
//       CreateTeamWidget(),
//     ];
//     return SafeArea(
//       child: Scaffold(
//         body: SingleChildScrollView(
//           child: Center(
//             child: Column(
//               children: <Widget>[
//                 // Replace the old SegmentedButton with your custom MySegmentedTab:
//                 CustomSegmentedTab(
//                   selectedTab: currentTab,
//                   onTabSelected: (CustomTab newTab) {
//                     setState(() {
//                       currentTab = newTab;
//                     });
//                   },
//                 ),

//                 const SizedBox(height: 10),

//                 // Show the appropriate page based on the currentTab
//                 pages[currentTab.index],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class CreateProjectWidget extends StatelessWidget {
//   CreateProjectWidget({super.key});

//   String projectDescription = '';
//   String projectTitle = '';
//   final _formKey = GlobalKey<FormState>();

//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: _formKey,
//       child: Stack(children: [
//         // Gray-blue background
//         Container(
//           decoration: BoxDecoration(color: Color(0xFFDDE6F2)),
//         ),

//         // Content
//         SafeArea(
//           child: Padding(
//             padding: EdgeInsets.only(top: 10),
//             child: Column(
//               children: [
//                 Container(
//                   // width: 400,
//                   // height: 500,
//                   margin: EdgeInsets.symmetric(horizontal: 16.0),
//                   decoration: BoxDecoration(
//                     color: Color(0xFFDDE6F2),
//                     borderRadius: BorderRadius.all(Radius.circular(10)),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha: 0.1),
//                         blurRadius: 6,
//                         offset: Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 40),
//                     child: Column(
//                       children: <Widget>[
//                         Align(
//                           alignment: Alignment.centerLeft,
//                           child: Text(
//                             'Cover Photo',
//                             textAlign: TextAlign.left,
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16.0,
//                               color: Color(0xFF2F6DCF),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 5),
//                         PhotoUpload(
//                           width: 380,
//                           height: 125,
//                           backgroundColor: Colors.grey,
//                           icon: Icons.add_photo_alternate,
//                           circular: false,
//                           onTap: () async {
//                             print('Test');
//                             final XFile? pickedFile = await ImagePicker()
//                                 .pickImage(source: ImageSource.gallery);
//                             if (pickedFile != null) {
//                               final File imageFile = File(pickedFile.path);
//                               // Now you have the image file, and you can submit or process it.
//                               print("Image selected: ${imageFile.path}");
//                             } else {
//                               print("No image selected.");
//                             }
//                           },
//                         ),
//                         const SizedBox(height: 15.0),
//                         Align(
//                           alignment: Alignment.centerLeft,
//                           child: Text(
//                             'Project Name',
//                             textAlign: TextAlign.left,
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16.0,
//                               color: Color(0xFF2F6DCF),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 5),
//                         const CreationTextBox(
//                           maxLength: 60,
//                           labelText: 'Project Name',
//                           maxLines: 1,
//                           minLines: 1,
//                         ),
//                         const SizedBox(height: 10.0),
//                         Align(
//                           alignment: Alignment.centerLeft,
//                           child: Text(
//                             'Project Description',
//                             textAlign: TextAlign.left,
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16.0,
//                               color: Color(0xFF2F6DCF),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 5),
//                         const CreationTextBox(
//                           maxLength: 240,
//                           labelText: 'Project Description',
//                           maxLines: 3,
//                           minLines: 3,
//                         ),
//                         const SizedBox(height: 10.0),
//                         Align(
//                           alignment: Alignment.bottomRight,
//                           child: EditButton(
//                             text: 'Next',
//                             foregroundColor: Colors.white,
//                             backgroundColor: const Color(0xFF2F6DCF),
//                             icon: const Icon(Icons.chevron_right),
//                             onPressed: () async {
//                               if (await getCurrentTeam() == null) {
//                                 // TODO: Display error for creating project before team
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                       content: Text(
//                                           'You are not in a team! Join a team first.')),
//                                 );
//                               } else if (_formKey.currentState!.validate()) {
//                                 Project partialProject = Project.partialProject(
//                                     title: projectTitle,
//                                     description: projectDescription);
//                                 Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                         builder: (context) =>
//                                             ProjectMapCreation(
//                                                 partialProjectData:
//                                                     partialProject)));
//                               }
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         )
//       ]),
//     );
//   }
// }

// class CreateTeamWidget extends StatefulWidget {
//   const CreateTeamWidget({super.key});

//   @override
//   State<CreateTeamWidget> createState() => _CreateTeamWidgetState();
// }

// class _CreateTeamWidgetState extends State<CreateTeamWidget> {
//   List<Member> _membersList = [];

//   List<Member> membersSearch = [];

//   List<Member> invitedMembers = [];

//   bool _isLoading = false;

//   String teamName = '';

//   int itemCount = 0;

//   final _formKey = GlobalKey<FormState>();

//   String teamID = '';

//   @override
//   initState() {
//     super.initState();
//     _getMembersList();
//   }

//   // Retrieves membersList and puts it in variable
//   Future<void> _getMembersList() async {
//     try {
//       _membersList = await getMembersList();
//     } catch (e, stacktrace) {
//       print("Error in create_project_and_teams, _getMembersList(): $e");
//       print("Stacktrace: $stacktrace");
//     }
//   }

//   // Searches member list for given String
//   List<Member> searchMembers(List<Member> membersList, String text) {
//     setState(() {
//       _isLoading = true;

//       membersList = membersList
//           .where((member) =>
//               member.getFullName().toLowerCase().startsWith(text.toLowerCase()))
//           .toList();

//       _isLoading = false;
//     });

//     return membersList.isNotEmpty ? membersList : [];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: _formKey,
//       child: Stack(
//         children: [
//           Container(
//             decoration: const BoxDecoration(color: Color(0xFFDDE6F2)),
//           ),

//           // Content
//           SafeArea(
//             child: Padding(
//                 padding: const EdgeInsets.only(top: 10),
//                 child: Column(
//                   children: [
//                     Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 16.0),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFDDE6F2),
//                         borderRadius:
//                             const BorderRadius.all(Radius.circular(10)),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withValues(alpha: 0.1),
//                             blurRadius: 6,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 40,
//                         ),
//                         child: Column(
//                           children: <Widget>[
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 // First column: Team Photo
//                                 Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Text(
//                                       'Team Photo',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 16.0,
//                                         color: Color(0xFF2F6DCF),
//                                       ),
//                                     ),
//                                     const SizedBox(height: 8),
//                                     PhotoUpload(
//                                       width: 75,
//                                       height: 75,
//                                       backgroundColor: Colors.grey,
//                                       icon: Icons.add_photo_alternate,
//                                       circular: true,
//                                       onTap: () {
//                                         print('Team photo tapped');
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(width: 60),
//                                 // Second column: Team Color
//                                 Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Text(
//                                       'Team Color',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 16.0,
//                                         color: Color(0xFF2F6DCF),
//                                       ),
//                                     ),
//                                     const SizedBox(height: 8),
//                                     Row(
//                                       children: [
//                                         ColorSelectCircle(
//                                             gradient: defaultGrad),
//                                         ColorSelectCircle(
//                                             gradient: defaultGrad),
//                                         ColorSelectCircle(
//                                             gradient: defaultGrad),
//                                       ],
//                                     ),
//                                     Row(
//                                       children: [
//                                         ColorSelectCircle(
//                                             gradient: defaultGrad),
//                                         ColorSelectCircle(
//                                             gradient: defaultGrad),
//                                         ColorSelectCircle(
//                                             gradient: defaultGrad),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                             SizedBox(height: 20),
//                             Align(
//                               alignment: Alignment.centerLeft,
//                               child: Text(
//                                 'Team Name',
//                                 textAlign: TextAlign.left,
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16.0,
//                                   color: Color(0xFF2F6DCF),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 5.0),
//                             const CreationTextBox(
//                               maxLength: 60,
//                               labelText: 'Team Name',
//                               maxLines: 1,
//                               minLines: 1,
//                             ),
//                             const SizedBox(height: 10.0),
//                             Align(
//                               alignment: Alignment.centerLeft,
//                               child: Text(
//                                 'Members',
//                                 textAlign: TextAlign.left,
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16.0,
//                                   color: Color(0xFF2F6DCF),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 5.0),
//                             CreationTextBox(
//                               maxLength: 60,
//                               labelText: 'Members',
//                               maxLines: 1,
//                               minLines: 1,
//                               icon: const Icon(
//                                 Icons.search,
//                                 color: Color(0xFF757575),
//                               ),
//                               onChanged: (text) {
//                                 print('Members text field: $text');
//                               },
//                             ),
//                             const SizedBox(height: 10.0),
//                             Align(
//                               alignment: Alignment.bottomRight,
//                               child: EditButton(
//                                 text: 'Create',
//                                 foregroundColor: Colors.white,
//                                 backgroundColor: const Color(0xFF2F6DCF),
//                                 icon: const Icon(Icons.chevron_right),
//                                 onPressed: () async {
//                                   if (_formKey.currentState!.validate()) {
//                                     // TODO: If the form is valid, display a snackbar, await database
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       const SnackBar(
//                                           content: Text('Processing Data')),
//                                     );
//                                     await saveTeam(
//                                         membersList: invitedMembers,
//                                         teamName: teamName);
//                                     Navigator.pushReplacement(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) =>
//                                             const HomeScreen(),
//                                       ),
//                                     );
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) =>
//                                             TeamsAndInvitesPage(),
//                                       ),
//                                     );
//                                   }
//                                 },
//                               ),
//                             )
//                           ],
//                         ),
//                       ),
//                     )
//                   ],
//                 )),
//           )
//         ],
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

