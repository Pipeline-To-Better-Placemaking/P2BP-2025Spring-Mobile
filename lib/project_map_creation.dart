import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/assets.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';

import 'db_schema_classes.dart';
import 'google_maps_functions.dart';
import 'home_screen.dart';

class ProjectMapCreation extends StatefulWidget {
  final Member member;
  final Team team;
  final String title;
  final String description;
  final String address;
  final File? coverImage;

  const ProjectMapCreation({
    super.key,
    required this.member,
    required this.team,
    required this.title,
    required this.description,
    required this.address,
    this.coverImage,
  });

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
      "Place points for your polygon, and click the check to confirm it. "
      "When you're satisfied click next.";
  String _errorText = 'You tried to place a point outside of the project area!';
  final List<LatLng> _polygonPoints = [];
  final List<StandingPoint> _standingPoints = [];
  final Set<Polygon> _polygons = {};
  Set<Marker> _markers = {};
  final _formKey = GlobalKey<FormState>();
  MapType _currentMapType = MapType.satellite;
  Timer? _outsidePointTimer;

  @override
  void initState() {
    super.initState();
    _checkAndFetchLocation();
  }

  @override
  void dispose() {
    _outsidePointTimer?.cancel();
    super.dispose();
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
          content: Text('Map failed to load. Error trying to '
              'retrieve location permissions.'),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _moveToCurrentLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentLocation, zoom: 15.0),
      ),
    );
  }

  void _togglePoint(LatLng point) {
    if (_polygonMode == true) {
      _polygonTap(point);
    } else if (_pointMode == true) {
      if (_deleteMode) return;
      if (!isPointInsidePolygon(point, _polygons.first)) {
        setState(() {
          _outsidePoint = true;
        });
        _outsidePointTimer?.cancel();
        _outsidePointTimer = Timer(Duration(seconds: 3), () {
          setState(() {
            _outsidePoint = false;
          });
        });
      }
      _showDialog(point);
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
          icon: standingPointEnabledIcon,
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
          icon: tempMarkerIcon,
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
      // Only have one polygon at a time.
      if (_polygons.isNotEmpty) _polygons.clear();

      // Create polygon.
      _polygons.add(finalizePolygon(_polygonPoints));

      // Clears polygon points and enter add points mode.
      _polygonPoints.clear();

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (_currentMapType == MapType.normal)
          ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height,
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition:
                          CameraPosition(target: _currentLocation, zoom: 15.0),
                      polygons: _polygons,
                      markers: _markers,
                      onTap: _togglePoint,
                      mapType: _currentMapType,
                    ),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 4),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: directionsTransparency,
                            gradient: defaultGrad,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(12)),
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
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 50),
                        child: Column(
                          spacing: 20,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_polygonMode)
                              CircularIconMapButton(
                                backgroundColor: Colors.blue,
                                borderColor: Color(0xFF2D6040),
                                onPressed: () {
                                  setState(() {
                                    if (_polygonPoints.length >= 3) {
                                      _finalizePolygon();
                                    }
                                  });
                                },
                                icon: const Icon(Icons.check, size: 35),
                              )
                            else
                              CircularIconMapButton(
                                backgroundColor:
                                    _deleteMode ? Colors.blue : Colors.red,
                                borderColor: _deleteMode
                                    ? Colors.blue.shade900
                                    : Colors.red.shade900,
                                onPressed: () {
                                  setState(() {
                                    _deleteMode = !_deleteMode;
                                    if (_deleteMode == true) {
                                      _outsidePoint = false;
                                      _errorText = 'You are in delete mode.';
                                    } else {
                                      _outsidePoint = false;
                                      _errorText = 'You tried to place a point '
                                          'outside of the project area!';
                                    }
                                  });
                                },
                                icon: Icon(
                                  _deleteMode
                                      ? Icons.location_on
                                      : Icons.delete,
                                  size: 30,
                                ),
                              ),
                            CircularIconMapButton(
                              backgroundColor: Colors.green,
                              borderColor: Color(0xFF2D6040),
                              onPressed: _toggleMapType,
                              icon: const Icon(Icons.map),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: _polygonMode
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
                                            _polygonPoints.clear();
                                            _pointMode = true;
                                            _polygonMode = false;
                                            _directions =
                                                "Place your standings points in "
                                                "the project area. When you're "
                                                "satisfied click finish.";
                                          });
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please designate your project '
                                                'area, and confirm with the '
                                                'check button.',
                                              ),
                                            ),
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
                                    : () => _saveProject(context),
                              ),
                            ),
                          ),
                  ),
                  SafeArea(
                    child: _outsidePoint || _deleteMode
                        ? TestErrorText(
                            padding: EdgeInsets.fromLTRB(50, 0, 50, 60),
                            text: _errorText,
                          )
                        : SizedBox(),
                  ),
                ],
              ),
      ),
    );
  }

  void _saveProject(BuildContext context) async {
    if (_standingPoints.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      await Project.createNew(
        title: widget.title,
        description: widget.description,
        address: widget.address,
        team: widget.team,
        owner: widget.member,
        polygon: _polygons.first,
        standingPoints: _standingPoints,
        coverImage: widget.coverImage,
      );

      if (!context.mounted) return;
      // Navigate to HomeScreen after emptying navigator stack.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(member: widget.member),
        ),
        (Route route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please designate at least one standing point.')),
      );
    }
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
