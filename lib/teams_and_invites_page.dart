import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'db_schema_classes.dart';
import 'team_settings_page.dart';
import 'theme.dart';

class TeamsAndInvitesPage extends StatefulWidget {
  final Member member;

  const TeamsAndInvitesPage({super.key, required this.member});

  @override
  State<TeamsAndInvitesPage> createState() => _TeamsAndInvitesPageState();
}

class _TeamsAndInvitesPageState extends State<TeamsAndInvitesPage> {
  bool _isLoadingTeams = true;
  bool _isLoadingInvites = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.member.selectedTeamRef != null) {
      _selectedIndex =
          widget.member.teamRefs.indexOf(widget.member.selectedTeamRef!);
    } else {
      _selectedIndex = -1;
    }
    if (widget.member.teams == null) {
      _getTeams();
    } else {
      widget.member.teams!;
      _isLoadingTeams = false;
    }
    if (widget.member.teamInvites == null) {
      _getInvites();
    } else {
      widget.member.teamInvites!;
      _isLoadingInvites = false;
    }
  }

  Future<void> _getTeams() async {
    try {
      await widget.member.loadTeamsInfo();

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
      await widget.member.loadTeamInvitesInfo();

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
                  child: widget.member.teams!.isNotEmpty
                      ? ListView.separated(
                          padding: const EdgeInsets.only(
                            left: 35,
                            right: 35,
                            top: 50,
                            bottom: 20,
                          ),
                          itemCount: widget.member.teams!.length,
                          itemBuilder: (context, index) {
                            return TeamCard(
                              team: widget.member.teams![index],
                              selected: _selectedIndex == index,
                              selectTeam: () async {
                                widget.member.selectedTeamRef =
                                    widget.member.teams![index].ref;
                                widget.member.selectedTeam =
                                    widget.member.teams![index];

                                setState(() {
                                  _selectedIndex = index;
                                });

                                await widget.member.update();
                              },
                              teamSettings: () async {
                                final bool? doRefresh = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TeamSettingsPage(
                                      member: widget.member,
                                      activeTeam: widget.member.teams![index],
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
                  child: widget.member.teamInvites!.isNotEmpty
                      ? ListView.separated(
                          padding: const EdgeInsets.only(
                            left: 35,
                            right: 35,
                            top: 25,
                            bottom: 25,
                          ),
                          itemCount: widget.member.teamInvites!.length,
                          itemBuilder: (BuildContext context, int index) {
                            final invite = widget.member.teamInvites![index];
                            return InviteCard(
                              invite: invite,
                              acceptInvite: () async {
                                invite.accept(widget.member);
                                setState(() {
                                  // Update visible invites after accept.
                                });
                              },
                              declineInvite: () {
                                invite.decline(widget.member);
                                setState(() {
                                  // Update visible invites after decline.
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
  final VoidCallback selectTeam;
  final VoidCallback teamSettings;

  const TeamCard({
    super.key,
    required this.team,
    required this.selected,
    required this.selectTeam,
    required this.teamSettings,
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
            onTap: selectTeam,
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
              onPressed: teamSettings,
            ),
          ),
        ],
      ),
    );
  }
}

class InviteCard extends StatelessWidget {
  final TeamInvite invite;
  final VoidCallback acceptInvite;
  final VoidCallback declineInvite;

  const InviteCard({
    super.key,
    required this.invite,
    required this.acceptInvite,
    required this.declineInvite,
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
                          text: invite.team.title,
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
                        onPressed: acceptInvite,
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Decline invitation',
                        color: Colors.white,
                        onPressed: declineInvite,
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
