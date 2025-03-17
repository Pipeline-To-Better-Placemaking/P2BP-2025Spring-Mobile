import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/firestore_functions.dart';
import 'google_maps_functions.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:p2bp_2025spring_mobile/db_schema_classes.dart';
import 'package:p2bp_2025spring_mobile/project_details_page.dart';
import 'package:p2bp_2025spring_mobile/people_in_motion_instructions.dart';

class TracedRoute {
  final List<LatLng> points;
  final String activityType;
  final DateTime timestamp;

  TracedRoute({
    required this.points,
    required this.activityType,
    required this.timestamp,
  });

  // Convert the route data into a JSON‑compatible map.
  Map<String, dynamic> toJson() {
    return {
      'points': points.toGeoPointList(),
      'activityType': activityType,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class PeopleInMotionTestPage extends StatefulWidget {
  final Project activeProject;
  final PeopleInMotionTest activeTest;

  const PeopleInMotionTestPage({
    super.key,
    required this.activeProject,
    required this.activeTest,
  }) : super();

  @override
  State<PeopleInMotionTestPage> createState() => _PeopleInMotionTestPageState();
}

class _PeopleInMotionTestPageState extends State<PeopleInMotionTestPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late GoogleMapController mapController;
  LatLng _currentLocation = defaultLocation; // Default location
  bool _isLoading = true;
  Timer? _hintTimer;
  bool _showHint = false;
  bool _isTestRunning = false;
  Timer? _timer;
  Set<Marker> _markers = {}; // Set of markers for points
  Set<Polygon> _polygons = {}; // Set of polygons
  MapType _currentMapType = MapType.normal; // Default map type
  bool _showErrorMessage = false;
  bool _isPointsMenuVisible = false;
  List<LatLng> _loggedPoints = [];

  bool _isTracingMode = false;
  List<LatLng> _tracedPolylinePoints = [];
  // Confirmed polylines persist from previous sessions.
  Set<Polyline> _confirmedPolylines = {};
  // Temporary polyline shown during the current tracing session
  Polyline? _tempPolyline;

  // This list tracks marker IDs added during the current tracing session.
  List<String> _currentTracingMarkerIds = [];
  PersistentBottomSheetController? _tracingSheetController;

  // Custom marker icons
  BitmapDescriptor? walkingConnector;
  BitmapDescriptor? runningConnector;
  BitmapDescriptor? swimmingConnector;
  BitmapDescriptor? wheelsConnector;
  BitmapDescriptor? handicapConnector;
  BitmapDescriptor? tempMarkerIcon;
  bool _customMarkersLoaded = false;

  MarkerId? _openMarkerId;

  List<TracedRoute> _confirmedRoutes = [];
  Map<String, List<String>> _routeMarkerIds = {};

  // Define an initial time
  int _remainingSeconds = 300;

  // Initialize project area using polygon data from ProjectDetails
  void initProjectArea() {
    setState(() {
      if (widget.activeProject.polygonPoints.isNotEmpty) {
        _polygons = getProjectPolygon(widget.activeProject.polygonPoints);
        if (_polygons.isNotEmpty) {
          // Calculate the centroid of the first polygon to center the map
          _currentLocation = getPolygonCentroid(_polygons.first);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    initProjectArea();
    print("initState called");
    _checkAndFetchLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("PostFrameCallback fired");
      _loadCustomMarkers();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  // Helper method to format elapsed seconds into mm:ss.
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Method to start the test and timer.
  void _startTest() {
    setState(() {
      _isTestRunning = true;
      _remainingSeconds = 300; // Reset countdown value
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          // When the timer reaches zero, cancel the timer and end the test.
          timer.cancel();
          _endTest();
        }
      });
    });
  }

  // Method to end the test and cancel the timer.
  void _endTest() async {
    setState(() {
      _isTestRunning = false;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectDetailsPage(
            projectData: widget.activeProject,
          ),
        ),
      );
    });
    _timer?.cancel();

    try {
      await _firestore
          .collection(
              widget.activeTest.collectionID) // NEW: Use test's collection ID.
          .doc(widget.activeTest.testID) // NEW: Use test's document ID.
          .update({
        'data': PeopleInMotionTest.convertDataToFirestore(
            _confirmedRoutes), // NEW: Convert traced route data.
        'isComplete': true,
      });
      print("PeopleInMotion test data submitted successfully.");
    } catch (e, stacktrace) {
      print("Error submitting PeopleInMotion test data: $e");
      print("Stacktrace: $stacktrace");
    }
  }

  void _showInstructionOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
              vertical: MediaQuery.of(context).size.height * 0.005),
          actionsPadding: EdgeInsets.zero,
          title: Text(
            'How It Works:',
            style: TextStyle(fontSize: 22),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: screenSize.width * 0.95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  peopleInMotionInstructions(),
                  SizedBox(height: 10),
                  buildLegends(),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: false,
                      onChanged: (_) {},
                    ),
                    Text("Don't show this again next time"),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget buildActivityColorItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14)),
      ],
    );
  }

  void _resetHintTimer() {
    _hintTimer?.cancel();
    setState(() {
      _showHint = false;
    });
    _hintTimer = Timer(Duration(seconds: 10), () {
      setState(() {
        _showHint = true;
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (widget.activeProject.polygonPoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final latLngPoints = widget.activeProject.polygonPoints.toLatLngList();
        final bounds = _getPolygonBounds(latLngPoints);
        mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      });
    } else {
      _moveToCurrentLocation(); // Center on current location.
    }
  }

  Future<void> _checkAndFetchLocation() async {
    try {
      _currentLocation = await checkAndFetchLocation();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInstructionOverlay();
      });
    } catch (e, stacktrace) {
      print('Exception fetching location: $e');
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

  LatLngBounds _getPolygonBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
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

  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
  }

  // Check if tapped point is inside the polygon boundary.
  bool _isPointInsidePolygon(LatLng point, List<LatLng> polygon) {
    final List<mp.LatLng> mpPolygon = polygon
        .map((latLng) => mp.LatLng(latLng.latitude, latLng.longitude))
        .toList();
    return mp.PolygonUtil.containsLocation(
      mp.LatLng(point.latitude, point.longitude),
      mpPolygon,
      false,
    );
  }

  // When in tracing mode, each tap creates a dot marker and updates the temporary polyline
  Future<void> _handleMapTap(LatLng point) async {
    _resetHintTimer();
    // If point is outside the project boundary, display error message
    if (!_isPointInsidePolygon(
        point, widget.activeProject.polygonPoints.toLatLngList())) {
      setState(() {
        _showErrorMessage = true;
      });
      Timer(Duration(seconds: 3), () {
        setState(() {
          _showErrorMessage = false;
        });
      });
      return;
    }
    if (_isTracingMode) {
      // Add this tap as a dot marker.
      final String markerIdVal =
          "tracing_marker_${DateTime.now().millisecondsSinceEpoch}";
      final MarkerId markerId = MarkerId(markerIdVal);
      // Using a different hue for temporary markers.
      final Marker marker = Marker(
        markerId: markerId,
        position: point,
        icon: _customMarkersLoaded && tempMarkerIcon != null
            ? tempMarkerIcon!
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
      // Append the tapped point to the traced polyline.
      setState(() {
        _markers.add(marker);
        _currentTracingMarkerIds.add(markerIdVal);
        _tracedPolylinePoints.add(point);
        _tempPolyline = Polyline(
          polylineId: PolylineId("tracing"),
          points: _tracedPolylinePoints,
          color: Colors.grey, // Temporary preview color.
          width: 5,
        );
      });
    }
    // (No action for non-tracing taps; old classification bottom sheet removed.)
  }

  // Function to load custom marker icons using AssetMapBitmap.
  Future<void> _loadCustomMarkers() async {
    final ImageConfiguration configuration =
        createLocalImageConfiguration(context);
    try {
      walkingConnector = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_motion/square_marker_teal.png',
        width: 24,
        height: 24,
      );
      runningConnector = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_motion/square_marker_red.png',
        width: 24,
        height: 24,
      );
      swimmingConnector = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_motion/square_marker_cyan.png',
        width: 24,
        height: 24,
      );
      wheelsConnector = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_motion/square_marker_orange.png',
        width: 24,
        height: 24,
      );
      handicapConnector = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_motion/square_marker_purple.png',
        width: 24,
        height: 24,
      );
      tempMarkerIcon = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_motion/polyline_marker4.png',
        width: 48,
        height: 48,
      );
      setState(() {
        _customMarkersLoaded = true;
      });
      print("Custom markers loaded successfully.");
    } catch (e) {
      print("Error loading custom markers: $e");
    }
  }

  // --- Tracing Mode Bottom Sheet (Persistent) ---
  void _showTracingConfirmationSheet() {
    // Use the scaffold key to show a persistent bottom sheet.
    _tracingSheetController = _scaffoldKey.currentState?.showBottomSheet(
      (context) {
        return Container(
          color: Color(0xFFDDE6F2),
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Cancel: dismiss the sheet, remove temporary markers and polyline, and disable tracing mode.
                  for (final id in _currentTracingMarkerIds) {
                    _markers
                        .removeWhere((marker) => marker.markerId.value == id);
                  }
                  setState(() {
                    _currentTracingMarkerIds.clear();
                    _tracedPolylinePoints.clear();
                    _tempPolyline = null;
                    _isTracingMode = false;
                  });
                  _tracingSheetController?.close();
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Confirm: dismiss the sheet and show activity selection.
                  _tracingSheetController?.close();
                  _showActivityDataSheet();
                },
                child: Text('Confirm'),
              ),
            ],
          ),
        );
      },
      backgroundColor: Colors.transparent,
    );
  }

  // --- Activity Data Bottom Sheet ---
  void _showActivityDataSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFFDDE6F2),
      builder: (BuildContext context) {
        return PeopleInMotionDataSheet(
          onSubmit: (selectedActivity) {
            // Map the selected activity to its corresponding marker icon.
            BitmapDescriptor connectorIcon;
            switch (selectedActivity) {
              case 'Walking':
                connectorIcon =
                    walkingConnector ?? BitmapDescriptor.defaultMarker;
                break;
              case 'Running':
                connectorIcon =
                    runningConnector ?? BitmapDescriptor.defaultMarker;
                break;
              case 'Swimming':
                connectorIcon =
                    swimmingConnector ?? BitmapDescriptor.defaultMarker;
                break;
              case 'Activity on Wheels':
                connectorIcon =
                    wheelsConnector ?? BitmapDescriptor.defaultMarker;
                break;
              case 'Handicap Assisted Wheels':
                connectorIcon =
                    handicapConnector ?? BitmapDescriptor.defaultMarker;
                break;
              default:
                connectorIcon = BitmapDescriptor.defaultMarker;
            }

            // Generate a unique route ID.
            final String routeId =
                DateTime.now().millisecondsSinceEpoch.toString();
            final polylineId = PolylineId(routeId);

            // Now, update the markers for the current tracing session to keep only the first and last markers.
            setState(() {
              _markers.removeWhere((marker) =>
                  _currentTracingMarkerIds.contains(marker.markerId.value));
              _currentTracingMarkerIds.clear();

              // If there are traced points, create start and end markers with IDs based on routeId.
              if (_tracedPolylinePoints.isNotEmpty) {
                final LatLng firstPoint = _tracedPolylinePoints.first;
                final LatLng lastPoint = _tracedPolylinePoints.last;

                final String startMarkerId = "start_$routeId";
                final String endMarkerId = "end_$routeId";

                _markers.addAll([
                  Marker(
                    markerId: MarkerId(startMarkerId),
                    position: firstPoint,
                    icon: connectorIcon,
                    anchor: Offset(0.5, 0.5),
                  ),
                  Marker(
                    markerId: MarkerId(
                        "end_${DateTime.now().millisecondsSinceEpoch}"),
                    position: lastPoint,
                    icon: connectorIcon,
                    anchor: Offset(0.5, 0.5),
                  ),
                ]);

                // Store these marker IDs in the map
                _routeMarkerIds[routeId] = [startMarkerId, endMarkerId];
              }

              // Remove the temporary tracing polyline and add a colored one.
              _confirmedPolylines
                  .removeWhere((poly) => poly.polylineId.value == "tracing");
              final polylineId =
                  PolylineId(DateTime.now().millisecondsSinceEpoch.toString());
              _confirmedPolylines.add(
                Polyline(
                  polylineId: polylineId,
                  points: List<LatLng>.from(_tracedPolylinePoints),
                  // Define colors for each activity type.
                  color: {
                        'Walking': Colors.teal,
                        'Running': Colors.red,
                        'Swimming': Colors.cyan,
                        'Activity on Wheels': Colors.orange,
                        'Handicap Assisted Wheels': Colors.purple,
                      }[selectedActivity] ??
                      Colors.black,
                  width: 5,
                ),
              );

              final tracedRoute = TracedRoute(
                points: List<LatLng>.from(_tracedPolylinePoints),
                activityType: selectedActivity,
                timestamp: DateTime.now(),
              );
              _confirmedRoutes.add(tracedRoute);

              saveTracedRoute(
                test: widget.activeTest,
                tracedRouteData: tracedRoute.toJson(),
              );

              _tracedPolylinePoints.clear();
              _tempPolyline = null;
              _isTracingMode = false;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Combine confirmed polylines with the temporary one (if any)
    final Set<Polyline> allPolylines = _confirmedPolylines.union(
      _tempPolyline != null ? {_tempPolyline!} : {},
    );

    // Determine which set of points to display in the points menu.
    final List<LatLng> displayedPoints = _tracedPolylinePoints.isNotEmpty
        ? _tracedPolylinePoints
        : _loggedPoints;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle:
            SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        // Start/End button on the left.
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: _isTestRunning ? Colors.red : Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () {
              if (_isTestRunning) {
                Navigator.pop(context);
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(
              _isTestRunning ? 'End' : 'Start',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        // Persistent prompt in the middle.
        title: _isTracingMode
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tap the screen to trace',
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
            : null,
        centerTitle: true,
        // Timer on the right.
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Full-screen map with polylines.
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 14.0,
            ),
            markers: _markers,
            polygons: _polygons,
            polylines: allPolylines,
            onTap: _handleMapTap,
            mapType: _currentMapType,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          if (_showErrorMessage)
            Positioned(
              bottom: 100.0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Please place points inside the boundary.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          // Overlaid button for toggling map type.
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 8.0,
            right: 20.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7EAD80).withValues(alpha: 0.9),
                border: Border.all(color: Color(0xFF2D6040), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Center(
                  child: Icon(Icons.layers, color: Color(0xFF2D6040)),
                ),
                onPressed: _toggleMapType,
              ),
            ),
          ),
          // Overlaid button for toggling instructions.
          if (!_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 70.0,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFBACFEB).withValues(alpha: 0.9),
                  border: Border.all(color: Color(0xFF37597D), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(FontAwesomeIcons.info, color: Color(0xFF37597D)),
                  onPressed: _showInstructionOverlay,
                ),
              ),
            ),
          // Overlaid button for toggling points menu.
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 132.0,
            right: 20.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFBD9FE4).withValues(alpha: 0.9),
                border: Border.all(color: Color(0xFF5A3E85), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(FontAwesomeIcons.locationDot,
                    color: Color(0xFF5A3E85)),
                onPressed: () {
                  setState(() {
                    _isPointsMenuVisible = !_isPointsMenuVisible;
                  });
                },
              ),
            ),
          ),
          // Overlaid button for activating tracing mode.
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 194.0,
            right: 20.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF9800).withValues(alpha: 0.9),
                border: Border.all(color: Color(0xFF8C2F00), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(FontAwesomeIcons.pen, color: Color(0xFF8C2F00)),
                onPressed: _isTracingMode
                    ? null
                    : () {
                        setState(() {
                          _isTracingMode = true;
                          _tracedPolylinePoints.clear();
                          _currentTracingMarkerIds.clear();
                          _confirmedPolylines.removeWhere(
                              (poly) => poly.polylineId.value == "tracing");
                        });
                        _showTracingConfirmationSheet();
                      },
              ),
            ),
          ),
          // Points menu bottom sheet.
          if (_isPointsMenuVisible)
            Positioned(
              bottom: 135.0,
              left: 20.0,
              right: 20.0,
              child: Container(
                // Set a fixed or dynamic height as needed.
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                    color: Color(0xFFDDE6F2).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(0xFF2F6DCF),
                      width: 2,
                    )),
                padding: EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Route Color Guide",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: activityColorsRow(),
                    ),
                    SizedBox(height: 16),
                    Divider(
                      height: 1,
                      thickness: 1.5,
                      color: Color(0xFF2F6DCF),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _confirmedPolylines.length,
                        itemBuilder: (context, index) {
                          final route = _confirmedRoutes[index];
                          final instanceNumber = _confirmedRoutes
                              .take(index + 1)
                              .where(
                                  (r) => r.activityType == route.activityType)
                              .length;
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            title: Text(
                              '${route.activityType} Route $instanceNumber',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Points: ${route.points.length}',
                              textAlign: TextAlign.left,
                            ),
                            trailing: IconButton(
                              icon: const Icon(FontAwesomeIcons.trashCan,
                                  color: Color(0xFFD32F2F)),
                              onPressed: () {
                                setState(() {
                                  // Retrieve the route ID from the polyline's id.
                                  // OLD: String routeId = polyline.polylineId.value; (Change back if necessary)
                                  String routeId =
                                      route.timestamp.toIso8601String();
                                  // Remove associated markers for this route.
                                  if (_routeMarkerIds.containsKey(routeId)) {
                                    for (var markerId
                                        in _routeMarkerIds[routeId]!) {
                                      _markers.removeWhere((marker) =>
                                          marker.markerId.value == markerId);
                                    }
                                    _routeMarkerIds.remove(routeId);
                                  }

                                  // Remove the associated polyline from _confirmedPolylines
                                  _confirmedPolylines.removeWhere((polyline) =>
                                      polyline.polylineId.value == routeId);

                                  _confirmedRoutes.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    // Bottom row with only a Clear All button.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFD32F2F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                // Clear all confirmed polylines.
                                _confirmedPolylines.clear();
                                // Remove start/end markers from the markers set.
                                _markers.removeWhere((marker) =>
                                    marker.markerId.value
                                        .startsWith("start_") ||
                                    marker.markerId.value.startsWith("end_"));
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

// --- PeopleInMotionDataSheet for activity selection ---
class PeopleInMotionDataSheet extends StatefulWidget {
  final Function(String) onSubmit;
  const PeopleInMotionDataSheet({Key? key, required this.onSubmit})
      : super(key: key);

  @override
  State<PeopleInMotionDataSheet> createState() =>
      _PeopleInMotionDataSheetState();
}

class _PeopleInMotionDataSheetState extends State<PeopleInMotionDataSheet> {
  String? _selectedActivity;

  // Build a button for each activity type.
  Widget _buildActivityButton(String activity) {
    final bool isSelected = activity == _selectedActivity;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextButton(
        onPressed: () {
          setState(() {
            _selectedActivity = activity;
          });
        },
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(activity),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Adjust for keyboard.
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row.
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: const Text(
                        'Data',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(width: 48)
                ],
              ),
              const SizedBox(height: 20),
              // Activity type label.
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Activity type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              // Activity selection buttons.
              Column(
                children: [
                  _buildActivityButton('Walking'),
                  _buildActivityButton('Running'),
                  _buildActivityButton('Swimming'),
                  _buildActivityButton('Activity on Wheels'),
                  _buildActivityButton('Handicap Assisted Wheels'),
                ],
              ),
              const SizedBox(height: 20),
              // Submit button.
              ElevatedButton(
                onPressed: () {
                  if (_selectedActivity != null) {
                    widget.onSubmit(_selectedActivity!);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
