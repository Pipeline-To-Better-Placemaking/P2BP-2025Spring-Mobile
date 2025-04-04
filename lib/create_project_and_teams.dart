import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p2bp_2025spring_mobile/project_map_creation.dart';
import 'package:p2bp_2025spring_mobile/teams_and_invites_page.dart';
import 'firestore_functions.dart';
import 'home_screen.dart';
import 'widgets.dart';
import 'theme.dart';
import 'db_schema_classes.dart';

// For page selection switch. 0 = project, 1 = team.
enum PageView { project, team }

class CreateProjectAndTeamsPage extends StatefulWidget {
  const CreateProjectAndTeamsPage({super.key});

  @override
  State<CreateProjectAndTeamsPage> createState() =>
      _CreateProjectAndTeamsPageState();
}

class _CreateProjectAndTeamsPageState extends State<CreateProjectAndTeamsPage> {
  PageView page = PageView.project;
  PageView pageSelection = PageView.project;
  final pages = [
    const CreateProjectWidget(),
    const CreateTeamWidget(),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: <Widget>[
            // Switch at top to switch between create project and team pages.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: CustomSegmentedTab(
                selectedTab: pageSelection == PageView.project
                    ? CustomTab.project
                    : CustomTab.team,
                onTabSelected: (CustomTab tab) {
                  setState(() {
                    // Convert CustomTab back to PageView enum
                    pageSelection = tab == CustomTab.project
                        ? PageView.project
                        : PageView.team;
                  });
                },
              ),
            ),

            // Spacing between button and container w/ pages.
            SizedBox(height: 10),

            // Changes page between two widgets: The CreateProjectWidget and
            // CreateTeamWidget. These widgets display their respective
            // screens to create either a project or team.
            pages[pageSelection.index],

            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class CreateProjectWidget extends StatefulWidget {
  const CreateProjectWidget({
    super.key,
  });

  @override
  State<CreateProjectWidget> createState() => _CreateProjectWidgetState();
}

class _CreateProjectWidgetState extends State<CreateProjectWidget> {
  // TODO: add cover photo?
  String projectDescription = '';
  String projectTitle = '';
  String projectAddress = '';
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: directionsTransparency,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
            child: Column(
              spacing: 5,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Cover Photo',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: p2bpBlue,
                    ),
                  ),
                ),
                PhotoUpload(
                  width: 380,
                  height: 130,
                  icon: Icons.add_photo_alternate,
                  circular: false,
                  onTap: () {
                    // TODO: Actual function (Photo Upload)
                    print('Test');
                    return;
                  },
                ),
                const SizedBox(height: 10.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Project Name',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: p2bpBlue,
                    ),
                  ),
                ),
                CreationTextBox(
                  maxLength: 60,
                  labelText: 'Project Name',
                  maxLines: 1,
                  minLines: 1,
                  // Error message field includes validation (3 characters min)
                  errorMessage:
                      'Project names must be at least 3 characters long.',
                  onChanged: (titleText) {
                    setState(() {
                      projectTitle = titleText;
                    });
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Project Description',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: p2bpBlue,
                    ),
                  ),
                ),
                CreationTextBox(
                  maxLength: 240,
                  labelText: 'Project Description',
                  maxLines: 3,
                  minLines: 3,
                  // Error message field includes validation (3 characters min)
                  errorMessage:
                      'Project descriptions must be at least 3 characters long.',
                  onChanged: (descriptionText) {
                    setState(() {
                      projectDescription = descriptionText;
                    });
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    spacing: 5,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Project Address',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: p2bpBlue,
                        ),
                      ),
                      Tooltip(
                        triggerMode: TooltipTriggerMode.tap,
                        enableTapToDismiss: true,
                        showDuration: Duration(seconds: 3),
                        preferBelow: false,
                        message:
                            'Enter a central address for the designated project location. \nIf no such address exists, give an approximate location.',
                        child: Icon(Icons.help, size: 18, color: p2bpBlue),
                      ),
                    ],
                  ),
                ),
                CreationTextBox(
                  maxLength: 120,
                  labelText: 'Project Address',
                  maxLines: 2,
                  minLines: 2,
                  errorMessage:
                      'Project address must be at least 3 characters long.',
                  onChanged: (addressText) {
                    setState(() {
                      projectAddress = addressText;
                    });
                  },
                ),
                const SizedBox(height: 10.0),
                Align(
                  alignment: Alignment.bottomRight,
                  child: EditButton(
                    text: 'Next',
                    foregroundColor: Colors.white,
                    backgroundColor: p2bpBlue,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () async {
                      if (await getCurrentTeam() == null) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'You are not in a team! Join a team first.')),
                        );
                      } else if (_formKey.currentState!.validate()) {
                        Project partialProject = Project.partialProject(
                          title: projectTitle,
                          description: projectDescription,
                          address: projectAddress,
                        );
                        if (!context.mounted) return;
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProjectMapCreation(
                                    partialProjectData: partialProject)));
                      } // function
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreateTeamWidget extends StatefulWidget {
  const CreateTeamWidget({
    super.key,
  });

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
              member.fullName.toLowerCase().startsWith(text.toLowerCase()))
          .toList();

      _isLoading = false;
    });

    return membersList.isNotEmpty ? membersList : [];
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: directionsTransparency,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 25.0),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text(
                          'Team Photo',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: p2bpBlue,
                          ),
                        ),
                        SizedBox(height: 5),
                        PhotoUpload(
                          width: 75,
                          height: 75,
                          icon: Icons.add_photo_alternate,
                          circular: true,
                          onTap: () {
                            // TODO: Actual function (Photo Upload)
                            print('Test');
                            return;
                          },
                        ),
                      ],
                    ),
                    // Column(
                    //   children: <Widget>[
                    //     Text(
                    //       'Team Color',
                    //       textAlign: TextAlign.left,
                    //       style: TextStyle(
                    //         fontWeight: FontWeight.bold,
                    //         fontSize: 16.0,
                    //         color: p2bpBlue,
                    //       ),
                    //     ),
                    //     SizedBox(height: 5),
                    //     Column(
                    //       children: <Widget>[
                    //         Row(
                    //           children: <Widget>[
                    //             ColorSelectCircle(
                    //               gradient: defaultGrad,
                    //             ),
                    //             ColorSelectCircle(
                    //               gradient: defaultGrad,
                    //             ),
                    //             ColorSelectCircle(
                    //               gradient: defaultGrad,
                    //             ),
                    //           ],
                    //         ),
                    //         Row(
                    //           children: <Widget>[
                    //             ColorSelectCircle(
                    //               gradient: defaultGrad,
                    //             ),
                    //             ColorSelectCircle(
                    //               gradient: defaultGrad,
                    //             ),
                    //             ColorSelectCircle(
                    //               gradient: defaultGrad,
                    //             ),
                    //           ],
                    //         ),
                    //       ],
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Team Name',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: p2bpBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 5.0),
                CreationTextBox(
                  maxLength: 60,
                  labelText: 'Team Name',
                  maxLines: 1,
                  minLines: 1,
                  // Error message field includes validation (3 characters min)
                  errorMessage:
                      'Team names must be at least 3 characters long.',
                  onChanged: (teamText) {
                    teamName = teamText;
                  },
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
                      color: p2bpBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 5.0),
                CreationTextBox(
                  maxLength: 60,
                  labelText: 'Members',
                  maxLines: 1,
                  minLines: 1,
                  icon: const Icon(Icons.search),
                  onChanged: (memberText) {
                    setState(() {
                      if (memberText.length > 2) {
                        membersSearch = searchMembers(_membersList, memberText);
                        itemCount = membersSearch.length;
                      } else {
                        itemCount = 0;
                      }
                    });
                  },
                ),
                const SizedBox(height: 10.0),
                SizedBox(
                  height: 250,
                  child: itemCount > 0
                      ? ListView.separated(
                          shrinkWrap: true,
                          itemCount: itemCount,
                          padding: const EdgeInsets.only(
                            left: 5,
                            right: 5,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            return buildInviteCard(
                                member: membersSearch[index], index: index);
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(
                            height: 10,
                          ),
                        )
                      : _isLoading == true
                          ? const Center(child: CircularProgressIndicator())
                          : const Center(
                              child: Text(
                                  'No users matching criteria. Enter at least 3 characters to search.'),
                            ),
                ),
                const SizedBox(height: 10.0),
                Align(
                  alignment: Alignment.bottomRight,
                  child: EditButton(
                    text: 'Create',
                    foregroundColor: Colors.white,
                    backgroundColor: p2bpBlue,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saving data...')),
                        );
                        await saveTeam(
                            membersList: invitedMembers, teamName: teamName);
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamsAndInvitesPage(),
                          ),
                        );
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Card buildInviteCard({required Member member, required int index}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: <Widget>[
            CircleAvatar(),
            SizedBox(width: 15),
            Expanded(
              child: Text(member.fullName),
            ),
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

  InkWell memberInviteButton(
      {required int index, required String teamID, required Member member}) {
    return InkWell(
      child: Text(member.invited ? "Invite sent!" : "Invite"),
      onTap: () {
        setState(() {
          if (!member.invited) {
            member.invited = true;
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
