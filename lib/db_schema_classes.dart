import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/google_maps_functions.dart';
import 'package:p2bp_2025spring_mobile/lighting_profile_test.dart';
import 'package:p2bp_2025spring_mobile/section_cutter_test.dart';
import 'firestore_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

import 'identifying_access_test.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// User class for create_project_and_teams.dart
class Member {
  String userID = '';
  String fullName = '';
  bool invited = false;

  Member({required this.userID, required this.fullName, this.invited = false});
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
  List<DocumentReference> testRefs = [];
  List<Test>? tests;
  List standingPoints = [];

  Project({
    this.creationTime,
    required this.teamRef,
    required this.projectID,
    required this.title,
    required this.description,
    required this.polygonPoints,
    required this.polygonArea,
    required this.standingPoints,
    required this.testRefs,
    this.tests,
  });

  // TODO: Eventually add Team Photo and Team Color
  Project.partialProject({required this.title, required this.description});

  /// Gets all fields for each [Test] in this [Project] and loads them
  /// into the [tests]. Also returns [tests].
  Future<List<Test>> loadAllTestData() async {
    List<Test> tests = [];
    for (final ref in testRefs) {
      if (ref is DocumentReference<Map<String, dynamic>>) {
        tests.add(await getTestInfo(ref));
      }
    }
    this.tests = tests;
    return tests;
  }
}

/// Parent class extended by every specific test class.
///
/// Each specific test will most likely have a different format for data
/// which needs to be specified around the implementation and used in place
/// of generic type [T] in each subclass.
///
/// Additionally, each subclass is expected to statically define constants
/// for the associated collection ID in Firestore and the basic structure
/// used for that test's [data] for initialization.
abstract class Test<T> {
  /// The time this [Test] was initially created at.
  late Timestamp creationTime;

  String title = '';
  String testID = '';

  /// The time scheduled for this test to be completed.
  ///
  /// For most tests this is the time that the test should be completed at
  /// but for some like 'Section cutter' and 'Identify programs' it is more
  /// like a deadline for the latest it should be completed by.
  Timestamp scheduledTime;

  /// The [DocumentReference] pointing to the project in which this [Test]
  /// resides.
  DocumentReference? projectRef;

  /// Maximum researchers that can complete this test.
  ///
  /// Currently always 1.
  late int maxResearchers;

  /// Instance member using custom data type for each specific test
  /// implementation for storing test data.
  ///
  /// Initial framework for storing data for each test should be defined in
  /// each implementation as the value returned from
  /// `getInitialDataStructure()`, as this is used for initializing `data`
  /// when it is not defined in the constructor.
  T data;

  /// The collection ID used in Firestore for this specific test.
  ///
  /// Each implementation of [Test] should statically define its
  /// collection ID for comparison against this field in
  /// factory constructors and other use cases.
  late final String collectionID;

  /// Whether this test has been completed by a surveyor yet.
  bool isComplete = false;

  /// Creates a new [Test] instance from the given arguments.
  ///
  /// Used for all creation of [Test] subclasses through super-constructor
  /// calls through factory constructors, so all logic for when certain
  /// values are not provided should be here.
  ///
  /// This is private because the only intended usage is through various
  /// public methods acting as factory constructors.
  Test._({
    required this.title,
    required this.testID,
    required this.scheduledTime,
    required this.projectRef,
    required this.collectionID,
    required this.data,
    Timestamp? creationTime,
    int? maxResearchers,
    bool? isComplete,
  }) {
    this.creationTime = creationTime ?? Timestamp.now();
    this.maxResearchers = maxResearchers ?? 1;
    this.isComplete = isComplete ?? false;
  }

  // The below Maps must have values registered for each subclass of Test.
  // Thus each subclass should have a method `static void register()`
  // which adds the appropriate values to each Map.

  /// Maps from the collection ID of each [Test] subclass to a function
  /// which should use a constructor of that [Test] type to make a new instance
  /// of said [Test].
  static final Map<
      String,
      Test Function({
        required String title,
        required String testID,
        required Timestamp scheduledTime,
        required DocumentReference projectRef,
        required String collectionID,
      })> _newTestConstructors = {};

  /// Maps from collection ID to a function which should use a constructor
  /// to make and return a [Test] object from the existing information
  /// given in [testDoc].
  static final Map<String,
          Test Function(DocumentSnapshot<Map<String, dynamic>>)>
      _recreateTestConstructors = {};

  /// Maps from a [Type] assumed to be a subclass of [Test] to the page
  /// for completing that [Test].
  static final Map<Type, Widget Function(Project, Test)> _pageBuilders = {};

  /// Maps from [Type] assumed to extend [Test] to the function used to
  /// save that [Test] instance to Firestore.
  static final Map<Type, void Function(Test)> _saveToFirestoreFunctions = {};

  /// Returns a new instance of the [Test] subclass associated with
  /// [collectionID].
  ///
  /// This acts as a factory constructor and is intended to be used for
  /// any newly created tests.
  ///
  /// Utilizes values registered to [Test._newTestConstructors].
  static Test createNew({
    required String title,
    required String testID,
    required Timestamp scheduledTime,
    required DocumentReference projectRef,
    required String collectionID,
  }) {
    final constructor = _newTestConstructors[collectionID];
    if (constructor != null) {
      return constructor(
        title: title,
        testID: testID,
        scheduledTime: scheduledTime,
        projectRef: projectRef,
        collectionID: collectionID,
      );
    }
    throw Exception('Unregistered Test type for collection: $collectionID');
  }

  /// Returns a new instance of the [Test] subclass appropriate for the
  /// given [testDoc] based on the collection it is from.
  ///
  /// This acts as a factory constructor for tests which already exist in
  /// Firestore.
  ///
  /// Utilizes values registered to [Test._recreateTestConstructors].
  static Test recreateFromDoc(DocumentSnapshot<Map<String, dynamic>> testDoc) {
    final constructor = _recreateTestConstructors[testDoc.reference.parent.id];
    if (constructor != null) {
      return constructor(testDoc);
    }
    throw Exception(
        'Unregistered Test type for collection: ${testDoc.reference.parent.id}');
  }

  /// Returns the [Widget] of the page used to complete this type of [Test]
  /// with the given [Test] and [Project] parameters already given.
  ///
  /// Basically when you want to navigate to [Test] completion page just use
  /// `test.getPage(project)` as the page given to a Navigator function.
  Widget getPage(Project project) {
    final pageBuilder = _pageBuilders[runtimeType];
    if (pageBuilder != null) {
      return pageBuilder(project, this);
    }
    throw Exception('No registered page for test type: $runtimeType');
  }

  void saveToFirestore() {
    final saveFunction = _saveToFirestoreFunctions[runtimeType];
    if (saveFunction != null) {
      return saveFunction(this);
    }
    throw Exception(
        'No registered saveToFirestore function for test type: $runtimeType');
  }

  @override
  String toString() {
    return 'This is an instance of $runtimeType\n'
        'title: ${this.title}\n'
        'testID: ${this.testID}\n'
        'scheduledTime: ${this.scheduledTime}\n'
        'projectRef: ${this.projectRef}\n'
        'collectionID: ${this.collectionID}\n'
        'data: ${this.data}\n'
        'creationTime: ${this.creationTime}\n'
        'maxResearchers: ${this.maxResearchers}\n'
        'isComplete: ${this.isComplete}\n';
  }

  /// Uploads the data from a completed test to Firestore.
  ///
  /// Used on completion of a test and should be passed all data
  /// collected throughout the duration of the test.
  ///
  /// Updates this test instance in Firestore with
  /// this new data and marks the test as complete; `isComplete = true`.
  /// This will need to change if more than 1 researcher is allowed per test.
  void submitData(T data);
}

/// Types of light for lighting profile test.
enum LightType { rhythmic, building, task }

// Author's note: I hate the names I used for both of these typedefs but I've
// already changed it/them so many times and I still cannot think of a better
// or shorter naming scheme for them so it is what it is.
/// Convenience alias for `LightingProfileTest` format used for `data`
/// locally (in Flutter/Dart).
typedef LightToLatLngMap = Map<LightType, Set<LatLng>>;

/// Convenience alias for `LightingProfileTest` format used for `data`
/// retrieved from Firestore.
typedef StringToGeoPointMap = Map<String, List<GeoPoint>>;

/// Class for lighting profile test info and methods.
class LightingProfileTest extends Test<LightToLatLngMap> {
  /// Returns a new instance of the initial data structure used for
  /// Lighting Profile Test.
  ///
  /// Initial data structure needs to be setup similar to this as
  /// just assigning a Map normally assigns by reference and will
  /// either overwrite the variable holding that initial structure
  /// or throw an Exception because you attempted to modify an
  /// immutable value if it was const.
  static LightToLatLngMap newInitialDataDeepCopy() {
    LightToLatLngMap newInitial = {};
    newInitial[LightType.rhythmic] = <LatLng>{};
    newInitial[LightType.building] = <LatLng>{};
    newInitial[LightType.task] = <LatLng>{};
    return newInitial;
  }

  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'lighting_profile_tests';

  /// Creates a new [LightingProfileTest] instance from the given arguments.
  ///
  /// This is private because the intended usage of this is through the
  /// 'factory constructor' in [Test] via [Test]'s various static methods
  /// imitating factory constructors.
  LightingProfileTest._({
    required super.title,
    required super.testID,
    required super.scheduledTime,
    required super.projectRef,
    required super.collectionID,
    required super.data,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
  }) : super._();

  /// Registers this class within the Maps required by class [Test].
  static void register() {
    // Register for creating new Lighting Profile Tests
    Test._newTestConstructors[collectionIDStatic] = ({
      required String title,
      required String testID,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      required String collectionID,
    }) =>
        LightingProfileTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: newInitialDataDeepCopy(),
        );
    // Register for recreating a Lighting Profile Test from Firestore
    Test._recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return LightingProfileTest._(
        title: testDoc['title'],
        testID: testDoc['id'],
        scheduledTime: testDoc['scheduledTime'],
        projectRef: testDoc['project'],
        collectionID: testDoc.reference.parent.id,
        data: convertDataFromFirestore(testDoc['data']),
        creationTime: testDoc['creationTime'],
        maxResearchers: testDoc['maxResearchers'],
        isComplete: testDoc['isComplete'],
      );
    };
    // Register for building a Lighting Profile Test page
    Test._pageBuilders[LightingProfileTest] =
        (project, test) => LightingProfileTestPage(
              activeProject: project,
              activeTest: test as LightingProfileTest,
            );
    // Register a function for saving to Firestore
    Test._saveToFirestoreFunctions[LightingProfileTest] = (test) async {
      await _firestore.collection(test.collectionID).doc(test.testID).set({
        'title': test.title,
        'id': test.testID,
        'scheduledTime': test.scheduledTime,
        'project': test.projectRef,
        'data': convertDataToFirestore(test.data),
        'creationTime': test.creationTime,
        'maxResearchers': test.maxResearchers,
        'isComplete': false,
      }, SetOptions(merge: true));
    };
  }

  @override
  void submitData(LightToLatLngMap data) async {
    try {
      // Adds all points of each type from submitted data to overall data
      StringToGeoPointMap firestoreData = convertDataToFirestore(data);

      // Updates data in Firestore
      await _firestore.collection(collectionID).doc(testID).update({
        'data': firestoreData,
        'isComplete': true,
      });

      this.data = data;
      isComplete = true;

      print(
          'Success! In LightingProfileTest.submitData. firestoreData = $firestoreData');
    } catch (e, stacktrace) {
      print("Exception in LightingProfileTest.submitData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  /// Transforms data retrieved from Firestore test instance to
  /// [LightToLatLngMap] for local manipulation.
  static LightToLatLngMap convertDataFromFirestore(Map<String, dynamic> data) {
    LightToLatLngMap output = newInitialDataDeepCopy();
    List<LightType> types = LightType.values;
    // Adds all data to output one type at a time
    for (final type in types) {
      if (data.containsKey(type.name)) {
        for (final GeoPoint geopoint in data[type.name]!) {
          output[type]?.add(geopoint.toLatLng());
        }
      }
    }
    return output;
  }

  /// Transforms data stored locally as [LightToLatLngMap] to
  /// Firestore format (represented by [StringToGeoPointMap])
  /// with String keys and any other needed changes.
  static StringToGeoPointMap convertDataToFirestore(LightToLatLngMap data) {
    StringToGeoPointMap output = {};
    List<LightType> types = LightType.values;
    for (final type in types) {
      output[type.name] = [];
      if (data.containsKey(type) && data[type] is Set) {
        for (final latlng in data[type]!) {
          output[type.name]?.add(latlng.toGeoPoint());
        }
      }
    }
    return output;
  }
}

/// Class for section cutter test info and methods.
class SectionCutterTest extends Test<Map<String, String>> {
  /// Default structure for Section Cutter test. Simply a [Map<String, String>],
  /// where the first string is the field and the second is the reference which
  /// refers to the path of the section drawing.
  static const Map<String, String> initialDataStructure = {"sectionLink": " "};
  static Map<String, String> newInitialDataDeepCopy() {
    Map<String, String> newInitial = {};
    newInitial['sectionLink'] = '';
    return newInitial;
  }

  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'section_cutter_tests';

  /// Creates a new [SectionCutterTest] instance from the given arguments.
  ///
  /// This is private because the intended usage of this is through the
  /// 'factory constructor' in [Test] via [Test]'s various static methods
  /// imitating factory constructors.
  SectionCutterTest._({
    required super.title,
    required super.testID,
    required super.scheduledTime,
    required super.projectRef,
    required super.collectionID,
    required super.data,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
  }) : super._();

  /// Registers this class within the Maps required by class [Test].
  static void register() {
    // Register for Map for Test.createNew
    Test._newTestConstructors[collectionIDStatic] = ({
      required String title,
      required String testID,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      required String collectionID,
    }) =>
        SectionCutterTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: newInitialDataDeepCopy(),
        );
    // Register for Map for Test.recreateFromDoc
    Test._recreateTestConstructors[collectionIDStatic] =
        (testDoc) => SectionCutterTest._(
              title: testDoc['title'],
              testID: testDoc['id'],
              scheduledTime: testDoc['scheduledTime'],
              projectRef: testDoc['project'],
              collectionID: testDoc.reference.parent.id,
              data: convertDataFromFirestore(testDoc['data']),
              creationTime: testDoc['creationTime'],
              maxResearchers: testDoc['maxResearchers'],
              isComplete: testDoc['isComplete'],
            );
    // Register for Map for Test.getPage
    Test._pageBuilders[SectionCutterTest] = (project, test) => SectionCutter(
          projectData: project,
          activeTest: test as SectionCutterTest,
        );
    // Register for Map for Test.saveToFirestore
    Test._saveToFirestoreFunctions[SectionCutterTest] = (test) async {
      await _firestore.collection(test.collectionID).doc(test.testID).set({
        'title': test.title,
        'id': test.testID,
        'scheduledTime': test.scheduledTime,
        'project': test.projectRef,
        'data': test.data,
        'creationTime': test.creationTime,
        'maxResearchers': test.maxResearchers,
        'isComplete': false,
      }, SetOptions(merge: true));
    };
  }

  @override
  void submitData(Map<String, String> data) async {
    try {
      // Updates data in Firestore
      await _firestore.collection(collectionID).doc(testID).update({
        'data': data,
        'isComplete': true,
      });

      this.data = data;
      isComplete = true;

      print('Success! In SectionCutterTest.submitData. firestoreData = $data');
    } catch (e, stacktrace) {
      print("Exception in SectionCutterTest.submitData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  /// Saves given [XFile]. Takes in the given data and saves it according to
  /// its corresponding project reference, under its given test id. Then,
  /// returns a [Map] where the path to the file is mapped to "sectionLink".
  Future<Map<String, String>> saveXFile(XFile data) async {
    Map<String, String> storageLocation = newInitialDataDeepCopy();
    try {
      if (projectRef == null) return storageLocation;
      final storageRef = FirebaseStorage.instance.ref();
      final sectionRef = storageRef.child(
          "project_uploads/${projectRef?.id}/section_cutter_files/$testID");
      final File sectionFile = File(data.path);

      print(sectionRef.fullPath);
      storageLocation = {"sectionLink": sectionRef.fullPath};
      await sectionRef.putFile(sectionFile);
    } catch (e, stacktrace) {
      print("Error in SectionCutterTest.saveXFile(): $e");
      print("Stacktrace: $stacktrace");
    }

    return storageLocation;
  }

  static Map<String, String> convertDataFromFirestore(
      Map<String, dynamic> data) {
    Map<String, String> output = newInitialDataDeepCopy();
    if (data.containsKey('sectionLink') && data['sectionLink'] is String) {
      output['sectionLink'] = data['sectionLink'];
    }
    return output;
  }
}

/// Enum types for Identifying Access test:
/// [bikeRack], [taxiAndRideShare], [parking], or [transportStation]
enum AccessType { bikeRack, taxiAndRideShare, parking, transportStation }

List<Object> accessObjects = [
  List<BikeRack>,
  List<TaxiAndRideShare>,
  List<Parking>,
  List<TransportStation>
];

// Realistically, these should all inherit from a parent class that has certain
// constants, such as width, color, and cap. Also have an abstract method for
// converting to Firestore.
/// Bike rack type for Identifying Access test. Enum type [bikeRack].
class BikeRack {
  static const AccessType type = AccessType.bikeRack;
  static const int polylineWidth = 3;
  static const Color color = Colors.black;
  static const Cap startCap = Cap.roundCap;
  final int spots;
  final Polyline polyline;
  final double pathLength;

  BikeRack({required this.spots, required this.polyline})
      : pathLength = mp.SphericalUtil.computeLength(polyline.toMPLatLngList())
            .toDouble();

  Map<String, dynamic> convertToFirestoreData() {
    Map<String, dynamic> firestoreData = {
      'spots': spots,
      'pathInfo': {
        'path': polyline.points.toGeoPointList(),
        'pathLength': pathLength,
      }
    };
    return firestoreData;
  }
}

/// Taxi/ride share type for Identifying Access test. Enum type
/// [taxiAndRideShare].
class TaxiAndRideShare {
  static const AccessType type = AccessType.taxiAndRideShare;
  static const int polylineWidth = 3;
  static const Color color = Colors.black;
  static const Cap startCap = Cap.roundCap;
  final Polyline polyline;
  final double pathLength;

  TaxiAndRideShare({required this.polyline})
      : pathLength = mp.SphericalUtil.computeLength(polyline.toMPLatLngList())
            .toDouble();

  Map<String, dynamic> convertToFirestoreData() {
    Map<String, dynamic> firestoreData = {
      'pathInfo': {
        'path': polyline.points.toGeoPointList(),
        'pathLength': pathLength
      }
    };
    return firestoreData;
  }
}

/// Parking type for Identifying Access test. Enum type [parking].
class Parking {
  static const AccessType type = AccessType.parking;
  static const int polylineWidth = 3;
  static const Color color = Colors.black;
  static const Cap startCap = Cap.roundCap;
  final int spots;
  final Polygon polygon;
  final Polyline polyline;
  final double pathLength;
  final double polygonArea;

  Parking({required this.spots, required this.polyline, required this.polygon})
      : pathLength = mp.SphericalUtil.computeLength(polyline.toMPLatLngList())
            .toDouble(),
        polygonArea = (mp.SphericalUtil.computeArea(polygon.toMPLatLngList()) *
                pow(feetPerMeter, 2))
            .toDouble();

  Map<String, dynamic> convertToFirestoreData() {
    Map<String, dynamic> firestoreData = {
      'spots': spots,
      'pathInfo': {
        'path': polyline.points.toGeoPointList(),
        'pathLength': pathLength,
      },
      'polygonInfo': {
        'polygon': polygon.points.toGeoPointList(),
        'polygonArea': pathLength,
      }
    };
    return firestoreData;
  }
}

/// Transport station type for Identifying Access test. Enum type
/// [transportStation].
class TransportStation {
  static const AccessType type = AccessType.transportStation;
  static const int polylineWidth = 3;
  static const Color color = Colors.black;
  static const Cap startCap = Cap.roundCap;
  final int routeNumber;
  final Polyline polyline;
  final double pathLength;

  TransportStation({required this.routeNumber, required this.polyline})
      : pathLength = mp.SphericalUtil.computeLength(polyline.toMPLatLngList())
            .toDouble();

  Map<String, dynamic> convertToFirestoreData() {
    Map<String, dynamic> firestoreData = {
      'routeNumber': routeNumber,
      'pathInfo': {
        'path': polyline.points.toGeoPointList(),
        'pathLength': pathLength,
      }
    };
    return firestoreData;
  }
}

/// Class for identifying access test info and methods.
class IdentifyingAccessTest extends Test<Map> {
  /// Returns a new instance of the initial data structure used for
  /// Identifying Access Test.
  static Map<AccessType, List> newInitialDataDeepCopy() {
    Map<AccessType, List> accessData = {};
    accessData[AccessType.bikeRack] = [];
    accessData[AccessType.taxiAndRideShare] = [];
    accessData[AccessType.transportStation] = [];
    accessData[AccessType.parking] = [];
    return accessData;
  }

  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'identifying_access_tests';

  /// Creates a new [IdentifyingAccessTest] instance from the given arguments.
  IdentifyingAccessTest._({
    required super.title,
    required super.testID,
    required super.scheduledTime,
    required super.projectRef,
    required super.collectionID,
    required super.data,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
  }) : super._();

  /// Registers this class within the Maps required by class [Test].
  static void register() {
    // Register for creating new Lighting Profile Tests
    Test._newTestConstructors[collectionIDStatic] = ({
      required String title,
      required String testID,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      required String collectionID,
    }) =>
        IdentifyingAccessTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: newInitialDataDeepCopy(),
        );
    // Register for recreating a Lighting Profile Test from Firestore
    Test._recreateTestConstructors[collectionIDStatic] = (testDoc) {
      print(testDoc['data']);
      return IdentifyingAccessTest._(
        title: testDoc['title'],
        testID: testDoc['id'],
        scheduledTime: testDoc['scheduledTime'],
        projectRef: testDoc['project'],
        collectionID: testDoc.reference.parent.id,
        data: convertDataFromFirestore(testDoc['data']),
        creationTime: testDoc['creationTime'],
        maxResearchers: testDoc['maxResearchers'],
        isComplete: testDoc['isComplete'],
      );
    };
    // Register for building a Lighting Profile Test page
    Test._pageBuilders[IdentifyingAccessTest] =
        (project, test) => IdentifyingAccess(
              activeProject: project,
              activeTest: test as IdentifyingAccessTest,
            );
    // Register a function for saving to Firestore
    Test._saveToFirestoreFunctions[IdentifyingAccessTest] = (test) async {
      await _firestore.collection(test.collectionID).doc(test.testID).set({
        'title': test.title,
        'id': test.testID,
        'scheduledTime': test.scheduledTime,
        'project': test.projectRef,
        'data': convertDataToFirestore(test.data),
        'creationTime': test.creationTime,
        'maxResearchers': test.maxResearchers,
        'isComplete': false,
      }, SetOptions(merge: true));
    };
  }

  @override
  void submitData(Map data) async {
    // Adds all points of each type from submitted data to overall data
    Map firestoreData = convertDataToFirestore(data);

    // Updates data in Firestore
    await _firestore.collection(collectionID).doc(testID).update({
      'data': firestoreData,
      'isComplete': true,
    });

    this.data = data;
    isComplete = true;

    print(
        'Success! In IdentifyingAccessTest.submitData. firestoreData = $firestoreData');
  }

  /// Transforms data retrieved from Firestore test instance to
  /// a list of AccessType objects, with data accessed through the fields of
  /// the respective objects.
  static Map<AccessType, dynamic> convertDataFromFirestore(
      Map<String, dynamic> data) {
    Map<AccessType, dynamic> output = newInitialDataDeepCopy();
    List<AccessType> types = AccessType.values;
    List dataList;
    // Adds all data to output one type at a time
    for (final type in types) {
      output[type] = [];
      if (data.containsKey(type.name)) {
        dataList = data[type.name];
        switch (type) {
          case AccessType.bikeRack:
            for (Map bikeRackMap in dataList) {
              if (bikeRackMap.containsKey('pathInfo') &&
                  bikeRackMap['pathInfo'].containsKey('path')) {
                List polylinePoints = bikeRackMap['pathInfo']['path'];
                output[type]?.add(
                  BikeRack(
                    spots: bikeRackMap['spots'],
                    polyline: Polyline(
                      polylineId: PolylineId(
                          DateTime.now().millisecondsSinceEpoch.toString()),
                      color: BikeRack.color,
                      width: BikeRack.polylineWidth,
                      startCap: BikeRack.startCap,
                      points: polylinePoints.toLatLngList(),
                    ),
                  ),
                );
              }
            }
          case AccessType.taxiAndRideShare:
            for (Map taxiRideShareMap in dataList) {
              if (taxiRideShareMap.containsKey('pathInfo') &&
                  taxiRideShareMap['pathInfo'].containsKey('path')) {
                List polylinePoints = taxiRideShareMap['pathInfo']['path'];
                output[type]?.add(
                  TaxiAndRideShare(
                    polyline: Polyline(
                      polylineId: PolylineId(
                          DateTime.now().millisecondsSinceEpoch.toString()),
                      color: TaxiAndRideShare.color,
                      width: TaxiAndRideShare.polylineWidth,
                      startCap: TaxiAndRideShare.startCap,
                      points: polylinePoints.toLatLngList(),
                    ),
                  ),
                );
              }
            }
          case AccessType.parking:
            for (Map parkingMap in dataList) {
              if ((parkingMap.containsKey('pathInfo') &&
                      parkingMap['pathInfo'].containsKey('path')) &&
                  (parkingMap.containsKey('polygonInfo') &&
                      parkingMap['polygonInfo'].containsKey('polygon'))) {
                List polylinePoints = parkingMap['pathInfo']['path'];
                List polygonPoints = parkingMap['polygonInfo']['polygon'];
                output[type]?.add(
                  Parking(
                    spots: parkingMap['spots'],
                    polyline: Polyline(
                        polylineId: PolylineId(
                            DateTime.now().millisecondsSinceEpoch.toString()),
                        color: Parking.color,
                        width: Parking.polylineWidth,
                        startCap: Parking.startCap,
                        points: polylinePoints.toLatLngList()),
                    polygon: Polygon(
                      polygonId: PolygonId(
                          DateTime.now().millisecondsSinceEpoch.toString()),
                      points: polygonPoints.toLatLngList(),
                      fillColor: Color(0x55999999),
                    ),
                  ),
                );
              }
            }
          case AccessType.transportStation:
            for (Map transportStationMap in dataList) {
              if (transportStationMap.containsKey('pathInfo') &&
                  transportStationMap['pathInfo'].containsKey('path')) {
                List polylinePoints = transportStationMap['pathInfo']['path'];
                output[type]?.add(
                  TransportStation(
                    routeNumber: transportStationMap['routeNumber'],
                    polyline: Polyline(
                        polylineId: PolylineId(
                            DateTime.now().millisecondsSinceEpoch.toString()),
                        color: TransportStation.color,
                        width: TransportStation.polylineWidth,
                        startCap: TransportStation.startCap,
                        points: polylinePoints.toLatLngList()),
                  ),
                );
              }
            }
        }
      }
    }
    return output;
  }

  /// Transforms data stored locally as of [List] access type objects to
  /// Firestore format (represented by a [Map])
  /// with String keys and any other needed changes.
  static Map<String, List> convertDataToFirestore(Map data) {
    Map<String, List> output = {};
    List<AccessType> types = AccessType.values;
    for (final type in types) {
      output[type.name] = [];
      // && accessObjects.contains(data[type].runtimeType)
      if (data.containsKey(type)) {
        switch (type) {
          case AccessType.bikeRack:
            for (BikeRack accessObject in data[type]!) {
              output[type.name]?.add(accessObject.convertToFirestoreData());
            }
          case AccessType.taxiAndRideShare:
            for (TaxiAndRideShare accessObject in data[type]!) {
              output[type.name]?.add(accessObject.convertToFirestoreData());
            }
          case AccessType.parking:
            for (Parking accessObject in data[type]!) {
              output[type.name]?.add(accessObject.convertToFirestoreData());
            }
          case AccessType.transportStation:
            for (TransportStation accessObject in data[type]!) {
              output[type.name]?.add(accessObject.convertToFirestoreData());
            }
        }
      }
    }
    return output;
  }
}
