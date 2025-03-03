import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'google_maps_functions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:p2bp_2025spring_mobile/create_project_and_teams.dart';
import 'package:p2bp_2025spring_mobile/home_screen.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';
import 'project_details_page.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'db_schema_classes.dart';
import 'dart:math';
import 'firestore_functions.dart';

class ProjectMapCreation extends StatefulWidget {
  final Project partialProjectData;
  const ProjectMapCreation({super.key, required this.partialProjectData});

  @override
  State<ProjectMapCreation> createState() => _ProjectMapCreationState();
}

final User? loggedInUser = FirebaseAuth.instance.currentUser;

class _ProjectMapCreationState extends State<ProjectMapCreation> {
  late DocumentReference teamRef;
  late GoogleMapController mapController;
  LatLng _currentLocation = defaultLocation; // Default location
  bool _isLoading = true;

  List<LatLng> _polygonPoints = []; // Points for the polygon
  List<mp.LatLng> _mapToolsPolygonPoints = [];
  Set<Polygon> _polygon = {}; // Set of polygons
  List<GeoPoint> _polygonAsGeoPoints =
      []; // The current polygon represented as points (for Firestore).
  Set<Marker> _markers = {}; // Set of markers for points

  MapType _currentMapType = MapType.satellite; // Default map type

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

  void _togglePoint(LatLng point) {
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
    print(_polygonPoints);
  }

  void _finalizePolygon() {
    try {
      // Create polygon.
      _polygon = finalizePolygon(_polygonPoints);

      // Cleans up current polygon representations.
      _polygonAsGeoPoints = [];
      _mapToolsPolygonPoints = [];

      // Creating points representations for Firestore storage and area calculation
      for (LatLng coordinate in _polygonPoints) {
        _polygonAsGeoPoints
            .add(GeoPoint(coordinate.latitude, coordinate.longitude));
        _mapToolsPolygonPoints
            .add(mp.LatLng(coordinate.latitude, coordinate.longitude));
      }

      // Clears polygon points and enter add points mode.
      _polygonPoints = [];

      // Clear markers from screen.
      setState(() {
        _markers.clear();
      });
    } catch (e, stacktrace) {
      print('Excpetion in _finalize_polygon(): $e');
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
                    // TODO: Explore alternative approaches. Maps widgets automatically sizes to infinity unless declared.
                    height: MediaQuery.of(context).size.height,
                    child: Stack(
                      children: [
                        GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                              target: _currentLocation, zoom: 14.0),
                          polygons: _polygon,
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
                                "Place points for your polygon, and click the check to confirm it. When you're satisfied click finish.",
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
                            padding: const EdgeInsets.only(
                                left: 10.0, bottom: 130.0),
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
                            padding:
                                const EdgeInsets.only(left: 10.0, bottom: 53.0),
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
                        ),
                      ],
                    ),
                  ),
                  Padding(
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
                                if (_polygon.isNotEmpty) {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  await saveProject(
                                    projectTitle:
                                        widget.partialProjectData.title,
                                    description:
                                        widget.partialProjectData.description,
                                    teamRef: await getCurrentTeam(),
                                    polygonPoints: _polygonAsGeoPoints,
                                    // Polygon area is square feet, returned in
                                    // (meters)^2, multiplied by (feet/meter)^2
                                    polygonArea: mp.SphericalUtil.computeArea(
                                            _mapToolsPolygonPoints) *
                                        pow(feetPerMeter, 2),
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HomeScreen(),
                                      ));
                                  // TODO: Push to project details page.
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HomeScreen(),
                                      ));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please designate your project area, and confirm with the check button.')),
                                  );
                                }
                              },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
