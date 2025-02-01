// User class for create_project_and_teams.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Member {
  String _userID = '';
  String _fullName = '';
  bool _invited = false;

  Member(
      {required String userID,
      required String fullName,
      bool invited = false}) {
    _userID = userID;
    _fullName = fullName;
    _invited = invited;
  }
  void setUserID(String userID) {
    _userID = userID;
  }

  void setFullName(String fullName) {
    _fullName = fullName;
  }

  void setInvited(bool invited) {
    _invited = invited;
  }

  String getUserID() {
    return _userID;
  }

  String getFullName() {
    return _fullName;
  }

  bool getInvited() {
    return _invited;
  }
}

// Team class for teams_and_invites_page.dart
class Team {
  Timestamp? creationTime;
  String adminName = '';
  String teamID = '';
  String title = '';
  // TODO: Change to contain user id and role.
  List teamMembers = [];

  Team({required this.teamID, required this.title, required this.adminName});
}

class Project {
  Timestamp? creationTime;
  String teamID = '';
  String projectID = '';
  String title = '';
  String description = '';
  List<GeoPoint> projectArea = [];
  // TODO: Change depending on implementation of tests.
  List<Test>? tests = [];

  Project(
      {this.creationTime,
      required this.teamID,
      required this.projectID,
      required this.title,
      required this.description,
      required this.projectArea,
      this.tests});

  // TODO: Eventually add Team Photo and Team Color
  Project.partialProject({required this.title, required this.description});
}

class Test {
  // TODO: Temporary until test is worked out
  String type = '';
}
