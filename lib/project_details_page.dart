import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:p2bp_2025spring_mobile/change_project_description_form.dart';
import 'package:p2bp_2025spring_mobile/change_project_name_form.dart';
import 'package:p2bp_2025spring_mobile/create_test_form.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';

import 'db_schema_classes.dart';
import 'firestore_functions.dart';
import 'mini_map.dart';

class ProjectDetailsPage extends StatefulWidget {
  final Member member;
  final Project activeProject;

  /// IMPORTANT: When navigating to this page, pass in project details. Use
  /// `getProjectInfo()` from firestore_functions.dart to retrieve project
  /// object w/ data.
  /// <br/>Note: project is returned as future, await return before passing.
  const ProjectDetailsPage({
    super.key,
    required this.member,
    required this.activeProject,
  });

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  int _testCount = 0;
  bool _isLoading = true;
  late GoogleMapController mapController;
  String _coverImageUrl = '';
  late final bool _isAdmin;

  @override
  void initState() {
    super.initState();
    if (widget.activeProject.tests == null) {
      _loadTests();
    } else {
      _isLoading = false;
    }
    _isAdmin = widget.activeProject.memberRefMap[GroupRole.owner]!.any(
        (memberRef) => memberRef.id == FirebaseAuth.instance.currentUser!.uid);
    _coverImageUrl = widget.activeProject.coverImageUrl;
  }

  void _loadTests() async {
    await widget.activeProject.loadAllTestInfo();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activeProject.tests != null) {
      _testCount = widget.activeProject.tests!.length;
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: MediaQuery.sizeOf(context).height * 0.2,
            pinned: true,
            automaticallyImplyLeading: false,
            leadingWidth: 60,
            systemOverlayStyle: SystemUiOverlayStyle.dark
                .copyWith(statusBarColor: Colors.transparent),
            // Custom back arrow button
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Container(
                // Opaque circle container for visibility
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Icon(Icons.arrow_back, color: p2bpBlue),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.only(right: 12),
            // 'Edit Options' button overlaid on right side of cover photo
            actions: [
              _SettingsMenuButton(
                changePhoto: () async {
                  final XFile? pickedFile = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    final File imageFile = File(pickedFile.path);
                    final coverImageUrl =
                        await widget.activeProject.addCoverImage(imageFile);
                    setState(() {
                      _coverImageUrl = coverImageUrl;
                    });
                  }
                },
                editName: () async {
                  final newName = await showModalBottomSheet<String>(
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    context: context,
                    builder: (context) => ChangeProjectNameForm(
                      currentName: widget.activeProject.title,
                    ),
                  );

                  if (newName == null ||
                      newName == widget.activeProject.title) {
                    return;
                  }

                  setState(() {
                    widget.activeProject.title = newName;
                  });
                  widget.activeProject.update();
                },
                editDescription: () async {
                  final newDescription = await showModalBottomSheet(
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    context: context,
                    builder: (context) => ChangeProjectDescriptionForm(
                      currentDescription: widget.activeProject.description,
                    ),
                  );

                  if (newDescription == null ||
                      newDescription == widget.activeProject.description) {
                    return;
                  }

                  setState(() {
                    widget.activeProject.description = newDescription;
                  });
                  widget.activeProject.update();
                },
                delete: () async {
                  final didDelete = await showDeleteProjectDialog(
                    context: context,
                    project: widget.activeProject,
                  );

                  if (!context.mounted) return;
                  if (didDelete == true) {
                    Navigator.pop(context, 'deleted');
                  }
                },
              ),
            ],
            flexibleSpace: DecoratedBox(
              decoration: BoxDecoration(
                color: p2bpBlue,
                image: _coverImageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_coverImageUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: FlexibleSpaceBar(
                background: ClipRRect(
                  child: Container(
                    decoration: BoxDecoration(
                      color: p2bpDarkBlue,
                      image: _coverImageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(_coverImageUrl),
                              fit: BoxFit.cover)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverList(delegate: SliverChildListDelegate([_getPageBody()])),
        ],
      ),
    );
  }

  Widget _getPageBody() {
    return Container(
      decoration: BoxDecoration(gradient: defaultGrad),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text(
                widget.activeProject.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 40),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(
                  'Project Description',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white, width: .5),
                  bottom: BorderSide(color: Colors.white, width: .5),
                ),
                color: Color(0x699F9F9F),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                child: Text.rich(
                  maxLines: 7,
                  overflow: TextOverflow.ellipsis,
                  TextSpan(text: "${widget.activeProject.description}\n\n\n"),
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 30),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: MiniMap(
                    activeProject: widget.activeProject,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Research Activities",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isAdmin)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.only(left: 15, right: 15),
                        backgroundColor: Color(0xFF62B6FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        // foregroundColor: foregroundColor,
                        // backgroundColor: backgroundColor,
                      ),
                      onPressed: _showCreateTestModal,
                      label: Text('Create'),
                      icon: Icon(Icons.add),
                      iconAlignment: IconAlignment.end,
                    )
                  else
                    SizedBox(),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Color(0x22535455),
                border: Border(
                  top: BorderSide(color: Colors.white, width: .5),
                ),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _testCount > 0
                      ? _buildTestListView()
                      : const Center(
                          child: Text(
                            'No research activities. Create one first!',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTestModal() async {
    final Map<String, dynamic>? newTestInfo = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 234, 245, 255),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: CreateTestForm(
                activeProject: widget.activeProject,
              ),
            );
          },
        );
      },
    );
    if (newTestInfo == null) return;
    final Test test = await saveTest(
      title: newTestInfo['title'],
      scheduledTime: newTestInfo['scheduledTime'],
      projectRef:
          _firestore.collection('projects').doc(widget.activeProject.id),
      collectionID: newTestInfo['collectionID'],
      standingPoints: newTestInfo.containsKey('standingPoints')
          ? newTestInfo['standingPoints']
          : null,
      testDuration: newTestInfo.containsKey('testDuration')
          ? newTestInfo['testDuration']
          : null,
      intervalDuration: newTestInfo.containsKey('intervalDuration')
          ? newTestInfo['intervalDuration']
          : null,
      intervalCount: newTestInfo.containsKey('intervalCount')
          ? newTestInfo['intervalCount']
          : null,
    );
    setState(() {
      widget.activeProject.tests?.add(test);
    });
  }

  Widget _buildTestListView() {
    widget.activeProject.tests!.sort((a, b) => testTimeComparison(a, b));

    Widget list = ListView.separated(
      physics: ClampingScrollPhysics(),
      shrinkWrap: true,
      itemCount: _testCount,
      padding: const EdgeInsets.only(
        left: 15,
        right: 15,
        top: 25,
        bottom: 30,
      ),
      itemBuilder: (BuildContext context, int index) {
        return TestCard(
          test: widget.activeProject.tests![index],
          project: widget.activeProject,
        );
      },
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 10),
    );

    return list;
  }
}

// TODO make this a much more customizable widget for making menus of this
//  style with different label names and callbacks and whatnot, probably
//  copy MenuBar flutter.dev example somewhat
class _SettingsMenuButton extends StatelessWidget {
  final VoidCallback? changePhoto;
  final VoidCallback? editName;
  final VoidCallback? editDescription;
  // final VoidCallback? archiveCallback;
  final VoidCallback? delete;

  const _SettingsMenuButton({
    this.changePhoto,
    this.editName,
    this.editDescription,
    // this.archiveCallback,
    this.delete,
  });

  static const ButtonStyle paddingButtonStyle = ButtonStyle(
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)));
  static const TextStyle whiteText = TextStyle(color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return MenuBar(
      style: MenuStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        )),
        backgroundColor:
            WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.8)),
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
      ),
      children: <Widget>[
        SubmenuButton(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            )),
            visualDensity:
                VisualDensity(horizontal: VisualDensity.minimumDensity),
          ),
          menuStyle: MenuStyle(
            backgroundColor:
                WidgetStatePropertyAll(p2bpBlue.withValues(alpha: 0.85)),
            padding: WidgetStatePropertyAll(EdgeInsets.zero),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          menuChildren: [
            MenuItemButton(
              style: paddingButtonStyle,
              trailingIcon: Icon(
                Icons.palette_outlined,
                color: Colors.white,
              ),
              onPressed: changePhoto,
              child: Text(
                'Change Project Photo',
                style: whiteText,
              ),
            ),
            Divider(color: Colors.white54, height: 1),
            MenuItemButton(
              style: paddingButtonStyle,
              trailingIcon: Icon(
                Icons.edit_outlined,
                color: Colors.white,
              ),
              onPressed: editName,
              child: Text(
                'Edit Project Name',
                style: whiteText,
              ),
            ),
            Divider(color: Colors.white54, height: 1),
            MenuItemButton(
              style: paddingButtonStyle,
              trailingIcon: Icon(
                Icons.description,
                color: Colors.white,
              ),
              onPressed: editDescription,
              child: Text(
                'Edit Project Description',
                style: whiteText,
              ),
            ),
            Divider(color: Colors.white54, height: 1),
            // MenuItemButton(
            //   style: paddingButtonStyle,
            //   trailingIcon: Icon(
            //     Icons.inventory_2_outlined,
            //     color: Colors.white,
            //   ),
            //   onPressed: archiveCallback,
            //   child: Text(
            //     'Archive Team',
            //     style: whiteText,
            //   ),
            // ),
            // Divider(color: Colors.white54, height: 1),
            MenuItemButton(
              style: paddingButtonStyle,
              trailingIcon:
                  Icon(Icons.delete_outlined, color: Color(0xFFFD6265)),
              onPressed: delete,
              child: Text(
                'Delete Project',
                style: TextStyle(color: Color(0xFFFD6265)),
              ),
            ),
          ],
          child: Icon(
            Icons.tune_rounded,
            color: p2bpBlue,
          ),
        ),
      ],
    );
  }
}

class TestCard extends StatelessWidget {
  final Test test;
  final Project project;

  TestCard({
    super.key,
    required this.test,
    required this.project,
  }) : isPastDate = test.scheduledTime.compareTo(Timestamp.now()) <= 0;

  final bool isPastDate;

  @override
  Widget build(BuildContext context) {
    final Color dateColor = isPastDate ? Color(0xFFB71C1C) : Colors.black;
    return InkWell(
      onLongPress: () {
        // TODO: Add menu for deletion?
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  // TODO: change corresponding to test type
                  CircleAvatar(
                    child: Text(test.getInitials()),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 15, color: dateColor),
                            SizedBox(width: 3),
                            Text(
                              DateFormat.yMMMd()
                                  .format(test.scheduledTime.toDate()),
                              style: TextStyle(fontSize: 14, color: dateColor),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: dateColor),
                            SizedBox(width: 3),
                            Text(
                              '${DateFormat.E().format(test.scheduledTime.toDate())}'
                              ' at ${DateFormat.jmv().format(test.scheduledTime.toDate())}',
                              style: TextStyle(
                                fontSize: 14,
                                color: dateColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    test.isComplete ? 'Completed ' : 'Not Completed ',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  test.isComplete
                      ? Icon(
                          Icons.check_circle_outline_sharp,
                          size: 18,
                          color: Colors.green,
                        )
                      : SizedBox(),
                  SizedBox(
                    width: 30,
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.blue,
                      ),
                      tooltip: 'Start test',
                      onPressed: () async {
                        if (test.isComplete) {
                          final bool? doOverwrite = await showDialog(
                            context: context,
                            builder: (context) {
                              return RedoConfirmationWidget(
                                test: test,
                                project: project,
                              );
                            },
                          );
                          if (doOverwrite != null &&
                              doOverwrite &&
                              context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => test.getPage(project)),
                            );
                          }
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => test.getPage(project)),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RedoConfirmationWidget extends StatelessWidget {
  const RedoConfirmationWidget({
    super.key,
    required this.test,
    required this.project,
  });

  final Test test;
  final Project project;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Column(
        children: [
          Text(
            "Wait!",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        "This test has already been completed. "
        "If you continue, you will overwrite the data in this test. "
        "\nWould you still like to continue?",
        style: TextStyle(fontSize: 16),
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Flexible(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text(
                  'No, take me back.',
                  style: TextStyle(fontSize: 17),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Flexible(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: Text(
                  'Yes, overwrite it.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
