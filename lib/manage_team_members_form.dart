import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:p2bp_2025spring_mobile/firestore_functions.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';

import 'db_schema_classes.dart';
import 'theme.dart';

class ManageTeamMembersForm extends StatefulWidget {
  final Team activeTeam;
  final List<Member> teamMembers;

  const ManageTeamMembersForm({
    super.key,
    required this.teamMembers,
    required this.activeTeam,
  });

  @override
  State<ManageTeamMembersForm> createState() => _ManageTeamMembersFormState();
}

class _ManageTeamMembersFormState extends State<ManageTeamMembersForm> {
  Future<bool> _showRemoveMemberDialog(Member member) async {
    return await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) => _RemoveMemberDialog(member: member),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          gradient: defaultGrad,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BarIndicator(),
              // Label for the first member.
              Padding(
                padding: EdgeInsets.only(left: 55),
                child: Text(
                  "Team Admin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              if (widget.teamMembers.isEmpty)
                SizedBox()
              else ...<Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(),
                  title: Text(
                    widget.teamMembers.first.fullName,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Icon(
                      FontAwesomeIcons.crown,
                      color: Color(0xFFFFCC00),
                    ),
                  ),
                ),
                Divider(
                  color: Colors.white.withValues(alpha: 0.3),
                  thickness: 1,
                ),
                // The rest of the team members.
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.4,
                  child: ListView.separated(
                    itemCount: widget.teamMembers.length - 1,
                    itemBuilder: (context, index) {
                      final thisMember = widget.teamMembers[index + 1];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Delete Icon
                            GestureDetector(
                              onTap: () async {
                                final didRemove =
                                    await _showRemoveMemberDialog(thisMember);

                                if (didRemove != true) return;
                                await removeUserFromTeam(
                                  thisMember.userID,
                                  widget.activeTeam.teamID,
                                );
                                setState(() {
                                  widget.teamMembers.remove(thisMember);
                                });
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                                child: Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            // Circle Avatar
                            CircleAvatar(),
                          ],
                        ),
                        title: Text(
                          thisMember.fullName,
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) {
                      return Divider(
                        color: Colors.white.withValues(alpha: 0.3),
                        thickness: 1,
                        indent: 50.0,
                      );
                    },
                  ),
                ),
              ],
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoveMemberDialog extends StatelessWidget {
  final Member member;

  const _RemoveMemberDialog({required this.member});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 14.0),
            decoration: BoxDecoration(
              color: p2bpBlue.withValues(alpha: 0.65), // frosted glass effect
              borderRadius: BorderRadius.circular(18.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remove Team Member',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white),
                ),
                SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                    children: [
                      TextSpan(text: 'Are you sure you want to remove '),
                      TextSpan(
                        text: member.fullName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' from the team?'),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child:
                          Text("Cancel", style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      child:
                          Text("Remove", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
