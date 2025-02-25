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

/// Parent class extended by every specific test class.
///
/// Each specific test will most likely have a different format for data
/// which needs to be specified around the implementation and used in place
/// of generic type `T` in each implementation.
abstract class Test<T> {
  Timestamp? creationTime;
  String title = '';
  String testID = '';

  /// The time scheduled for this test to be completed.
  ///
  /// For most tests this is the time that the test should be completed at
  /// but for some like 'Section cutter' and 'Identify programs' it is more
  /// like a deadline for the latest it should be completed by.
  Timestamp scheduledTime;
  DocumentReference? projectRef;

  /// Maximum researchers that can complete this test.
  ///
  /// Currently always 1.
  int maxResearchers = 1;

  /// Whether this test has been completed by a surveyor yet.
  bool isComplete = false;

  /// Instance member using custom data type for each specific test
  /// implementation for storing test data.
  ///
  /// Initial framework for storing data for each test should be defined in
  /// each implementation as the value returned from
  /// `getInitialDataStructure()`, as this is used for initializing `data`
  /// when it is not defined in the constructor.
  late T data;

  /// The collection ID used in Firestore for this specific test.
  ///
  /// This should be innately initialized to [getCollectionID] in all
  /// constructors, which itself needs to be defined in each implementation,
  /// likely just returning a static constant value.
  late final String collectionID;

  /// Creates a new test instance from scratch.
  ///
  /// Used when creating a brand new test
  /// which then needs to be inserted in Firestore.
  ///
  /// `creationTime` and `data` are automatically initialized
  /// correctly for a new test when not specified.
  ///
  /// This usage is primarily intended for when an admin
  /// is creating a new test and has manually specified all required
  /// parameters.
  Test.createNew({
    required this.title,
    required this.testID,
    required this.scheduledTime,
    required this.projectRef,
    this.creationTime,
    T? data,
  }) {
    this.creationTime ??= Timestamp.now();
    this.data = data ?? getInitialDataStructure();
    this.collectionID = getCollectionID();
  }

  /// Recreates a test instance based on the given `DocumentSnapshot`.
  ///
  /// This is intended to be used when surveyor chooses to complete a test.
  /// Once user has selected the option to complete test, the
  /// `DocumentSnapshot` is retrieved with `getTestInfo` from
  /// `firestore_functions.dart`. Then this constructor is used to create
  /// a test instance which is passed to `LightingProfileTestPage` when
  /// navigating there.
  Test.recreateFromDoc(DocumentSnapshot<Map<String, dynamic>> testDoc)
      : title = testDoc['title'],
        testID = testDoc['id'],
        scheduledTime = testDoc['scheduledTime'],
        projectRef = testDoc['project'],
        maxResearchers = testDoc['maxResearchers'],
        creationTime = testDoc['creationTime'] {
    data = convertDataFromDoc(testDoc['data']);
    collectionID = getCollectionID();
  }

  /// Returns the initial state for `data`.
  ///
  /// Used to initialize `data` when no value is provided.
  ///
  /// This must be defined in each implementation and likely will just
  /// return a static constant value hard-coded for each test in real
  /// implementations.
  T getInitialDataStructure();

  /// Returns the value for `collectionID`.
  ///
  /// Used to initialize collectionID, which is constant for each
  /// specific test type but must be overwritten in every implementation
  /// to return the actual collection ID used for that test.
  String getCollectionID() {
    return '';
  }

  /// Returns value for `data` field after converting from type used in
  /// Firestore document.
  ///
  /// This will need to be different for each test and likely will just
  /// call a static method in the implementing class which contains the real
  /// functionality.
  T convertDataFromDoc(dynamic data);

  /// Uploads the data from a completed test to Firestore.
  ///
  /// Used on completion of a test and should be passed all data
  /// collected throughout the duration of the test.
  ///
  /// Updates this test instance in Firestore with
  /// this new data and marks the test as complete `isComplete = true`.
  /// This will need to change if more than 1 researcher is allowed per test.
  void submitData(T data);
}
