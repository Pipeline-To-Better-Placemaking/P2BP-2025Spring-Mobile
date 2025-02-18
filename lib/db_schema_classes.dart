import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// User class for create_project_and_teams.dart
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
  List teamMembers = [];
  List projects = [];
  int numProjects = 0;

  Team(
      {required this.teamID,
      required this.title,
      required this.adminName,
      required this.projects,
      required this.numProjects});

  // Specifically for a team invite. Invite does not need numProjects, projects,
  // etc.
  Team.teamInvite({
    required this.teamID,
    required this.title,
    required this.adminName,
  });
}

// Project class for project creation (create project + map)
class Project {
  Timestamp? creationTime;
  DocumentReference? teamRef;
  String projectID = '';
  String title = '';
  String description = '';
  List polygonPoints = [];
  num polygonArea = 0;
  // TODO: Change depending on implementation of tests.
  List<Test>? tests = [];

  Project(
      {this.creationTime,
      required this.teamRef,
      required this.projectID,
      required this.title,
      required this.description,
      required this.polygonPoints,
      required this.polygonArea,
      this.tests});

  // TODO: Eventually add Team Photo and Team Color
  Project.partialProject({required this.title, required this.description});
}

/// Superclass (or interface, not sure which makes more sense yet)
/// for each specific test
abstract interface class Test<A, B> {
  Timestamp? creationTime;
  String title = '';
  String testID = '';
  Timestamp? scheduledTime;
  DocumentReference? projectRef;
  int maxResearchers = 0;
  Map<A, B> data = {};

  Test.create({
    required this.creationTime,
    required this.title,
    required this.testID,
    required this.scheduledTime,
    required this.projectRef,
    required this.maxResearchers,
  });

  /// Used on completion of a test and passed all data collected throughout
  /// the duration of the test. Updates this test instance in Firestore with
  /// this new data.
  void submitData(Map<A, B> data);
}

/// Types of light for lighting profile test.
enum LightType { rhythmic, building, task }

/// Schema for lighting profile test.
class LightingProfileTest extends Test<LightType, List<LatLng>> {
  LightingProfileTest.create({
    required super.creationTime,
    required super.title,
    required super.testID,
    required super.scheduledTime,
    required super.projectRef,
    required super.maxResearchers,
  }) : super.create() {
    data = {
      LightType.rhythmic: [],
      LightType.building: [],
      LightType.task: [],
    };
  }

  @override
  void submitData(Map<LightType, List<LatLng>> data) {
    // Adds all points of each type from submitted data to overall data
    for (final point in data[LightType.rhythmic]!) {
      this.data[LightType.rhythmic]?.add(point);
    }
    for (final point in data[LightType.building]!) {
      this.data[LightType.building]?.add(point);
    }
    for (final point in data[LightType.task]!) {
      this.data[LightType.task]?.add(point);
    }

    // TODO: Insert to/update in firestore
  }
}
