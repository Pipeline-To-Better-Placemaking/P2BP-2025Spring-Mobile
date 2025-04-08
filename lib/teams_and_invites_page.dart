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
  int teamsCount = 0;
  int invitesCount = 0;
  int selectedIndex = 0;

  Future<void> _getTeams() async {
    try {
      if (widget.member.teams == null) {
        _teams = await widget.member.loadTeamsInfo();
      }
      setState(() {
        _isLoadingTeams = false;
        teamsCount = _teams.length;
      });
    } catch (e, stacktrace) {
      print('Exception retrieving teams: $e');
      print('Stacktrace: $stacktrace');
    }
  }

  // Gets user info and once that is done gets teams and invites
  Future<void> _getInvites() async {
    try {
      if (widget.member.teamInvites == null) {
        _teamInvites = await widget.member.loadTeamInvitesInfo();
      }
      setState(() {
        _isLoadingInvites = false;
        invitesCount = _teamInvites.length;
      });
    } catch (e, stacktrace) {
      print('Exception retrieving team invites: $e');
      print('Stacktrace: $stacktrace');
    }
  }

  // Future<void> _getTeams() async {
  //   try {
  //     _teams = await getTeamsIDs();
  //     currentTeam = await getCurrentTeam();
  //
  //     if (currentTeam == null && _teams.isNotEmpty) {
  //       // No selected team:
  //       print("No team selected. Defaulting to first if available.");
  //       await _firestore.collection('users').doc(_loggedInUser?.uid).update({
  //         'selectedTeam': _firestore.doc('/teams/${_teams.first.id}'),
  //       });
  //       setState(() {
  //         selectedIndex = 0;
  //       });
  //     } else if (_teams.isNotEmpty) {
  //       // A list of teams with a selected team:
  //       setState(() {
  //         selectedIndex = _teams
  //             .indexWhere((team) => team.id.compareTo(currentTeam!.id) == 0);
  //       });
  //     } else if (_teams.isEmpty && currentTeam != null) {
  //       // No teams but a selected team:
  //       _firestore
  //           .collection('users')
  //           .doc(_loggedInUser?.uid)
  //           .update({'selectedTeam': null});
  //       setState(() {
  //         selectedIndex = -1;
  //       });
  //     } else {
  //       // No teams but a selected team:
  //       setState(() {
  //         selectedIndex = -1;
  //       });
  //     }
  //     _isLoadingTeams = false;
  //     teamsCount = _teams.length;
  //   } catch (e, stacktrace) {
  //     print('Exception retrieving teams: $e');
  //     print('Stacktrace: $stacktrace');
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _getTeams();
    _getInvites();
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
              teamsCount > 0
                  // If user has teams, display them
                  ? RefreshIndicator(
                      onRefresh: () async {
                        await _getTeams();
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.only(
                          left: 35,
                          right: 35,
                          top: 50,
                          bottom: 20,
                        ),
                        itemCount: teamsCount,
                        itemBuilder: (BuildContext context, int index) {
                          return buildContainer(
                            index: index,
                            color: p2bpBlue,
                            numProjects: _teams[index].projectRefs.length,
                            team: _teams[index],
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(
                          height: 50,
                        ),
                      ),
                    )
                  : _isLoadingTeams
                      // If teams are loading display loading indicator
                      ? const Center(child: CircularProgressIndicator())
                      // Else display text to join a team
                      : RefreshIndicator(
                          onRefresh: () async {
                            await _getTeams();
                          },
                          child: CustomScrollView(
                            slivers: <Widget>[
                              SliverFillRemaining(
                                child: Center(
                                  child: Text(
                                      "You have no teams! Join or create one first."),
                                ),
                              ),
                            ],
                          ),
                        ),

              // Iterate through list of invites, each being a card.
              // Update variables each time with: color, team name, num of
              // projects, and members list from database.
              _teamInvites.isNotEmpty
                  // If user has invites, display them
                  ? RefreshIndicator(
                      onRefresh: () async {
                        await _getInvites();
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.only(
                          left: 35,
                          right: 35,
                          top: 25,
                          bottom: 25,
                        ),
                        itemCount: _teamInvites.length,
                        itemBuilder: (BuildContext context, int index) {
                          return buildInviteCard(index);
                        },
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(
                          height: 25,
                        ),
                      ),
                    )
                  // Else if user does not have invites
                  : _isLoadingInvites
                      // If invites are loading, display loading indicator
                      ? const Center(child: CircularProgressIndicator())
                      // Else display text telling to refresh
                      : RefreshIndicator(
                          onRefresh: () async {
                            await _getInvites();
                          },
                          child: CustomScrollView(
                            slivers: <Widget>[
                              SliverFillRemaining(
                                child: Center(
                                  child: Text(
                                      "You have no invites! Pull down to refresh."),
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

  Container buildInviteCard(int index) {
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
                          text: _teamInvites[index].ownerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' has invited you to join: '),
                        TextSpan(
                          text: _teamInvites[index].title,
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
                        onPressed: () {
                          // Add to database
                          addUserToTeam(_teamInvites[index].id);
                          // Remove invite from screen
                          setState(() {
                            _teamInvites.removeWhere((team) =>
                                team.id.compareTo(_teamInvites[index].id) == 0);
                            teamsCount = _teamInvites.length;
                          });
                        },
                      ),
                      IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Decline invitation',
                          color: Colors.white,
                          onPressed: () {
                            // Remove invite from database
                            removeInviteFromUser(_teamInvites[index].id);
                            // Remove invite from screen
                            setState(() {
                              _teamInvites.removeWhere((team) =>
                                  team.id.compareTo(_teamInvites[index].id) ==
                                  0);
                              teamsCount = _teamInvites.length;
                            });
                          }),
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

  Container buildContainer({
    required int index,
    required Color color,
    required int numProjects,
    required Team team,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      height: 200,
      child: Row(
        children: <Widget>[
          InkWell(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 10.0, bottom: 10.0, right: 5.0, top: 5.0),
                child: Tooltip(
                  message: "Select team",
                  child: selectedIndex == index
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
            onTap: () async {
              await _firestore
                  .collection('users')
                  .doc(_loggedInUser?.uid)
                  .update({
                'selectedTeam': _firestore.doc('/teams/${team.id}'),
              });
              setState(() {
                selectedIndex = index;
              });
              // Debugging print statement:
              // print("Index: $index, Title: ${teams[index].title}");
            },
          ),
          const CircleAvatar(
            radius: 35,
          ),
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
                        text: '$numProjects ',
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
              onPressed: () async {
                final bool? doRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TeamSettingsPage(activeTeam: team)),
                );
                if (doRefresh == true) _getTeams();
                setState(() {
                  // Just in case something changed.
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
