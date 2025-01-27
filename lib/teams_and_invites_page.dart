import 'package:flutter/material.dart';
import 'teams_settings_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeamsAndInvitesPage extends StatefulWidget {
  const TeamsAndInvitesPage({super.key});

  @override
  State<TeamsAndInvitesPage> createState() => _TeamsAndInvitesPageState();
}

class _TeamsAndInvitesPageState extends State<TeamsAndInvitesPage> {
  List teams = [];
  List invites = [];
  int itemCount = 0;
  int selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? loggedInUser = FirebaseAuth.instance.currentUser;

  List getTeamsIDs() {
    try {
      _firestore
          .collection("users")
          .doc(loggedInUser?.uid)
          .snapshots()
          .listen((result) {
        teams = result.data()?["teams"];
        print(teams);
      });
    } catch (e, stacktrace) {
      print('Exception retrieving teams: $e');
      print('Stacktrace: $stacktrace');
    }
    return teams;
  }

  List getInvites() {
    try {
      _firestore
          .collection("users")
          .doc(loggedInUser?.uid)
          .snapshots()
          .listen((result) {
        invites = result.data()?['invites'];
        print(invites);
      });
    } catch (e, stacktrace) {
      print('Exception retrieving teams: $e');
      print('Stacktrace: $stacktrace');
    }
    return invites;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              labelColor: Colors.blue,
              indicatorColor: Colors.blue,
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
              // TODO: steam for teams and invites? or either or neither?
              StreamBuilder<DocumentSnapshot>(
                  stream: _firestore
                      .collection("users")
                      .doc(loggedInUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    teams = getTeamsIDs();
                    if (!snapshot.hasData || teams.isEmpty) {
                      print("->${snapshot.data}");
                      return const Center(
                        child: Text(
                            'You have no teams! Join a team or create one first.'),
                      );
                    }
                    final userData = snapshot.data;
                    itemCount = teams.length;

                    return itemCount > 0
                        ? ListView.separated(
                            padding: const EdgeInsets.only(
                              left: 35,
                              right: 35,
                              top: 50,
                              bottom: 20,
                            ),
                            itemCount: itemCount,
                            itemBuilder: (BuildContext context, int index) {
                              return buildContainer(
                                  index: index,
                                  color: Colors.blue,
                                  numProjects: 12, //<-- TODO: edit
                                  teamName: 'PlaceHolder');
                            },
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const SizedBox(
                              height: 50,
                            ),
                          )
                        : Center(
                            child: Text(
                                "You have no teams! Join a team or create one first."),
                          );
                  }),

              // Iterate through list of projects, each being a card.
              // Update variables each time with: color, team name, num of
              // projects, and members list from database.
              StreamBuilder<Object>(
                  stream: _firestore
                      .collection("users")
                      .doc(loggedInUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    invites = getInvites();
                    if (!snapshot.hasData) {
                      print("->${snapshot.data}");
                      return const Center(
                        child: Text('You have no invites!'),
                      );
                    }
                    final userData = snapshot.data;
                    itemCount = invites.length;

                    return itemCount > 0
                        ? ListView.separated(
                            padding: const EdgeInsets.only(
                              left: 35,
                              right: 35,
                              top: 25,
                              bottom: 25,
                            ),
                            itemCount: itemCount,
                            itemBuilder: (BuildContext context, int index) {
                              return const InviteCard(
                                color: Colors.blue,
                                name: 'Placeholder',
                                teamName: 'Placeholder',
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const SizedBox(
                              height: 25,
                            ),
                          )
                        : const Center(child: Text('You have no invites!'));
                  })
            ],
          ),
        ),
      ),
    );
  }

  Container buildContainer(
      {required int index,
      required Color color,
      required int numProjects,
      required String teamName}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      height: 200,
      child: Row(
        children: <Widget>[
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 10.0, bottom: 10.0, right: 5.0, top: 5.0),
              child: Tooltip(
                message: "Select team",
                child: InkWell(
                  child: selectedIndex == index
                      ? const Icon(Icons.radio_button_on)
                      : const Icon(Icons.radio_button_off),
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                ),
              ),
            ),
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
                        text: teamName,
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
              onPressed: () {
                // TODO: Actual function
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TeamSettingsScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class InviteCard extends StatelessWidget {
  final Color color;
  final String name;
  final String teamName;
  // TODO: final List<Members> members; (for cover photo, not implemented yet)

  const InviteCard({
    super.key,
    required this.color,
    required this.name,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
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
          Flexible(
            child: Stack(
              children: <Widget>[
                Center(
                  child: Text.rich(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    TextSpan(
                      children: [
                        TextSpan(
                          text: name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' has invited you to join: '),
                        TextSpan(
                          text: teamName,
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
                          // TODO: Actual function
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Deny invitation',
                        color: Colors.white,
                        onPressed: () {
                          // TODO: Actual function
                        },
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
