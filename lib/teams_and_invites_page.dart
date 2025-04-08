import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'db_schema_classes.dart';
import 'firestore_functions.dart';
import 'team_settings_page.dart';
import 'theme.dart';

class TeamsAndInvitesPage extends StatefulWidget {
  final Member member;

  const TeamsAndInvitesPage({super.key, required this.member});

  @override
  State<TeamsAndInvitesPage> createState() => _TeamsAndInvitesPageState();
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class _TeamsAndInvitesPageState extends State<TeamsAndInvitesPage> {
  final User? _loggedInUser = FirebaseAuth.instance.currentUser;

  List<Team> _teams = [];
  List<TeamInvite> _teamInvites = [];
  DocumentReference? currentTeam;
  bool _isLoadingTeams = true;
  bool _isLoadingInvites = true;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.member.teams == null) {
      _getTeams();
    } else {
      _teams = widget.member.teams!;
      _isLoadingTeams = false;
    }
    if (widget.member.teamInvites == null) {
      _getInvites();
    } else {
      _teamInvites = widget.member.teamInvites!;
      _isLoadingInvites = false;
    }
  }

  Future<void> _getTeams() async {
    try {
      _teams = await widget.member.loadTeamsInfo();

      setState(() {
        _isLoadingTeams = false;
      });
    } catch (e, stacktrace) {
      print('Exception retrieving teams: $e');
      print('Stacktrace: $stacktrace');
    }
  }

  Future<void> _getInvites() async {
    try {
      _teamInvites = await widget.member.loadTeamInvitesInfo();

      setState(() {
        _isLoadingInvites = false;
      });
    } catch (e, stacktrace) {
      print('Exception retrieving team invites: $e');
      print('Stacktrace: $stacktrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: p2bpBlue),
              onPressed: () => Navigator.pop(context),
            ),
            systemOverlayStyle: SystemUiOverlayStyle.dark
                .copyWith(statusBarColor: Colors.transparent),
            bottom: TabBar(
              labelColor: p2bpBlue,
              indicatorColor: p2bpBlue,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(
                  child: Text(
                    'Teams',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                Tab(
                  child: Text(
                    'Invites',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              if (_isLoadingTeams)
                const Center(child: CircularProgressIndicator())
              else
                RefreshIndicator(
                  onRefresh: () async {
                    await _getTeams();
                  },
                  child: _teams.isNotEmpty
                      ? ListView.separated(
                          padding: const EdgeInsets.only(
                            left: 35,
                            right: 35,
                            top: 50,
                            bottom: 20,
                          ),
                          itemCount: _teams.length,
                          itemBuilder: (context, index) {
                            return TeamCard(
                              team: _teams[index],
                              selected: selectedIndex == index,
                              radioSelectCallback: () async {
                                await _firestore
                                    .collection('users')
                                    .doc(_loggedInUser?.uid)
                                    .update({
                                  'selectedTeam': _firestore
                                      .doc('/teams/${_teams[index].id}'),
                                });
                                setState(() {
                                  selectedIndex = index;
                                });
                              },
                              teamSettingsCallback: () async {
                                final bool? doRefresh = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TeamSettingsPage(
                                      member: widget.member,
                                      activeTeam: _teams[index],
                                    ),
                                  ),
                                );
                                if (doRefresh == true) _getTeams();
                                setState(() {
                                  // Just in case something changed.
                                });
                              },
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 50),
                        )
                      : CustomScrollView(
                          slivers: <Widget>[
                            SliverFillRemaining(
                              child: Align(
                                alignment: Alignment(0, -0.3),
                                child: Text(
                                  'You have no teams!\nJoin or create one '
                                  'first, or pull down to refresh.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              if (_isLoadingInvites)
                const Center(child: CircularProgressIndicator())
              else
                RefreshIndicator(
                  onRefresh: () async {
                    await _getInvites();
                  },
                  child: _teamInvites.isNotEmpty
                      ? ListView.separated(
                          padding: const EdgeInsets.only(
                            left: 35,
                            right: 35,
                            top: 25,
                            bottom: 25,
                          ),
                          itemCount: _teamInvites.length,
                          itemBuilder: (BuildContext context, int index) {
                            final invite = _teamInvites[index];
                            return InviteCard(
                              invite: invite,
                              acceptCallback: () {
                                // Add to database
                                addUserToTeam(invite.id);
                                // Remove invite from screen
                                setState(() {
                                  _teamInvites.removeWhere((team) =>
                                      team.id.compareTo(invite.id) == 0);
                                  // _teamsCount = _teamInvites.length;
                                });
                              },
                              declineCallback: () {
                                // Remove invite from database
                                removeInviteFromUser(invite.id);
                                // Remove invite from screen
                                setState(() {
                                  _teamInvites.removeWhere((team) =>
                                      team.id.compareTo(invite.id) == 0);
                                  // _teamsCount = _teamInvites.length;
                                });
                              },
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(height: 25),
                        )
                      // Else if user does not have invites
                      : CustomScrollView(
                          slivers: <Widget>[
                            SliverFillRemaining(
                              child: Align(
                                alignment: Alignment(0, -0.3),
                                child: Text(
                                  'You have no invites! Pull down to refresh.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class TeamCard extends StatelessWidget {
  final Team team;
  final bool selected;
  final VoidCallback radioSelectCallback;
  final VoidCallback teamSettingsCallback;

  const TeamCard({
    super.key,
    required this.team,
    required this.selected,
    required this.radioSelectCallback,
    required this.teamSettingsCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p2bpBlue,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      height: 200,
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: radioSelectCallback,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 10.0, bottom: 10.0, right: 5.0, top: 5.0),
                child: Tooltip(
                  message: "Select team",
                  child: selected
                      ? const Icon(
                          Icons.radio_button_on,
                          color: placeYellow,
                        )
                      : const Icon(
                          Icons.radio_button_off,
                          color: placeYellow,
                        ),
                ),
              ),
            ),
          ),
          const CircleAvatar(radius: 35),
          const SizedBox(width: 20),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text.rich(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Team: '),
                      TextSpan(
                        text: team.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Text.rich(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${team.projectRefs.length} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: 'Projects'),
                    ],
                  ),
                ),
                const Row(
                  children: [
                    Text(
                      'Members: ',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(
                Icons.chevron_right,
                color: Colors.white,
              ),
              tooltip: 'Open team settings',
              onPressed: teamSettingsCallback,
            ),
          ),
        ],
      ),
    );
  }
}

class InviteCard extends StatelessWidget {
  final TeamInvite invite;
  final VoidCallback acceptCallback;
  final VoidCallback declineCallback;

  const InviteCard({
    super.key,
    required this.invite,
    required this.acceptCallback,
    required this.declineCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p2bpBlue,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      height: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(width: 15),
          const CircleAvatar(
            radius: 25,
          ),
          const SizedBox(width: 15),
          Flexible(
            child: Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    TextSpan(
                      children: [
                        TextSpan(
                          text: invite.ownerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' has invited you to join: '),
                        TextSpan(
                          text: invite.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.check),
                        tooltip: 'Accept invitation',
                        color: Colors.white,
                        onPressed: acceptCallback,
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Decline invitation',
                        color: Colors.white,
                        onPressed: declineCallback,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0),
        ],
      ),
    );
  }
}
