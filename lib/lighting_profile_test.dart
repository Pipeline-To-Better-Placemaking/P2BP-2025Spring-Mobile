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
  LightToLatLngMap _allPointsMap = {
    LightType.rhythmic: {},
    LightType.building: {},
    LightType.task: {},
  };

  ButtonStyle _typeButtonStyle = FilledButton.styleFrom();

  @override
  void initState() {
    super.initState();
    _checkAndFetchLocation();
  }

  // Temp static fetch stuff until this is connected to other pages with test backend
  static const String _testID = 'WBZQb2ZhnjV1CJBx10t1';

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

  /// Adds a `Marker` to the map and stores that same point in
  /// `_allPointsMap` to be submitted as test data later.
  ///
  /// This also resets the fields for selecting type so another can be
  /// selected after this point is placed.
  void _togglePoint(LatLng point) {
    _allPointsMap[_selectedType]?.add(point);
    final markerId = MarkerId(point.toString());

    setState(() {
      // Create marker
      _markers.add(
        Marker(
          markerId: markerId,
          position: point,
          consumeTapEvents: true,
          onTap: () {
            // If the marker is tapped again, it will be removed
            _allPointsMap.updateAll((key, value) {
              value.remove(point);
              return value;
            });
            setState(() {
              _markers.removeWhere((marker) => marker.markerId == markerId);
            });
          },
        ),
      );

      // Reset selected light type
      _setLightType(null);
    });

    print(_allPointsMap); // debug
  }

  /// Sets [_selectedType] to parameter `type` and [_isTypeSelected] to
  /// true if [type] is non-null and false otherwise.
  void _setLightType(LightType? type) {
    setState(() {
      _selectedType = type;
      _isTypeSelected = _selectedType != null;
    });
  }

  /// Toggles map type between satellite and normal
  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
  }

  /// Sets button style on each build based on width of context
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
                        : 'Drop a pin where the light is.',
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
                                      _setLightType(LightType.rhythmic),
                                  child: Text('Rhythmic'),
                                ),
                                FilledButton(
                                  style: _typeButtonStyle,
                                  onPressed: () =>
                                      _setLightType(LightType.building),
                                  child: Text('Building'),
                                ),
                                FilledButton(
                                  style: _typeButtonStyle,
                                  onPressed: () =>
                                      _setLightType(LightType.task),
                                  child: Text('Task'),
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
