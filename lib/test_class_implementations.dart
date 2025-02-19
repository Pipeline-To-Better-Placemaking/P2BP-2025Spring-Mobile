import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'db_schema_classes.dart';

/// Types of light for lighting profile test.
enum LightType { rhythmic, building, task }

/// Convenience alias for [LightingProfileTest] [data] format used locally
/// (in Flutter/Dart).
typedef LightToLatLngMap = Map<LightType, Set<LatLng>>;

/// Convenience alias for [LightingProfileTest] [data] format when
/// retrieved from Firestore.
typedef LightToGeoPointMap = Map<String, List<GeoPoint>>;

/// Class for lighting profile test.
class LightingProfileTest extends Test<LightToLatLngMap> {
  /// Hard-coded definition of basic structure for [data]
  /// used for initialization of new lighting tests.
  static const LightToLatLngMap initialDataStructure = {
    LightType.rhythmic: {},
    LightType.building: {},
    LightType.task: {},
  };

  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'lighting_profile_test';

  LightingProfileTest({
    required super.title,
    required super.testID,
    required super.scheduledTime,
    required super.projectRef,
    required super.maxResearchers,
    super.creationTime,
    super.data,
  }) {
    super.collectionID = collectionIDStatic;
  }

  LightingProfileTest.makeFromDoc(
    DocumentSnapshot<Map<String, dynamic>> testDoc,
  ) : this(
          title: testDoc['title'],
          testID: testDoc['id'],
          scheduledTime: testDoc['scheduledTime'],
          projectRef: testDoc['project'],
          maxResearchers: testDoc['maxResearchers'],
          creationTime: testDoc['creationTime'],
          data: LightingProfileTest.convertDataFromFirestore(testDoc['data']),
        );

  @override
  LightToLatLngMap getInitialDataStructure() {
    return initialDataStructure;
  }

  @override
  void submitData(LightToLatLngMap data) {
    // Adds all points of each type from submitted data to overall data
    if (data[LightType.rhythmic] != null &&
        data[LightType.rhythmic]!.isNotEmpty) {
      this.data[LightType.rhythmic]?.addAll(data[LightType.rhythmic]!);
    }
    if (data[LightType.building] != null &&
        data[LightType.building]!.isNotEmpty) {
      this.data[LightType.building]?.addAll(data[LightType.building]!);
    }
    if (data[LightType.task] != null && data[LightType.task]!.isNotEmpty) {
      this.data[LightType.task]?.addAll(data[LightType.task]!);
    }

    // TODO: Insert to/update in firestore
  }

  /// Transforms data retrieved from Firestore test instance to
  /// [LightToLatLngMap] for local manipulation.
  static LightToLatLngMap convertDataFromFirestore(LightToGeoPointMap data) {
    LightToLatLngMap output = initialDataStructure;
    List<LightType> types = LightType.values;

    // Adds all data from parameter to output one type at a time
    for (final type in types) {
      if (data.containsKey(type.name) && data[type.name] is List) {
        output[type]!.addAll(data[type.name]);
      }
    }

    // if (data.containsKey('rhythmic') && data['rhythmic'] is List) {
    //   output[LightType.rhythmic]!.addAll(data['rhythmic']);
    // }
    // if (data.containsKey('building') && data['building'] is List) {
    //   output[LightType.building]!.addAll(data['building']);
    // }
    // if (data.containsKey('task') && data['task'] is List) {
    //   output[LightType.task]!.addAll(data['task']);
    // }

    return output;
  }

  /// Transforms data stored locally as [LightToLatLngMap] to
  /// Firestore format with String keys and any other needed changes.
  static LightToGeoPointMap convertDataToFirestore(LightToLatLngMap data) {
    throw UnimplementedError();
  }
}
