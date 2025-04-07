import 'package:flutter/material.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';

import 'db_schema_classes.dart';
import 'firestore_functions.dart';

class InviteUserForm extends StatefulWidget {
  final Team activeTeam;
  final List<Member> teamMembers;

  const InviteUserForm({
    super.key,
    required this.activeTeam,
    required this.teamMembers,
  });

  @override
  State<InviteUserForm> createState() => _InviteUserFormState();
}

class _InviteUserFormState extends State<InviteUserForm> {
  List<Member> membersSearch = [];
  List<Member> invitedMembers = [];
  int itemCount = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: Container(
          decoration: BoxDecoration(
            gradient: defaultGrad,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const BarIndicator(),
              Center(
                child: Text(
                  'Invite Users to this Team',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Search Members',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 8),
              TextFormField(
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  labelText: 'Members',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
                onChanged: (memberText) async {
                  if (memberText.length > 2) {
                    setState(() {
                      _isLoading = true;
                    });

                    membersSearch = await Member.queryByFullName(memberText);
                    membersSearch.removeWhere(
                        (member) => widget.teamMembers.contains(member));
                    itemCount = membersSearch.length;

                    setState(() {
                      _isLoading = false;
                    });
                  } else {
                    itemCount = 0;
                  }
                },
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 250,
                child: itemCount > 0
                    ? ListView.separated(
                        itemBuilder: (context, index) {
                          final member = membersSearch[index];
                          final invited = invitedMembers.contains(member);
                          return MemberInviteCard(
                            member: member,
                            invited: invited,
                            inviteCallback: () {
                              if (!invited) {
                                sendInviteToUser(
                                    member.id, widget.activeTeam.id);
                                setState(() {
                                  invitedMembers.add(member);
                                });
                              }
                            },
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemCount: itemCount)
                    : _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : const Text(
                            'No users matching criteria. '
                            'Enter at least 3 characters to search.',
                            style: TextStyle(color: Colors.white),
                          ),
              ),
              SizedBox(height: 20),
              InkWell(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: placeYellow),
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
