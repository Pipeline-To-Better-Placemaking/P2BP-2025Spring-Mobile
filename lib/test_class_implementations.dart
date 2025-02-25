import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/firestore_functions.dart';
import 'db_schema_classes.dart';

/// Maps the collection IDs for tests to that test's [recreateFromDoc]
/// constructor.
///
/// Intended use case is when using `Test.recreateFromDoc` constructor
/// with an existing `Test` instance from Firestore, primarily in
/// [getTestInfo].
const Map<String, Test Function(DocumentSnapshot<Map<String, dynamic>>)>
    collectionIDToRecreateFromDoc = {
  LightingProfileTest.collectionIDStatic: LightingProfileTest.recreateFromDoc,
};

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
typedef LightToGeoPointMap = Map<String, List<GeoPoint>>;

/// Class for lighting profile test info and methods.
class LightingProfileTest extends Test<LightToLatLngMap> {
  /// Hard-coded definition of basic structure for `data`
  /// used for initialization of new lighting tests.
  static const LightToLatLngMap initialDataStructure = {
    LightType.rhythmic: {},
    LightType.building: {},
    LightType.task: {},
  };

  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'lighting_profile_test';

  LightingProfileTest.createNew({
    required super.title,
    required super.testID,
    required super.scheduledTime,
    required super.projectRef,
    super.creationTime,
    super.data,
  }) : super.createNew();

  LightingProfileTest.recreateFromDoc(
      DocumentSnapshot<Map<String, dynamic>> testDoc)
      : super.recreateFromDoc(testDoc);

  @override
  LightToLatLngMap getInitialDataStructure() {
    return initialDataStructure;
  }

  @override
  String getCollectionID() {
    return collectionIDStatic;
  }

  @override
  LightToLatLngMap convertDataFromDoc(dynamic data) {
    return _convertDataFromFirestore(data);
  }

  @override
  void submitData(LightToLatLngMap data) {
    // Adds all points of each type from submitted data to overall data
    LightToGeoPointMap firestoreData = _convertDataToFirestore(data);

    // TODO: Insert to/update in firestore
  }

  /// Transforms data retrieved from Firestore test instance to
  /// [LightToLatLngMap] for local manipulation.
  static LightToLatLngMap _convertDataFromFirestore(LightToGeoPointMap data) {
    LightToLatLngMap output = initialDataStructure;
    List<LightType> types = LightType.values;

    // Adds all data from parameter to output one type at a time
    for (final type in types) {
      if (data.containsKey(type.name) && data[type.name] is List) {
        for (final geopoint in data[type.name]!) {
          output[type]?.add(geopoint.toLatLng());
        }
      }
    }

    return output;
  }

  /// Transforms data stored locally as [LightToLatLngMap] to
  /// Firestore format (represented by [LightToGeoPointMap])
  /// with String keys and any other needed changes.
  static LightToGeoPointMap _convertDataToFirestore(LightToLatLngMap data) {
    LightToGeoPointMap output = {};
    List<LightType> types = LightType.values;

    for (final type in types) {
      if (data.containsKey(type) && data[type] is Set) {
        for (final latlng in data[type]!) {
          output[type.name]?.add(latlng.toGeoPoint());
        }
      }
    }

    return output;
  }
}
