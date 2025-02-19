import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'google_maps_functions.dart';
import 'db_schema_classes.dart';
import 'test_class_implementations.dart';

class LightingProfileTestPage extends StatefulWidget {
  // final LightingProfileTest testToBeCompleted;
  // const LightingProfileTestPage({super.key, required this.testToBeCompleted});

  @override
  State<StatefulWidget> createState() => _LightingProfileTestPageState();
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class _LightingProfileTestPageState extends State<LightingProfileTestPage> {
  bool _isLoading = true;
  bool _isTypeSelected = false;
  LightType? _selectedType;

  late GoogleMapController mapController;
  LatLng _currentPosition = defaultLocation;
  MapType _currentMapType = MapType.satellite; // Default map type
  Set<Marker> _markers = {}; // Set of markers visible on map
  List<LatLng> _currentPoints = []; // Point(s) for current selection, max 1
  LightingProfileDataType _confirmedPoints = {
    LightType.rhythmic: {},
    LightType.building: {},
    LightType.task: {},
  };

  LightingProfileTest

  ButtonStyle _typeButtonStyle = FilledButton.styleFrom();

  @override
  void initState() {
    super.initState();

    _checkAndFetchLocation();
  }

  // Temp static fetch stuff until this is connected to other pages with test backend
  static const String _testID = 'WBZQb2ZhnjV1CJBx10t1';
  void fetchTestRef() async {
    LightingProfileTest test;
    final DocumentSnapshot<Map<String, dynamic>> testDoc;

    try {
      testDoc = await _firestore
          .collection('lighting_profile_test')
          .doc(_testID)
          .get();
      if (testDoc.exists && testDoc.data()!.containsKey('scheduledTime')) {
        test = LightingProfileTest(
          title: testDoc['title'],
          testID: testDoc['id'],
          scheduledTime: testDoc['scheduledTime'],
          projectRef: testDoc['project'],
          maxResearchers: testDoc['maxResearchers'],
          creationTime: testDoc['creationTime'],
          data:
        );
      } else {
        if (!testDoc.exists) {
          throw Exception('test-does-not-exist');
        } else {
          throw Exception('test-improperly-initialized');
        }
      }
    } catch (e, stacktrace) {
      print('Exception retrieving teams: $e');
      print('Stacktrace: $stacktrace');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToCurrentLocation(); // Ensure the map is centered on the current location
  }

  Future<void> _checkAndFetchLocation() async {
    _currentPosition = await checkAndFetchLocation();
    setState(() {
      _isLoading = false;
    });
  }

  void _moveToCurrentLocation() {
    if (mapController != null) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition, zoom: 14.0),
        ),
      );
    }
  }

  void _togglePoint(LatLng point) {
    // Makes sure there is no more than 1 point marked at any time
    if (_currentPoints.isNotEmpty) {
      setState(() {
        _currentPoints = [];
        _markers = {};
      });
    }

    final markerId = MarkerId(point.toString());
    _currentPoints.add(point);
    setState(() {
      _markers.add(
        Marker(
          markerId: markerId,
          position: point,
          consumeTapEvents: true,
          onTap: () {
            // If the marker is tapped again, it will be removed
            setState(() {
              _markers.removeWhere((marker) => marker.markerId == markerId);
              _currentPoints.remove(point);
            });
          },
        ),
      );
    });
    print(_currentPoints);
  }

  // Toggles map type between satellite and normal
  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
  }

  // Sets button style on each build based on width of context
  void _setButtonStyle() {
    _typeButtonStyle = FilledButton.styleFrom(
      backgroundColor: Colors.blue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      visualDensity: VisualDensity(horizontal: -4),
      fixedSize: Size.fromWidth(MediaQuery.of(context).size.width * .3),
    );
  }

  void _selectType(LightType type) {
    setState(() {
      _selectedType = type;
      _isTypeSelected = true;
    });
  }

  /// Locks in placed point(s), saving them with all other confirmed points
  /// to be submitted once test is complete.
  void _confirmPoints() {
    if (_isTypeSelected && _selectedType != null && _currentPoints.isNotEmpty) {
      _confirmedPoints.updateAll(update);
      _confirmedPoints.update();
    }
  }

  /// Cancels placement of point(s), removing any points and markers in
  /// [_currentPoints] and [_markers]
  void _cancelPoints() {
    setState(() {
      _currentPoints = [];
      _markers = {};
    });
  }

  // saving results in DB:
  // document has misc fields like date completed and maybe user id
  // data saved in array 'results' or just 'data'
  // has a sub-array for each light type: rhythmic, building, task
  // each of those is a list of points (individual maps with lat and lng or
  // some better data type)

  @override
  Widget build(BuildContext context) {
    _setButtonStyle();
    return SafeArea(
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  Text(
                    !_isTypeSelected
                        ? 'Select a type of light.'
                        : _currentPoints.isEmpty
                            ? 'Drop a pin where the light is.'
                            : 'Confirm or cancel your selection.',
                    style: TextStyle(fontSize: 24),
                  ),
                  Center(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * .7,
                      child: Stack(
                        children: <Widget>[
                          GoogleMap(
                            onMapCreated: _onMapCreated,
                            initialCameraPosition: CameraPosition(
                                target: _currentPosition, zoom: 14),
                            markers: _markers,
                            onTap: _isTypeSelected ? _togglePoint : null,
                            mapType: _currentMapType,
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 60.0, vertical: 15.0),
                              child: FloatingActionButton(
                                heroTag: null,
                                onPressed: _toggleMapType,
                                backgroundColor: Colors.green,
                                child: const Icon(Icons.map),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: <Widget>[
                          Text(
                            'Light Type',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          if (!_isTypeSelected)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                FilledButton(
                                  style: _typeButtonStyle,
                                  onPressed: () =>
                                      _selectType(LightType.rhythmic),
                                  child: Text('Rhythmic'),
                                ),
                                FilledButton(
                                  style: _typeButtonStyle,
                                  onPressed: () =>
                                      _selectType(LightType.building),
                                  child: Text('Building'),
                                ),
                                FilledButton(
                                  style: _typeButtonStyle,
                                  onPressed: () => _selectType(LightType.task),
                                  child: Text('Task'),
                                ),
                              ],
                            ),
                          if (_currentPoints.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                FilledButton(
                                  style: _typeButtonStyle,
                                  onPressed: _confirmPoints,
                                  child: Text('Confirm'),
                                ),
                                FilledButton(
                                  style: _typeButtonStyle,
                                  onPressed: _cancelPoints,
                                  child: Text('Cancel'),
                                ),
                              ],
                            ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blue[400],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text('Back'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
