import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:p2bp_2025spring_mobile/change_team_name_form.dart';
import 'package:p2bp_2025spring_mobile/extensions.dart';
import 'package:p2bp_2025spring_mobile/invite_user_form.dart';
import 'package:p2bp_2025spring_mobile/manage_team_members_form.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';

import 'create_project_form.dart';
import 'db_schema_classes.dart';
import 'project_details_page.dart';
import 'theme.dart';

class TeamSettingsPage extends StatefulWidget {
  final Member member;
  final Team activeTeam;

  const TeamSettingsPage({
    super.key,
    required this.member,
    required this.activeTeam,
  });

  @override
  State<TeamSettingsPage> createState() => _TeamSettingsPageState();
}

class _TeamSettingsPageState extends State<TeamSettingsPage> {
  bool _isLoadingProjects = true;
  bool _isLoadingTeamMembers = true;
  bool _isMultiSelectMode = false;
  final Set<Project> _selectedProjects = {};
  late final RoleMap<Member> _teamMembers;

  @override
  void initState() {
    super.initState();
    if (widget.activeTeam.projects == null) {
      _getProjects();
    }
    if (widget.activeTeam.memberMap == null) {
      _getTeamMembers();
    } else {
      _teamMembers = widget.activeTeam.memberMap!;
    }
  }

  Future<void> _getProjects() async {
    await widget.activeTeam.loadProjectsInfo();
    setState(() {
      _isLoadingProjects = false;
    });
  }

  void _getTeamMembers() async {
    _teamMembers = await widget.activeTeam.loadMembersInfo();
    setState(() {
      _isLoadingTeamMembers = false;
    });
  }

  /// Call this method to toggle multi-select mode
  void toggleMultiSelect() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedProjects.clear();
      }
    });
  }

  void toggleProjectSelection(Project project) {
    setState(() {
      if (_selectedProjects.contains(project)) {
        _selectedProjects.remove(project);
      } else {
        _selectedProjects.add(project);
      }
    });
  }

  Widget _deleteProjectsDialog() {
    return GenericConfirmationDialog(
      titleText: 'Delete Projects?',
      contentText:
          'This will delete all selected projects and the tests within them. '
          'This cannot be undone. '
          'Are you absolutely certain you want to delete all these projects?',
      declineText: 'No, go back',
      confirmText: 'Yes, delete them',
      onConfirm: () async {
        for (final project in _selectedProjects) {
          await project.delete();
          // the 2 statements below might not be needed because it is handled in project.delete
          widget.activeTeam.projectRefs
              .removeWhere((ref) => ref.id == project.id);
          widget.activeTeam.projects!.remove(project);
        }

        if (!mounted) return;
        Navigator.pop(context);
        setState(() {
          // Rebuild projects list after changes
        });
      },
    );
  }

  Widget _deleteTeamDialog() {
    return GenericConfirmationDialog(
      titleText: 'Delete This Team?',
      contentText: 'This will delete the currently selected team as well as '
          'well as all projects within it, and the tests within those '
          'projects. This cannot be undone. '
          'Are you absolutely certain you want to delete this team?',
      declineText: 'No, go back',
      confirmText: 'Yes, delete this team',
      onConfirm: () async {
        final success = await widget.activeTeam.delete();
        if (success == true) {
          widget.member.teams?.remove(widget.activeTeam);
          widget.member.teamRefs
              .removeWhere((ref) => ref.id == widget.activeTeam.id);
          if (!mounted) return;
          Navigator.pop(context);
          Navigator.pop(context, true);
        } else {
          if (!mounted) return;
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light
            .copyWith(statusBarColor: Colors.transparent),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        forceMaterialTransparency: true,
        actionsPadding: EdgeInsets.symmetric(horizontal: 4),
        actions: [
          _SettingsMenuButton(
            editName: () async {
              final String? newName = await showModalBottomSheet<String>(
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                context: context,
                builder: (context) => ChangeTeamNameForm(
                  currentName: widget.activeTeam.title,
                ),
              );

              if (newName == null || newName == widget.activeTeam.title) return;
              setState(() {
                widget.activeTeam.title = newName;
              });
              widget.activeTeam.update();
            },
            selectProjects: toggleMultiSelect,
            deleteTeam: () {
              showDialog(
                context: context,
                builder: (context) => _deleteTeamDialog(),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: defaultGrad),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _AvatarAndTitleRow(
                  title: widget.activeTeam.title,
                  manageMembersCallback: _isLoadingTeamMembers
                      ? null
                      : () {
                          showModalBottomSheet(
                            useSafeArea: true,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            context: context,
                            builder: (BuildContext context) =>
                                ManageTeamMembersForm(
                              activeTeam: widget.activeTeam,
                              teamMembers: _teamMembers,
                            ),
                          );
                        },
                  inviteCallback: _isLoadingTeamMembers
                      ? null
                      : () {
                          showModalBottomSheet(
                            useSafeArea: true,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            context: context,
                            builder: (context) => InviteUserForm(
                              activeTeam: widget.activeTeam,
                              teamMembers: _teamMembers.toSingleList(),
                            ),
                          );
                          // _showInviteDialog(context);
                        },
                ),
              ),
              SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Projects',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    if (_isMultiSelectMode)
                      Row(
                        children: [
                          TextButton(
                            onPressed: toggleMultiSelect,
                            child: Text(
                              'Done',
                              style: TextStyle(
                                  color: Color(0xFF62B6FF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 5),
                          ElevatedButton(
                            onPressed: _selectedProjects.isEmpty
                                ? null
                                : () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          _deleteProjectsDialog(),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor:
                                  _isMultiSelectMode ? Colors.red : Colors.blue,
                              minimumSize: Size(0, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            useSafeArea: true,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            context: context,
                            builder: (context) => CreateProjectForm(
                              activeTeam: widget.activeTeam,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.blue,
                          minimumSize: Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Create New',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              if (_isLoadingProjects)
                const CircularProgressIndicator()
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: widget.activeTeam.projects!.length,
                    itemBuilder: (context, index) {
                      final project = widget.activeTeam.projects![index];
                      bool isSelected = _selectedProjects.contains(project);
                      return _ProjectListTile(
                        isMultiSelectMode: _isMultiSelectMode,
                        isSelected: isSelected,
                        project: project,
                        toggleProjectSelection: toggleProjectSelection,
                        onTap: () async {
                          if (_isMultiSelectMode) {
                            toggleProjectSelection(project);
                          } else {
                            final status = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProjectDetailsPage(
                                  member: widget.member,
                                  activeProject: project,
                                ),
                              ),
                            );
                            if (status == 'deleted') {
                              setState(() {
                                widget.activeTeam.projectRefs.removeAt(index);
                                widget.activeTeam.projects!.removeAt(index);
                              });
                            }
                          }
                        },
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return _isMultiSelectMode
                          ? Divider(
                              color: Colors.white.withValues(alpha: 0.3),
                              thickness: 1,
                              indent: 50,
                              endIndent: 16,
                            )
                          : Divider(
                              color: Colors.white.withValues(alpha: 0.3),
                              thickness: 1,
                              indent: 16,
                              endIndent: 16,
                            );
                    },
                  ),
                ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectListTile extends StatelessWidget {
  final bool isMultiSelectMode;
  final bool isSelected;
  final Project project;
  final void Function(Project) toggleProjectSelection;
  final VoidCallback onTap;

  const _ProjectListTile({
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.project,
    required this.toggleProjectSelection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // If in multi-select mode, show bubble for selecting project.
      leading: isMultiSelectMode
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => toggleProjectSelection(project),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Color(0xFF62B6FF)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
                SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/RedHouse.png', // Replace with project image
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/RedHouse.png', // Replace with project image
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
      title: Text(
        project.title,
        style: TextStyle(color: Colors.white),
      ),
      // Hide trailing chevron when in multi-select mode
      trailing: isMultiSelectMode
          ? null
          : Icon(Icons.chevron_right, color: Colors.white),
      onTap: onTap,
    );
  }
}

class _SettingsMenuButton extends StatelessWidget {
  final VoidCallback? editName;
  // final VoidCallback? changeColor;
  final VoidCallback? selectProjects;
  // final VoidCallback? archiveTeam;
  final VoidCallback? deleteTeam;

  const _SettingsMenuButton({
    this.editName,
    // this.changeColor,
    this.selectProjects,
    // this.archiveTeam,
    this.deleteTeam,
  });

  static const ButtonStyle paddingButtonStyle = ButtonStyle(
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)));
  static const TextStyle whiteText = TextStyle(color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return MenuBar(
      style: MenuStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        )),
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
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
                Icons.edit_outlined,
                color: Colors.white,
              ),
              onPressed: editName,
              child: Text(
                'Edit Team Name',
                style: whiteText,
              ),
            ),
            Divider(color: Colors.white54, height: 1),
            // MenuItemButton(
            //   style: paddingButtonStyle,
            //   trailingIcon: Icon(
            //     Icons.palette_outlined,
            //     color: Colors.white,
            //   ),
            //   onPressed: changeColor,
            //   child: Text(
            //     'Change Team Color',
            //     style: whiteText,
            //   ),
            // ),
            // Divider(color: Colors.white54, height: 1),
            MenuItemButton(
              style: paddingButtonStyle,
              trailingIcon: Icon(
                Icons.check_circle_outlined,
                color: Colors.white,
              ),
              onPressed: selectProjects,
              child: Text(
                'Select Projects',
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
            //   onPressed: archiveTeam,
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
              onPressed: deleteTeam,
              child: Text(
                'Delete Team',
                style: TextStyle(color: Color(0xFFFD6265)),
              ),
            ),
          ],
          child: Icon(
            Icons.tune_rounded,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _AvatarAndTitleRow extends StatelessWidget {
  final String title;
  final VoidCallback? manageMembersCallback;
  final VoidCallback? inviteCallback;

  const _AvatarAndTitleRow({
    required this.title,
    required this.inviteCallback,
    this.manageMembersCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Profile Avatar on the left
        Flexible(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 36,
                // TODO: Add actual image
              ),
              GestureDetector(
                onTap: () async {
                  // Open image edit functionality
                  final XFile? pickedFile = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    final File imageFile = File(pickedFile.path);
                    // TODO: Submit image or something.
                    print("Image selected: ${imageFile.path}");
                  } else {
                    print("No image selected.");
                  }
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Column with Team Name and Team Members Row
        SizedBox(
          // Height is 72 to match profile avatar on left of row
          height: 72,
          // Width of 206 is exactly the width used by all the Positioned stuff
          width: 206,
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Overlapping team members
                    for (int index = 0; index < 6; index++)
                      Positioned(
                        left: index * 24.0, // Overlap amount
                        child: CircleAvatar(
                          radius: 16,
                          // TODO: Add team member photos
                        ),
                      ),
                    // Edit button overlapping the last avatar
                    Positioned(
                      // Overlap position for the last avatar
                      left: 5 * 24.0 + 20,
                      // Adjust for proper vertical alignment
                      top: 12,
                      child: GestureDetector(
                        onTap: manageMembersCallback,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.edit,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Invite button to the right of the Team Members Profile Avatars
                    Positioned(
                      // Place the invite button to the right of the team avatars
                      left: 6 * 24.0 + 20,
                      // Align with the team avatars vertically
                      top: -6,
                      child: ElevatedButton(
                        onPressed: inviteCallback,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                          minimumSize: Size(30, 25),
                          backgroundColor: Colors.blue,
                        ),
                        child: Icon(
                          Icons.person_add, // Invite icon
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
