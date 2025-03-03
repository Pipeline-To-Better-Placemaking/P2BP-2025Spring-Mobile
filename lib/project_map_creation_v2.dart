import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/people_in_motion_test.dart';
import 'package:p2bp_2025spring_mobile/people_in_place_test.dart';
import 'google_maps_functions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:p2bp_2025spring_mobile/create_project_and_teams.dart';
import 'package:p2bp_2025spring_mobile/home_screen.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';
import 'create_project_details.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'db_schema_classes.dart';
import 'dart:math';
import 'firestore_functions.dart';

class ProjectMapCreationV2 extends StatefulWidget {
  final Project partialProjectData;
  const ProjectMapCreationV2({super.key, required this.partialProjectData});

  @override
  State<ProjectMapCreationV2> createState() => _ProjectMapCreationV2State();
}

final User? loggedInUser = FirebaseAuth.instance.currentUser;

class _ProjectMapCreationV2State extends State<ProjectMapCreationV2> {
  late DocumentReference teamRef;
  late GoogleMapController mapController;
  LatLng _currentLocation = defaultLocation; // Default location
  bool _isLoading = true;
  bool _isMenuVisible = false;

  List<LatLng> _polygonPoints = []; // Points for the polygon
  List<mp.LatLng> _mapToolsPolygonPoints = [];
  Set<Polygon> _polygon = {}; // Set of polygons
  List<GeoPoint> _polygonAsGeoPoints =
      []; // The current polygon represented as points (for Firestore).
  Set<Marker> _markers = {}; // Set of markers for points

  MapType _currentMapType = MapType.normal; // Default map type

  Project? project;

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
      print('Stracktrace: $stacktrace');
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
    if (mapController != null) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation, zoom: 14.0),
        ),
      );
    }
  }

  void updatePolygon() {
    setState(() {
      if (_polygonPoints.length >= 3) {
        // finalizePolygon is your helper that converts a List<LatLng> to a Set<Polygon>
        _polygon = finalizePolygon(_polygonPoints);
      } else {
        _polygon = {};
      }
    });
  }

  // Old togglePoint function
  // void _togglePoint(LatLng point) {
  //   final markerId = MarkerId(point.toString());
  //   _polygonPoints.add(point);
  //   setState(() {
  //     _markers.add(
  //       Marker(
  //         markerId: markerId,
  //         position: point,
  //         consumeTapEvents: true,
  //         onTap: () {
  //           // If the marker is tapped again, it will be removed
  //           setState(() {
  //             _markers.removeWhere((marker) => marker.markerId == markerId);
  //             _polygonPoints.remove(point);
  //           });
  //         },
  //       ),
  //     );
  //   });
  //   print(_polygonPoints);
  // }

  void _togglePoint(LatLng point) {
    final markerId = MarkerId(point.toString());
    _polygonPoints.add(point);
    _markers.add(
      Marker(
        markerId: markerId,
        position: point,
        consumeTapEvents: true,
        onTap: () {
          // Remove the tapped marker and point, then update the polygon.
          setState(() {
            _markers.removeWhere((marker) => marker.markerId == markerId);
            _polygonPoints.remove(point);
          });
          updatePolygon();
        },
      ),
    );
    // After adding the new point, update the polygon.
    updatePolygon();
    print(_polygonPoints);
  }

  Future<void> _finalizeSelection() async {
    if (_polygon.isNotEmpty) {
      await saveProject(
        projectTitle: widget.partialProjectData.title,
        description: widget.partialProjectData.description,
        teamRef: await getCurrentTeam(),
        polygonPoints: _polygonAsGeoPoints,
        // Polygon area in square feet (meters^2 multiplied by (feet/meter)^2)
        polygonArea: mp.SphericalUtil.computeArea(_mapToolsPolygonPoints) *
            pow(feetPerMeter, 2),
      );
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => PeopleInMotionTest(
                  polygonPoints: _polygonPoints,
                  polygon: _polygon,
                )),
      );
      // TODO: You might only need one Navigator.push here, unless you're planning to push to multiple pages.
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PeopleInMotionTest(
                  polygonPoints: _polygonPoints,
                  polygon: _polygon,
                )),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please designate your project area, and confirm with the check button.'),
        ),
      );
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle:
            SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 80,
        leading: Container(
          margin: EdgeInsets.only(left: 20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue, // same as your FAB background color
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(FontAwesomeIcons.chevronLeft, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Full-screen map.
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation,
                    zoom: 14.0,
                  ),
                  polygons: _polygon,
                  markers: _markers,
                  onTap: _togglePoint,
                  mapType: _currentMapType,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                // Overlayed button for toggling map type.
                Positioned(
                  top:
                      MediaQuery.of(context).padding.top + kToolbarHeight + 8.0,
                  right: 20.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.layers, color: Colors.white),
                      onPressed: _toggleMapType,
                    ),
                  ),
                ),

                // Overlayed button for finalizing polygon.
                Positioned(
                  bottom: 90.0,
                  right: 20.0,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6.0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                            icon: Icon(Icons.check,
                                color: Colors.white, size: 35),
                            onPressed: () {
                              setState(() {
                                _isMenuVisible = !_isMenuVisible;
                              });
                            }),
                      ),
                      // The red badge positioned at the edge of the container
                      if (_polygonPoints.isNotEmpty)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Text(
                              _polygonPoints.length.toString(),
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Floating container menu for points.
                if (_isMenuVisible)
                  Positioned(
                    bottom:
                        150.0, // Adjust so it sits just above the confirm button.
                    left: 20.0,
                    right: 20.0,
                    child: Container(
                      // You can fix the height or allow it to be dynamic
                      height: MediaQuery.of(context).size.height * 0.4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: _polygonPoints.length,
                              itemBuilder: (context, index) {
                                final point = _polygonPoints[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  title: Text(
                                    'Point ${index + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                                    textAlign: TextAlign.left,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        // Get the point to be removed.
                                        final point = _polygonPoints[index];
                                        // Construct the markerId the same way it was created.
                                        final markerId =
                                            MarkerId(point.toString());
                                        // Remove the marker from the markers set.
                                        _markers.removeWhere((marker) =>
                                            marker.markerId == markerId);
                                        // Remove the point from the list.
                                        _polygonPoints.removeAt(index);
                                        // Update the polygon display.
                                        updatePolygon();
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          // Bottom row with Clear All and Confirm Selections buttons.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _polygonPoints.clear();
                                      _markers.clear();
                                      _polygon = {};
                                      _isMenuVisible = false;
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 16.0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Clear All',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.close, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextButton(
                                  onPressed: () {
                                    // Finalize polygon logic
                                    _finalizeSelection();
                                    setState(() {
                                      _isMenuVisible = false;
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 16.0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Confirm Selection',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.check, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
