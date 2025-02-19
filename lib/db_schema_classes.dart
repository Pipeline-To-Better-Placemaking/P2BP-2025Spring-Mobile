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

/// Abstract superclass for all tests to be extended by each specific
/// test class.
///
/// Each specific test will most likely have a different format for data
/// which needs to be specified around the implementation and used in place
/// of generic type [A].
abstract class Test<A> {
  Timestamp? creationTime;
  String title = '';
  String testID = '';
  Timestamp? scheduledTime;
  DocumentReference? projectRef;
  int maxResearchers = 0;

  /// Instance member using custom data type for each specific test
  /// implementation for storing test data.
  ///
  /// Initial framework for storing data for each test should be defined in
  /// each implementation as the value returned from
  /// [_getInitialDataStructure()].
  /// This is then used to initialize data when it is not given, as this
  /// indicates creation of a new test as opposed to retrieval of an
  /// existing test.
  late A data;

  /// The collection ID used in Firestore for this specific test.
  ///
  /// Each implementation should initialize this at some point during
  /// construction, as well as duplicated to a static member ideally.
  late final String collectionID;

  /// Creates a new test instance. Private constructor as it is only intended
  /// to be called from subclass constructors. Each subclass internally
  /// provides argument for initialDataStructure.
  ///
  /// When creating a new test to be stored in the DB for the first time,
  /// include only the required parameters. [creationTime] and [data]
  /// are automatically initialized correctly for a new test when not given.
  /// This usage is primarily intended for when an admin
  /// is creating a new test and manually specified all relevant parameters.
  ///
  /// When retrieving an existing test from the DB, include arguments for every
  /// parameter. This should be trivial once the proper document has been
  /// retrieved.
  /// This usage is primarily intended for adding data from surveyor completing
  /// the test.
  Test({
    required this.title,
    required this.testID,
    required this.scheduledTime,
    required this.projectRef,
    required this.maxResearchers,
    this.creationTime,
    A? data,
  }) {
    this.creationTime ??= Timestamp.now();
    this.data = data ?? getInitialDataStructure();
  }

  /// Creates a new test instance from existing info from Firestore
  /// in the required [DocumentSnapshot].
  Test.makeFromDoc(DocumentSnapshot<Map<String, dynamic>> testDoc)
      : this(
          title: testDoc['title'],
          testID: testDoc['id'],
          scheduledTime: testDoc['scheduledTime'],
          projectRef: testDoc['project'],
          maxResearchers: testDoc['maxResearchers'],
          creationTime: testDoc['creationTime'],
        );

  /// Returns the initial state for [data] specific to each test
  /// implementation.
  ///
  /// Used in the constructor to define [data] when no value is provided.
  ///
  /// This must be setup in each implementation and likely will just
  /// return a static constant value hard-coded for each test.
  A getInitialDataStructure();

  /// Used on completion of a test and passed all data collected throughout
  /// the duration of the test. Updates this test instance in Firestore with
  /// this new data.
  void submitData(A data);

  Future<T?> getTestInfo<T extends Test>(
      String testID, String collectionID, Type testType) async {
    return null;
  }
}
