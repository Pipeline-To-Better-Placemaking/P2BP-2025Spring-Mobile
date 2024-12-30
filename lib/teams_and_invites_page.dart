import 'package:flutter/material.dart';

class TeamsAndInvitesPage extends StatefulWidget {
  const TeamsAndInvitesPage({super.key});

  @override
  State<TeamsAndInvitesPage> createState() => _TeamsAndInvitesPageState();
}

class _TeamsAndInvitesPageState extends State<TeamsAndInvitesPage> {
  List<int> items = [1, 2, 3, 4, 5];
  int itemCount = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Teams'),
                Tab(text: 'Invites'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              itemCount > 0
                  ? ListView.separated(
                      padding: const EdgeInsets.only(
                          left: 35, right: 35, top: 50, bottom: 20),
                      itemCount: itemCount,
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                          height: 200,
                          child: const Row(
                            children: <Widget>[
                              CircleAvatar(
                                radius: 35,
                              ),
                              Column(
                                children: <Widget>[
                                  Text('Team: \$team_name'),
                                  Text('\$num_of_projects projects'),
                                  Row(
                                    children: [
                                      Text('Members: '),
                                    ],
                                  )
                                ],
                              ),
                              Icon(Icons.chevron_right),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(
                        height: 50,
                      ),
                    )
                  : const Center(
                      child: Text(
                          'You have no teams! Join a team or create one first.')),
              itemCount > 0
                  ? ListView.separated(
                      padding: const EdgeInsets.only(
                        left: 35,
                        right: 35,
                        top: 25,
                        bottom: 25,
                      ),
                      itemCount: itemCount,
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                          height: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              const SizedBox(width: 15),
                              const CircleAvatar(
                                radius: 25,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Flexible(
                                      child: Text(
                                          '\$name has invited you to join: \$project_name'),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: <Widget>[
                                        IconButton(
                                          icon: const Icon(Icons.check),
                                          tooltip: 'Accept invitation',
                                          onPressed: () {
                                            // TODO: Actual function
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.clear),
                                          tooltip: 'Deny invitation',
                                          onPressed: () {
                                            // TODO: Actual function
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(
                        height: 25,
                      ),
                    )
                  : const Center(child: Text('You have no invites!')),
            ],
          ),
        ),
      ),
    );
  }
}
