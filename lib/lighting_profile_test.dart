import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'google_maps_functions.dart';

class LightingProfileTestPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LightingProfileTestPageState();
}

enum LightType { rhythmic, building, task }

class _LightingProfileTestPageState extends State<LightingProfileTestPage> {
  bool _isLoading = true;
  bool _isTypeSelected = false;

  LightType? _selectedType;

  late GoogleMapController mapController;
  LatLng _currentPosition = defaultLocation;
  Set<Marker> _markers = {}; // Set of markers for points
  MapType _currentMapType = MapType.satellite; // Default map type
  List<LatLng> _currentPoints = []; // Point(s) for current selection

  ButtonStyle _typeButtonStyle = FilledButton.styleFrom();

  @override
  void initState() {
    super.initState();
    _checkAndFetchLocation();
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

  void _selectRhythmic() {
    setState(() {
      _selectedType = LightType.rhythmic;
      _isTypeSelected = true;
    });
  }

  void _selectBuilding() {
    setState(() {
      _selectedType = LightType.building;
      _isTypeSelected = true;
    });
  }

  void _selectTask() {
    setState(() {
      _selectedType = LightType.task;
      _isTypeSelected = true;
    });
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
                    _isTypeSelected
                        ? 'Drop a pin where the light is.'
                        : 'Select a type of light.',
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
                                  horizontal: 60.0, vertical: 90.0),
                              child: FloatingActionButton(
                                heroTag: null,
                                onPressed: _toggleMapType,
                                backgroundColor: Colors.green,
                                child: const Icon(Icons.map),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 60.0, vertical: 20.0),
                              child: FloatingActionButton(
                                heroTag: null,
                                onPressed: () {
                                  setState(() {
                                    if (_currentPoints.isNotEmpty) {
                                      // TODO: confirm selection
                                    }
                                  });
                                },
                                backgroundColor: Colors.blue,
                                child: const Icon(
                                  Icons.check,
                                  size: 35,
                                ),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              FilledButton(
                                style: _typeButtonStyle,
                                onPressed: _selectRhythmic,
                                child: Text('Rhythmic'),
                              ),
                              FilledButton(
                                style: _typeButtonStyle,
                                onPressed: _selectBuilding,
                                child: Text('Building'),
                              ),
                              FilledButton(
                                style: _typeButtonStyle,
                                onPressed: _selectTask,
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
