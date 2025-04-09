import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:p2bp_2025spring_mobile/project_map_creation.dart';
import 'package:p2bp_2025spring_mobile/teams_and_invites_page.dart';

import 'db_schema_classes.dart';
import 'home_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class CreateProjectAndTeamsPage extends StatefulWidget {
  final Member member;

  const CreateProjectAndTeamsPage({super.key, required this.member});

  @override
  State<CreateProjectAndTeamsPage> createState() =>
      _CreateProjectAndTeamsPageState();
}

class _CreateProjectAndTeamsPageState extends State<CreateProjectAndTeamsPage> {
  late final List<Widget> pages;
  late Widget pageSelection;

  @override
  void initState() {
    super.initState();
    pages = [
      CreateProjectWidget(member: widget.member),
      CreateTeamWidget(member: widget.member),
    ];
    pageSelection = pages[0];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: <Widget>[
            // Switch at top to switch between create project and team pages.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SegmentedButton(
                selectedIcon: const Icon(Icons.check_circle),
                style: SegmentedButton.styleFrom(
                  iconColor: Colors.white,
                  backgroundColor: const Color(0xFF4871AE),
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
                segments: <ButtonSegment>[
                  ButtonSegment(
                    value: pages[0],
                    label: const Text('Project'),
                    icon: const Icon(Icons.developer_board),
                  ),
                  ButtonSegment(
                    value: pages[1],
                    label: const Text('Team'),
                    icon: const Icon(Icons.people),
                  ),
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
            ),
            const SizedBox(height: 10),

            // Changes page between two widgets: The CreateProjectWidget and
            // CreateTeamWidget. These widgets display their respective
            // screens to create either a project or team.
            pageSelection,

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class CreateProjectWidget extends StatefulWidget {
  final Member member;

  const CreateProjectWidget({
    super.key,
    required this.member,
  });

  @override
  State<CreateProjectWidget> createState() => _CreateProjectWidgetState();
}

class _CreateProjectWidgetState extends State<CreateProjectWidget> {
  // TODO: add cover photo?
  String projectDescription = '';
  String projectTitle = '';
  String projectAddress = '';
  File? _selectedCoverImage;
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
                _selectedCoverImage != null
                    ? Stack(
                        children: [
                          Container(
                            width: 380,
                            height: 130,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(_selectedCoverImage!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(Icons.edit, color: Colors.grey),
                                onPressed: _selectImage,
                                iconSize: 20,
                                padding: EdgeInsets.all(8),
                                constraints: BoxConstraints(),
                              ),
                            ),
                          )
                        ],
                      )
                    : PhotoUpload(
                        width: 380,
                        height: 130,
                        icon: Icons.add_photo_alternate,
                        circular: false,
                        onTap: _selectImage,
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
                    onPressed: () {
                      if (widget.member.selectedTeamRef == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'You are not in a team! Join a team first.')),
                        );
                      } else if (_formKey.currentState!.validate()) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjectMapCreation(
                              member: widget.member,
                              team: widget.member.selectedTeam!,
                              title: projectTitle,
                              description: projectDescription,
                              address: projectAddress,
                              coverImage: _selectedCoverImage,
                            ),
                          ),
                        );
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

  Future<void> _selectImage() async {
    try {
      final XFile? imageFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (imageFile != null) {
        setState(() {
          _selectedCoverImage = File(imageFile.path);
        });
        print("Image selected: ${imageFile.path}");
      } else {
        print("No image selected.");
      }
    } catch (e) {
      print("Error selecting image: $e");
    }
  }
}

class CreateTeamWidget extends StatefulWidget {
  final Member member;

  const CreateTeamWidget({
    super.key,
    required this.member,
  });

  @override
  State<CreateTeamWidget> createState() => _CreateTeamWidgetState();
}

class _CreateTeamWidgetState extends State<CreateTeamWidget> {
  List<Member> membersSearch = [];
  List<Member> invitedMembers = [];
  bool _isLoading = false;
  String teamTitle = '';
  int itemCount = 0;
  final _formKey = GlobalKey<FormState>();
  String teamID = '';

  @override
  initState() {
    super.initState();
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
                    teamTitle = teamText;
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
                  onChanged: (memberText) async {
                    if (memberText.length > 2) {
                      setState(() {
                        _isLoading = true;
                      });

                      membersSearch = await Member.queryByFullName(memberText);
                      itemCount = membersSearch.length;

                      setState(() {
                        _isLoading = false;
                      });
                    } else {
                      itemCount = 0;
                    }
                  },
                ),
                const SizedBox(height: 10.0),
                SizedBox(
                  height: 250,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : itemCount > 0
                          ? ListView.separated(
                              shrinkWrap: true,
                              itemCount: itemCount,
                              padding: const EdgeInsets.only(left: 5, right: 5),
                              itemBuilder: (context, index) {
                                final member = membersSearch[index];
                                final invited = invitedMembers.contains(member);
                                return MemberInviteCard(
                                  member: member,
                                  invited: invited,
                                  inviteCallback: () {
                                    if (!invited) {
                                      setState(() {
                                        invitedMembers.add(member);
                                      });
                                    }
                                  },
                                );
                              },
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const SizedBox(height: 10),
                            )
                          : const Center(
                              child: Text(
                                  'No users matching criteria. Enter at least '
                                  '3 characters to search.'),
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

                        await Team.createNew(
                          teamTitle: teamTitle,
                          teamOwner: widget.member,
                          inviteList: invitedMembers,
                        );

                        if (!context.mounted) return;
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HomeScreen(member: widget.member),
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TeamsAndInvitesPage(member: widget.member),
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
