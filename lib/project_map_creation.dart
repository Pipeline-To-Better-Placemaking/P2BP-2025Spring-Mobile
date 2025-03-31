import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:p2bp_2025spring_mobile/home_screen.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';

import 'db_schema_classes.dart';
import 'firestore_functions.dart';
import 'google_maps_functions.dart';

class ProjectMapCreation extends StatefulWidget {
  final Project partialProjectData;
  const ProjectMapCreation({super.key, required this.partialProjectData});

  @override
  State<ProjectMapCreation> createState() => _ProjectMapCreationState();
}

class _ProjectMapCreationState extends State<ProjectMapCreation> {
  late DocumentReference teamRef;
  late GoogleMapController mapController;
  LatLng _currentLocation = defaultLocation; // Default location
  bool _deleteMode = false;
  bool _isLoading = true;
  bool _pointMode = false;
  bool _polygonMode = true;
  bool _outsidePoint = false;
  String? _pointName;
  String _directions =
      "Place points for your polygon, and click the check to confirm it. When you're satisfied click next.";
  String _errorText = 'You tried to place a point outside of the project area!';
  List<LatLng> _polygonPoints = []; // Points for the polygon
  List<StandingPoint> _standingPoints = [];
  List<mp.LatLng> _mapToolsPolygonPoints = [];
  Set<Polygon> _polygons = {}; // Set of polygons
  Set<Marker> _markers = {}; // Set of markers for points
  final _formKey = GlobalKey<FormState>();

  MapType _currentMapType = MapType.satellite; // Default map type

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
    try {
      _currentLocation = await checkAndFetchLocation();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e, stacktrace) {
      print('Exception fetching location in project_map_creation.dart: $e');
      print('Stacktrace: $stacktrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Map failed to load. Error trying to retrieve location permissions.')),
      );
      Navigator.pop(context);
    }
  }

  void _moveToCurrentLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentLocation, zoom: 14.0),
      ),
    );
  }

  void _togglePoint(LatLng point) {
    if (_pointMode == true) {
      if (_deleteMode) return;
      if (!mp.PolygonUtil.containsLocationAtLatLng(
          point.latitude, point.longitude, _mapToolsPolygonPoints, true)) {
        setState(() {
          _outsidePoint = true;
        });
        // TODO: change logic for this
        Future.delayed(Duration(seconds: 2), () {
          setState(() {
            _outsidePoint = false;
          });
        });
        return;
      }
      _showDialog(point);
    } else if (_polygonMode == true) {
      _polygonTap(point);
    }
  }

  void _pointTap(LatLng point, String? title) {
    if (title == null) return;
    final markerId = MarkerId(point.toString());
    _standingPoints.add(StandingPoint(location: point, title: title));
    setState(() {
      _markers.add(
        Marker(
          markerId: markerId,
          position: point,
          infoWindow: InfoWindow(
              title: title,
              snippet:
                  '${point.latitude.toStringAsFixed(5)}, ${point.latitude.toStringAsFixed(5)}',
              onTap: () {}),
          icon: BitmapDescriptor.defaultMarkerWithHue(100),
          onTap: () {
            if (_deleteMode) {
              setState(() {
                _markers.removeWhere((marker) => marker.markerId == markerId);
                _standingPoints.removeWhere(
                    (standingPoint) => standingPoint.location == point);
                _deleteMode = false;
              });
            }
          },
        ),
      );
    });
  }

  void _polygonTap(LatLng point) {
    final markerId = MarkerId(point.toString());
    _polygonPoints.add(point);
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
              _polygonPoints.remove(point);
            });
          },
        ),
      );
    });
  }

  void _finalizePolygon() {
    try {
      // Create polygon.
      _polygons.add(finalizePolygon(_polygonPoints));

      // Creates Maps Toolkit representation of Polygon for checking if point
      // is inside area.
      _mapToolsPolygonPoints = _polygons.first.toMPLatLngList();

      // Clears polygon points and enter add points mode.
      _polygonPoints = [];

      // Clear markers from screen.
      setState(() {
        _markers.clear();
      });
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: Stack(
                      children: [
                        GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                              target: _currentLocation, zoom: 14.0),
                          polygons: _polygons,
                          markers: _markers,
                          onTap: _togglePoint,
                          mapType: _currentMapType, // Use current map type
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20.0, horizontal: 25.0),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              decoration: BoxDecoration(
                                color: directionsTransparency,
                                gradient: defaultGrad,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(10)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _directions,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 10.0, bottom: 50.0),
                            child: FloatingActionButton(
                              heroTag: null,
                              onPressed: _toggleMapType,
                              backgroundColor: Colors.green,
                              child: const Icon(Icons.map),
                            ),
                          ),
                        ),
                        _polygonMode
                            ? Align(
                                alignment: Alignment.bottomLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10.0, bottom: 130.0),
                                  child: FloatingActionButton(
                                    heroTag: null,
                                    onPressed: () {
                                      setState(() {
                                        if (_polygonPoints.length >= 3) {
                                          _finalizePolygon();
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
                              )
                            : Align(
                                alignment: Alignment.bottomLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10.0, bottom: 130.0),
                                  child: FloatingActionButton(
                                    heroTag: null,
                                    onPressed: () {
                                      setState(() {
                                        _deleteMode = !_deleteMode;
                                        if (_deleteMode == true) {
                                          _outsidePoint = false;
                                          _errorText =
                                              'You are in delete mode.';
                                        } else {
                                          _outsidePoint = false;
                                          _errorText =
                                              'You tried to place a point outside of the project area!';
                                        }
                                      });
                                    },
                                    backgroundColor:
                                        _deleteMode ? Colors.blue : Colors.red,
                                    child: Icon(
                                      _deleteMode
                                          ? Icons.location_on
                                          : Icons.delete,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                  _polygonMode
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: EditButton(
                              text: 'Next',
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF4871AE),
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      if (_polygons.isNotEmpty) {
                                        setState(() {
                                          _markers = {};
                                          _polygonPoints = [];
                                          _pointMode = true;
                                          _polygonMode = false;
                                          _directions =
                                              "Place your standings points in the project area. When you're satisfied click finish.";
                                        });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Please designate your project area, and confirm with the check button.')),
                                        );
                                      }
                                    },
                            ),
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: EditButton(
                              text: 'Finish',
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF4871AE),
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      if (_standingPoints.isNotEmpty) {
                                        setState(() {
                                          _isLoading = true;
                                        });
                                        await saveProject(
                                          projectTitle:
                                              widget.partialProjectData.title,
                                          description: widget
                                              .partialProjectData.description,
                                          address:
                                              widget.partialProjectData.address,
                                          polygonPoints: _polygons.first.points,
                                          polygonArea: _polygons.first
                                              .getAreaInSquareFeet(),
                                          standingPoints: _standingPoints,
                                        );
                                        if (!context.mounted) return;
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  HomeScreen(),
                                            ));
                                        // TODO: Push to project details page.
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  HomeScreen(),
                                            ));
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Please designate at least one standing point.')),
                                        );
                                      }
                                    },
                            ),
                          ),
                        ),
                  _outsidePoint || _deleteMode
                      ? Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 30.0, horizontal: 100.0),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red[900],
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(10)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _errorText,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red[50],
                                ),
                              ),
                            ),
                          ),
                        )
                      : SizedBox(),
                ],
              ),
      ),
    );
  }

  void _showDialog(LatLng point) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          title: Column(
            children: [
              Text(
                'Enter Standing Point Title',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Form(
            key: _formKey,
            child: DialogTextBox(
              maxLength: 60,
              labelText: 'Enter the name of the standing point',
              errorMessage: 'Please enter at least 3 characters.',
              onChanged: (inputText) {
                setState(() {
                  _pointName = inputText;
                });
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'Cancel');
                {
                  _pointName = null;
                }
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate() &&
                    _pointName != null &&
                    _pointName!.characters.length > 2) {
                  _pointTap(point, _pointName);
                  Navigator.pop(context, 'Next');
                }
              },
              child: const Text('Next'),
            ),
          ],
        );
      },
    );
  }
}
