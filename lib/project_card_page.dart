import 'package:flutter/material.dart';
import 'package:p2bp_2025spring_mobile/pdf_report.dart';
import 'package:p2bp_2025spring_mobile/project_details_page.dart';
import 'package:p2bp_2025spring_mobile/teams_and_invites_page.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';

import 'db_schema_classes.dart';
import 'edit_project_form.dart';

const List<String> _bannerImages = [
  'assets/RedHouse.png',
  'assets/BeachfrontHouse.png',
  'assets/MansionSunset.png',
  'assets/MountainsideCabin.png',
  'assets/HouseInForest.png',
  'assets/HouseAtNight.png',
  'assets/MansionTropical.png',
  'assets/MansionGreenValley.png',
  'assets/MiamiHouse.png'
];

class ProjectCardPage extends StatefulWidget {
  final Member member;

  const ProjectCardPage({super.key, required this.member});

  @override
  State<ProjectCardPage> createState() => _ProjectCardPageState();
}

class _ProjectCardPageState extends State<ProjectCardPage> {
  Team? _currentTeam;
  List<Project> _projectList = [];
  int _projectsCount = 0;
  bool _isLoading = true;
  late final String _firstName;

  @override
  void initState() {
    super.initState();
    _firstName = widget.member.fullName.split(' ').first;
    _populateProjects();
  }

  Future<void> _populateProjects() async {
    try {
      _currentTeam = await widget.member.loadSelectedTeamInfo();
      if (_currentTeam == null) return;

      _projectList = await _currentTeam!.loadProjectsInfo();

      if (!mounted) return;
      setState(() {
        _projectsCount = _projectList.length;
        _isLoading = false;
      });
    } catch (e) {
      print("Error in _populateProjects(): $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _populateProjects();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // P2BP Logo centered at the top
              Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      'assets/P2BP_Logo.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Teams Button
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2F6DCF),
                              border: Border.all(
                                  color: Color(0xFF0A2A88), width: 3)),
                          child: Center(
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.groups),
                              color: p2bpYellow,
                              onPressed: () async {
                                // Navigate to Teams/Invites screen
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const TeamsAndInvitesPage(),
                                  ),
                                );
                                _populateProjects();
                              },
                              iconSize: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // "Hello, [user]" greeting, aligned to the left below the logo
                  Padding(
                    padding: const EdgeInsets.only(top: 40, left: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) {
                            return defaultGrad.createShader(bounds);
                          },
                          child: Text(
                            'Hello, \n$_firstName',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2, // Masked text with gradient
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // "Your Projects" label, aligned to the right of the screen"
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return defaultGrad.createShader(bounds);
                      },
                      child: const Text(
                        'Your Projects',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Project Cards
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _projectsCount > 0
                      // If there are projects populate ListView
                      ? ListView.separated(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(
                            left: 15,
                            right: 15,
                            top: 5,
                            bottom: 25,
                          ),
                          itemCount: _projectsCount,
                          itemBuilder: (BuildContext context, int index) {
                            // Get the team name for this project
                            return ProjectCard(
                              bannerImage:
                                  _bannerImages[index % _bannerImages.length],
                              project: _projectList[index],
                              editProjectCallback: (updated) {
                                if (updated == 'deleted') {
                                  _populateProjects();
                                } else if (updated == 'altered') {
                                  setState(() {
                                    // Update if something was changed in EditProject
                                  });
                                }
                              },
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(height: 50),
                        )
                      // Else if there are no projects
                      : RefreshIndicator(
                          onRefresh: () async {
                            await _populateProjects();
                          },
                          child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.sizeOf(context).height * 2 / 3,
                              child: Center(
                                child: Text('You have no projects! Join a team '
                                    'or create a project first.'),
                              ),
                            ),
                          ),
                        ),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // Widget buildProjectCard({
  //   required BuildContext context,
  //   required String bannerImage,
  //   required Project project,
  //   required String teamName,
  //   required int index,
  // }) {
  //   return Card(
  //     elevation: 5,
  //     shape: RoundedRectangleBorder(
  //         borderRadius:
  //             BorderRadius.circular(12) // Match the container's corner radius
  //         ),
  //     child: InkWell(
  //       onTap: () async {
  //         await Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => ProjectDetailsPage(activeProject: project),
  //           ),
  //         );
  //
  //         // This might be really costly to do every time but not sure how else
  //         // to guarantee projects update after renaming or otherwise.
  //         _populateProjects();
  //       },
  //       child: Container(
  //         decoration: BoxDecoration(
  //           gradient: const LinearGradient(
  //             colors: [Color(0xFF3874CB), Color(0xFF183769)],
  //             begin: Alignment.topCenter,
  //             end: Alignment.bottomCenter,
  //           ),
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // Banner image at the top
  //             ClipRRect(
  //               borderRadius: const BorderRadius.only(
  //                 topLeft: Radius.circular(12),
  //                 topRight: Radius.circular(12),
  //               ),
  //               child: Image.asset(
  //                 bannerImage,
  //                 width: double.infinity,
  //                 height: 150,
  //                 fit: BoxFit.cover,
  //               ),
  //             ),
  //             // Project details section
  //             Padding(
  //               padding: const EdgeInsets.all(10),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   // Project name
  //                   Text(
  //                     project.title,
  //                     style: const TextStyle(
  //                       fontSize: 17,
  //                       fontWeight: FontWeight.bold,
  //                       color: Color(0xFFFFCC00),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 5),
  //                   // Team name
  //                   Text(
  //                     teamName,
  //                     style: const TextStyle(
  //                       fontSize: 12,
  //                       fontWeight: FontWeight.bold,
  //                       color: Color(0xFFFFCC00),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             // Row with Edit and Results buttons in the bottom right corner
  //             Padding(
  //               padding: const EdgeInsets.all(10),
  //               child: Row(
  //                 mainAxisAlignment: MainAxisAlignment.end,
  //                 children: [
  //                   // Edit Info button
  //                   OutlinedButton(
  //                     onPressed: () async {
  //                       // Handle navigation to Edit menu
  //                       final updated = await showModalBottomSheet<String>(
  //                         context: context,
  //                         isScrollControlled: true,
  //                         useSafeArea: true,
  //                         builder: (context) =>
  //                             EditProjectForm(activeProject: project),
  //                       );
  //
  //                       if (updated != null) {
  //                         if (updated == 'deleted') {
  //                           await _populateProjects();
  //                         } else if (updated == 'altered') {
  //                           setState(() {
  //                             // Update if something was changed in EditProject
  //                           });
  //                         }
  //                       }
  //                     },
  //                     style: OutlinedButton.styleFrom(
  //                       side: const BorderSide(
  //                         color: Color(0xFFFFCC00),
  //                         width: 2.0,
  //                       ),
  //                       foregroundColor: const Color(0xFFFFCC00),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                     ),
  //                     child: const Text(
  //                       'Edit Info',
  //                       style: TextStyle(fontSize: 12),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 10),
  //                   ElevatedButton(
  //                     onPressed: () {
  //                       Navigator.push(
  //                         context,
  //                         MaterialPageRoute(
  //                           builder: (context) =>
  //                               PdfReportPage(activeProject: project),
  //                         ),
  //                       );
  //                     },
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: const Color(0xFFFFCC00),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                     ),
  //                     child: const Text(
  //                       'Results',
  //                       style: TextStyle(
  //                         fontSize: 12,
  //                         color: Color(0xFF1D4076),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

class ProjectCard extends StatelessWidget {
  final String bannerImage;
  final Project project;
  final void Function(String) editProjectCallback;

  const ProjectCard({
    super.key,
    required this.bannerImage,
    required this.project,
    required this.editProjectCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12) // Match the container's corner radius
          ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailsPage(activeProject: project),
            ),
          );

          // This might be really costly to do every time but not sure how else
          // to guarantee projects update after renaming or otherwise.
          // _populateProjects(); TODO check if this is needed after refactor
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3874CB), Color(0xFF183769)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner image at the top
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.asset(
                  bannerImage,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              // Project details section
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project name
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFCC00),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Team name
                    Text(
                      project.team!.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFCC00),
                      ),
                    ),
                  ],
                ),
              ),
              // Row with Edit and Results buttons in the bottom right corner
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit Info button
                    OutlinedButton(
                      onPressed: () async {
                        // Handle navigation to Edit menu
                        final updated = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (context) =>
                              EditProjectForm(activeProject: project),
                        );

                        if (updated != null) {
                          editProjectCallback(updated);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFFFCC00),
                          width: 2.0,
                        ),
                        foregroundColor: const Color(0xFFFFCC00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Edit Info',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PdfReportPage(activeProject: project),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Results',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1D4076),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
