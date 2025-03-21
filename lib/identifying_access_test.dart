import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';
import 'project_details_page.dart';
import 'db_schema_classes.dart';
import 'google_maps_functions.dart';
import 'home_screen.dart';

class IdentifyingAccess extends StatefulWidget {
  final Project activeProject;
  final Test activeTest;

  /// IMPORTANT: When navigating to this page, pass in project details. The
  /// project details page already contains project info, so you should use
  /// that data.
  const IdentifyingAccess({
    super.key,
    required this.activeProject,
    required this.activeTest,
  });

  @override
  State<IdentifyingAccess> createState() => _IdentifyingAccessState();
}

class _IdentifyingAccessState extends State<IdentifyingAccess> {
  bool _isLoading = true;
  bool _polygonMode = false;
  bool _pointMode = false;
  bool _polylineMode = false;
  bool _oldPolylinesToggle = true;
  int? _currentSpotsOrRoute;
  AccessType? _type;
  String _directions = "Choose a category.";
  final double _bottomSheetHeight = 300;
  late DocumentReference teamRef;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation; // Default location
  final AccessData _accessData = AccessData();

  Set<Polygon> _projectArea = {};
  Polyline? _currentPolyline;
  List<LatLng> _currentPolylinePoints = [];
  final Set<Polyline> _polylines = {};
  Set<Marker> _polylineMarkers = {};
  Set<Marker> _visiblePolylineMarkers = {};
  Set<Polygon> _currentPolygon = {};
  List<LatLng> _polygonPoints = []; // Points for the polygon
  Set<Polygon> _polygons = {}; // Set of polygons
  final Set<Marker> _markers = {}; // Set of markers for points
  Set<Marker> _polygonMarkers = {}; // Set of markers for polygon creation
  bool _directionsVisible = true;
  MapType _currentMapType = MapType.satellite; // Default map type

  Project? project;

  @override
  void initState() {
    super.initState();
    initProjectArea();
  }

  /// Gets the project polygon, adds it to the current polygon list, and
  /// centers the map over it.
  void initProjectArea() {
    setState(() {
      _projectArea = getProjectPolygon(widget.activeProject.polygonPoints);
      _location = getPolygonCentroid(_projectArea.first);
      // Take some latitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      // TODO: dynamic zooming
      _isLoading = false;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToLocation(); // Ensure the map is centered on the current location
  }

  void _moveToLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: 14),
      ),
    );
  }

  void _togglePoint(LatLng point) {
    try {
      if (_pointMode) _pointTap(point);
      if (_polygonMode) _polygonTap(point);
      if (_polylineMode) _polylineTap(point);
    } catch (e, stacktrace) {
      print('Error in identifying_access_test.dart, _togglePoint(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  void _polygonTap(LatLng point) {
    if (_type == null) return;
    final markerId = MarkerId('${_type!.name}_marker_${point.toString()}');
    setState(() {
      _polygonPoints.add(point);
      _polygonMarkers.add(
        Marker(
          markerId: markerId,
          position: point,
          consumeTapEvents: true,
          icon: AssetMapBitmap(
            'assets/test_markers/${_type!.name}_marker.png',
            width: 30,
            height: 30,
          ),
          onTap: () {
            // If the marker is tapped again, it will be removed
            setState(() {
              _polygonPoints.remove(point);
              _polygonMarkers
                  .removeWhere((marker) => marker.markerId == markerId);
            });
          },
        ),
      );
    });
  }

  void _polylineTap(LatLng point) {
    if (_type == null) return;
    final markerId = MarkerId('${_type!.name}_marker_${point.toString()}');
    setState(() {
      _currentPolylinePoints.add(point);
      _polylineMarkers.add(
        Marker(
          markerId: markerId,
          position: point,
          consumeTapEvents: true,
          icon: AssetMapBitmap(
            'assets/test_markers/${_type!.name}_marker.png',
            width: 30,
            height: 30,
          ),
          onTap: () {
            // If the marker is tapped again, it will be removed
            setState(() {
              _currentPolylinePoints.remove(point);
              _polylineMarkers
                  .removeWhere((marker) => marker.markerId == markerId);
              _currentPolyline =
                  createPolyline(_currentPolylinePoints, Colors.white);
              if (_polylineMarkers.isNotEmpty) {
                _visiblePolylineMarkers = {
                  _polylineMarkers.first,
                  _polylineMarkers.last
                };
              } else {
                _visiblePolylineMarkers = {};
              }
            });
          },
        ),
      );
    });
    if (_polylineMarkers.isNotEmpty) {
      _visiblePolylineMarkers = {_polylineMarkers.first, _polylineMarkers.last};
    }
    _currentPolyline =
        createPolyline([..._currentPolylinePoints, point], Colors.white);
  }

  // TODO: Delete if proves to be unnecessary...
  void _pointTap(LatLng point) {
    if (_type == null) return;
    final markerId = MarkerId('${_type!.name}_marker_${point.toString()}');
    setState(() {
      // TODO: create list of markers for test, add these to it (cat, dog, etc.)
      _markers.add(
        Marker(
          markerId: markerId,
          position: point,
          consumeTapEvents: true,
          icon: AssetMapBitmap(
            'assets/test_markers/${_type!.name}_marker.png',
            width: 30,
            height: 30,
          ),
          onTap: () {
            // If placing a point or polygon, don't remove point.
            if (_polylineMode || _polygonMode) return;
            // If the marker is tapped again, it will be removed
            setState(() {
              _markers.removeWhere((marker) => marker.markerId == markerId);
              // TODO: create list of points for test
            });
          },
        ),
      );
    });
    _pointMode = false;
  }

  void _finalizeShape() {
    if (_polygonMode) _finalizePolygon();
    if (_polylineMode) {
      // If parking, then make sure to save the polygon also.
      if (_type == AccessType.parking) {
        _polygons = {..._polygons, ..._currentPolygon};
      }
      _finalizePolyline();
    }
  }

  void _finalizePolyline() {
    Polyline? finalPolyline =
        createPolyline(_currentPolylinePoints, Colors.black);
    if (finalPolyline != null) {
      setState(() {
        _polylines.add(finalPolyline);
      });
    } else {
      print("Polyline is null. Nothing to finalize.");
    }
    // Save data to its respective type list.
    _saveLocalData();
    // Update widgets accordingly
    setState(() {
      _polylineMarkers = {};
      _currentPolylinePoints = [];
      _currentPolyline = null;
      _visiblePolylineMarkers = {};
      _currentPolygon = {};
      _directions = 'Choose a category. Or, click finish if done.';
    });
    _polylineMode = false;
    _currentSpotsOrRoute = null;
  }

  void _saveLocalData() {
    try {
      if (_type != AccessType.taxiAndRideShare &&
          _currentSpotsOrRoute == null) {
        throw Exception("Current spots/routes not set in _saveLocalData(). "
            "Make sure a value is entered before continuing.");
      }
      if (_currentPolyline == null) {
        throw Exception("Current polyline is null in _saveLocalData()");
      }
      switch (_type) {
        case null:
          throw Exception(
              "_type is null in saveLocalData(). Make sure that type is set correctly when invoking _finalizeShape().");
        case AccessType.bikeRack:
          _accessData.bikeRacks.add(BikeRack(
              spots: _currentSpotsOrRoute!, polyline: _currentPolyline!));
        case AccessType.taxiAndRideShare:
          _accessData.taxisAndRideShares
              .add(TaxiAndRideShare(polyline: _currentPolyline!));
        case AccessType.parking:
          _accessData.parkingStructures.add(Parking(
              spots: _currentSpotsOrRoute!,
              polyline: _currentPolyline!,
              polygon: _currentPolygon.first));
        case AccessType.transportStation:
          _accessData.transportStations.add(TransportStation(
              routeNumber: _currentSpotsOrRoute!, polyline: _currentPolyline!));
      }
    } catch (e, stacktrace) {
      print(
          "Error saving data locally in identify_access_test.dart, saveLocalData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  void _finalizePolygon() {
    try {
      // Create polygon.
      _currentPolygon = finalizePolygon(_polygonPoints);

      // Clears polygon points and enter add points mode.
      _polygonPoints = [];

      // Clear markers from screen.
      setState(() {
        _polygonMarkers.clear();
        _polygonMode = false;
        _polylineMode = false;
      });

      _showDialog(
        text: 'How Many Parking Spots?',
        hintText: 'Enter number of spots.',
        onNext: () {
          setState(() {
            _polylineMode = true;
            _directions =
                'Now define the path to the project area from the parking.';
          });
        },
      );
    } catch (e, stacktrace) {
      print('Exception in _finalize_polygon(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Stack(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: GoogleMap(
                        // TODO: size based off of bottomsheet container
                        polylines: _currentPolyline == null
                            ? (_oldPolylinesToggle ? _polylines : {})
                            : (_oldPolylinesToggle
                                ? {..._polylines, _currentPolyline!}
                                : {_currentPolyline!}),
                        padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                        onMapCreated: _onMapCreated,
                        initialCameraPosition:
                            CameraPosition(target: _location, zoom: 14),
                        polygons: _oldPolylinesToggle
                            ? {
                                ..._projectArea,
                                ..._polygons,
                                ..._currentPolygon
                              }
                            : {..._projectArea, ..._currentPolygon},
                        markers: {
                          ..._markers,
                          ..._polygonMarkers,
                          ..._visiblePolylineMarkers
                        },
                        onTap: _togglePoint,
                        mapType: _currentMapType, // Use current map type
                      ),
                    ),
                    DirectionsWidget(
                        onTap: () {
                          setState(() {
                            _directionsVisible = !_directionsVisible;
                          });
                        },
                        text: _directions,
                        visibility: _directionsVisible),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: _bottomSheetHeight + 130, left: 5),
                        child: FloatingActionButton(
                          heroTag: null,
                          onPressed: _toggleMapType,
                          backgroundColor: Colors.green,
                          child: const Icon(Icons.map),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: _bottomSheetHeight + 35, left: 5),
                        child: VisibilitySwitch(
                          visibility: _oldPolylinesToggle,
                          onChanged: (value) {
                            // This is called when the user toggles the switch.
                            setState(() {
                              _oldPolylinesToggle = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        bottomSheet: _isLoading
            ? SizedBox()
            : Container(
                height: _bottomSheetHeight,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 10.0),
                decoration: BoxDecoration(
                  gradient: defaultGrad,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24.0),
                    topRight: Radius.circular(24.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(0.0, 1.0), //(x,y)
                      blurRadius: 6.0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5),
                    Center(
                      child: Text(
                        'Identifying Access',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: placeYellow,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        'Mark where people enter the project area from.',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    Center(
                      child: Text(
                        'Access Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      spacing: 10,
                      children: <Widget>[
                        Flexible(child: Spacer(flex: 1)),
                        TestButton(
                          flex: 6,
                          buttonText: 'Parking',
                          onPressed:
                              (_pointMode || _polygonMode || _polylineMode)
                                  ? null
                                  : () {
                                      setState(() {
                                        _type = AccessType.parking;
                                        _polygonMode = true;
                                        _directions =
                                            'First, define the parking area by creating a polygon.';
                                      });
                                    },
                        ),
                        TestButton(
                          flex: 6,
                          buttonText: 'Public Transport',
                          onPressed:
                              (_pointMode || _polygonMode || _polylineMode)
                                  ? null
                                  : () {
                                      _showDialog(
                                        text: 'Enter the Route Number',
                                        hintText: 'Route Number',
                                        onNext: () {
                                          setState(() {
                                            _type = AccessType.transportStation;
                                            _polylineMode = true;
                                            _directions =
                                                "Mark the spot of the transport station. Then define the path to the project area.";
                                          });
                                        },
                                      );
                                    },
                        ),
                        Flexible(child: Spacer(flex: 1)),
                      ],
                    ),
                    Row(
                      spacing: 10,
                      children: <Widget>[
                        Flexible(child: Spacer(flex: 1)),
                        TestButton(
                          flex: 6,
                          onPressed: (_pointMode ||
                                  _polygonMode ||
                                  _polylineMode)
                              ? null
                              : () {
                                  _showDialog(
                                    text: 'How Many Bikes/Scooters Can Fit?',
                                    hintText: 'Enter number of spots.',
                                    onNext: () {
                                      setState(() {
                                        _type = AccessType.bikeRack;
                                        _polylineMode = true;
                                        _directions =
                                            "Mark the spot of the bike/scooter rack. Then define the path to the project area.";
                                      });
                                    },
                                  );
                                },
                          buttonText: 'Bike or Scooter Rack',
                        ),
                        TestButton(
                          flex: 6,
                          buttonText: 'Taxi or Rideshare',
                          onPressed:
                              (_pointMode || _polygonMode || _polylineMode)
                                  ? null
                                  : () {
                                      setState(() {
                                        _type = AccessType.taxiAndRideShare;
                                        _polylineMode = true;
                                        _directions =
                                            'Mark a point where the taxi dropped off. Then make a line to denote the path to the project area.';
                                      });
                                    },
                        ),
                        Flexible(child: Spacer(flex: 1)),
                      ],
                    ),
                    SizedBox(height: 20),
                    Expanded(
                      child: Row(
                        spacing: 10,
                        children: <Widget>[
                          Expanded(
                            child: Row(
                              spacing: 10,
                              children: <Widget>[
                                Flexible(
                                  child: EditButton(
                                    text: 'Confirm Shape',
                                    foregroundColor: Colors.green,
                                    backgroundColor: Colors.white,
                                    icon: const Icon(Icons.check),
                                    iconColor: Colors.green,
                                    onPressed: ((_polylineMode &&
                                                (_currentPolyline != null &&
                                                    _currentPolyline!
                                                            .points.length >
                                                        2)) ||
                                            (_polygonMode &&
                                                _polygonPoints.length >= 3))
                                        ? _finalizeShape
                                        : null,
                                  ),
                                ),
                                Flexible(
                                  child: EditButton(
                                    text: 'Cancel',
                                    foregroundColor: Colors.red,
                                    backgroundColor: Colors.white,
                                    icon: const Icon(Icons.cancel),
                                    iconColor: Colors.red,
                                    onPressed: (_polylineMode || _polygonMode)
                                        ? () {
                                            setState(() {
                                              _pointMode = false;
                                              _polygonMode = false;
                                              _polylineMode = false;
                                              _polylineMarkers = {};
                                              _currentPolyline = null;
                                              _currentPolylinePoints = [];
                                              _visiblePolylineMarkers = {};
                                              _polygonMarkers = {};
                                              _currentPolygon = {};
                                              _directions =
                                                  'Choose a category. Or, click finish if done.';
                                            });
                                            _polygonPoints = [];
                                          }
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            flex: 0,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: EditButton(
                                text: 'Finish',
                                foregroundColor: Colors.black,
                                backgroundColor: Colors.white,
                                icon: const Icon(Icons.chevron_right,
                                    color: Colors.black),
                                onPressed: (_polygonMode || _polylineMode)
                                    ? null
                                    : () {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return TestFinishDialog(
                                                onNext: () {
                                                  widget.activeTest
                                                      .submitData(_accessData);
                                                  Navigator.pushReplacement(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            HomeScreen(),
                                                      ));
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            ProjectDetailsPage(
                                                                projectData: widget
                                                                    .activeProject),
                                                      ));
                                                },
                                              );
                                            });
                                      },
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }

  void _showDialog(
      {required String text,
      required String hintText,
      required VoidCallback? onNext}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          title: Column(
            children: [
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            decoration: InputDecoration(hintText: hintText),
            onChanged: (inputText) {
              int? parsedInt = int.tryParse(inputText);
              if (parsedInt == null) {
                print(
                    "Error: Could not parse int in _showDialog with type $_type");
                print("Invalid input: defaulting to null.");
              }
              setState(() {
                _currentSpotsOrRoute = parsedInt;
              });
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'Cancel');
                {
                  setState(() {
                    _pointMode = false;
                    _polygonMode = false;
                    _polylineMode = false;
                    _polylineMarkers = {};
                    _currentPolyline = null;
                    _currentPolylinePoints = [];
                    _visiblePolylineMarkers = {};
                    _polygonMarkers = {};
                    _currentPolygon = {};
                    _directions =
                        'Choose a category. Or, click finish if done.';
                    _currentSpotsOrRoute = null;
                  });
                  _polygonPoints = [];
                }
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_currentSpotsOrRoute == null) return;
                onNext!();
                Navigator.pop(context, 'Next');
              },
              child: const Text('Next'),
            ),
          ],
        );
      },
    );
  }
}
