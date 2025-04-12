import 'dart:async';

import 'package:flutter/material.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';

import 'db_schema_classes.dart';

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
  List<Member> _searchResults = [];
  final List<Member> _invitedMembers = [];
  bool _isLoading = false;

  Timer? _searchDelayTimer;
  String _searchTextBuffer = '';

  @override
  void dispose() {
    _searchDelayTimer?.cancel();
    super.dispose();
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
              const SizedBox(height: 12),
              Text(
                'Search Members',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
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
                onChanged: (searchText) async {
                  if (searchText.length > 2) {
                    setState(() {
                      _isLoading = true;
                    });

                    // Delay after text stops changing before search.
                    // This delay is to prevent excessive amount of queries
                    // as user is typing.
                    _searchDelayTimer?.cancel();
                    _searchTextBuffer = searchText;
                    _searchDelayTimer = Timer(Duration(seconds: 1), () async {
                      // Do search
                      _searchResults =
                          await Member.queryByFullName(_searchTextBuffer);

                      // Remove current team members from results by id.
                      final List<String> teamMemberIds = [
                        for (final member in widget.teamMembers) member.id,
                      ];
                      _searchResults.removeWhere(
                          (member) => teamMemberIds.contains(member.id));

                      setState(() {
                        _isLoading = false;
                      });
                    });
                  } else {
                    _searchDelayTimer?.cancel();
                    setState(() {
                      _isLoading = false;
                      _searchResults = [];
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 250,
                child: _searchResults.isNotEmpty
                    ? ListView.separated(
                        itemBuilder: (context, index) {
                          final member = _searchResults[index];
                          final invited = _invitedMembers.contains(member);
                          return MemberInviteCard(
                            member: member,
                            invited: invited,
                            inviteMember: () {
                              if (!invited) {
                                TeamInvite.sendToUser(
                                  member,
                                  widget.activeTeam,
                                );
                                setState(() {
                                  _invitedMembers.add(member);
                                });
                              }
                            },
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemCount: _searchResults.length,
                      )
                    : _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : const Text(
                            'No users matching criteria. '
                            'Enter at least 3 characters to search.',
                            style: TextStyle(color: Colors.white),
                          ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
