import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/firestore_functions.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'google_maps_functions.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:p2bp_2025spring_mobile/db_schema_classes.dart';
import 'package:p2bp_2025spring_mobile/project_details_page.dart';
import 'package:p2bp_2025spring_mobile/people_in_motion_instructions.dart';

class PeopleInMotionTestPage extends StatefulWidget {
  final Project activeProject;
  final PeopleInMotionTest activeTest;

  const PeopleInMotionTestPage({
    super.key,
    required this.activeProject,
    required this.activeTest,
  });

  @override
  State<PeopleInMotionTestPage> createState() => _PeopleInMotionTestPageState();
}

class _PeopleInMotionTestPageState extends State<PeopleInMotionTestPage> {
  late GoogleMapController mapController;
  LatLng _currentLocation = defaultLocation; // Default location
  bool _isLoading = true;
  Timer? _hintTimer;
  bool _showHint = false;
  bool _isTestRunning = false;
  bool _isTracingMode = false;
  bool _showErrorMessage = false;
  bool _isPointsMenuVisible = false;
  Timer? _timer;

  Set<Polygon> _polygons = {}; // Set of polygons
  MapType _currentMapType = MapType.normal; // Default map type

  // Set of markers when drawing polyline
  Set<Marker> _polylineMarkers = {};
  // List of points when drawing polyline, should match _polylineMarkers
  List<LatLng> _polylinePoints = [];
  // Temporary polyline shown during the current tracing session
  Polyline? _tempPolyline;
  // Set of polylines created during this test
  Set<Polyline> _polylines = {};

  // // Confirmed polylines persist from previous sessions.
  // Set<Polyline> _confirmedPolylines = {};

  final PeopleInMotionData _newData = PeopleInMotionData();

  // Custom marker icons
  BitmapDescriptor? walkingConnector;
  BitmapDescriptor? runningConnector;
  BitmapDescriptor? swimmingConnector;
  BitmapDescriptor? wheelsConnector;
  BitmapDescriptor? handicapConnector;
  BitmapDescriptor? tempMarkerIcon;
  bool _customMarkersLoaded = false;

  // List<TracedRoute> _confirmedRoutes = [];
  // Map<String, List<String>> _routeMarkerIds = {};

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
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentLocation, zoom: 14.0),
      ),
    );
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
    if (!_isPointInsidePolygon(point, _polygons.first.toLatLngList())) {
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
      final markerId = MarkerId(point.toString());
      // Using a different hue for temporary markers.
      final Marker marker = Marker(
        markerId: markerId,
        position: point,
        icon: _customMarkersLoaded && tempMarkerIcon != null
            ? tempMarkerIcon!
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      setState(() {
        _polylinePoints.add(point);
        _polylineMarkers.add(marker);
      });

      // Append the tapped point to the traced polyline.
      Polyline? polyline = createPolyline(_polylinePoints, Colors.grey);
      if (polyline == null) {
        throw Exception('Failed to create Polyline from given points.');
      }

      setState(() {
        _tempPolyline = polyline;
      });
    }
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

  BitmapDescriptor _getMarkerIcon(ActivityTypeInMotion? key) {
    switch (key) {
      case ActivityTypeInMotion.walking:
        return walkingConnector ?? BitmapDescriptor.defaultMarker;
      case ActivityTypeInMotion.running:
        return runningConnector ?? BitmapDescriptor.defaultMarker;
      case ActivityTypeInMotion.swimming:
        return swimmingConnector ?? BitmapDescriptor.defaultMarker;
      case ActivityTypeInMotion.activityOnWheels:
        return wheelsConnector ?? BitmapDescriptor.defaultMarker;
      case ActivityTypeInMotion.handicapAssistedWheels:
        return handicapConnector ?? BitmapDescriptor.defaultMarker;
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _doActivityDataSheet() async {
    final ActivityTypeInMotion? activity = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFFDDE6F2),
      builder: (BuildContext context) => _ActivityForm(),
    );
    if (activity == null) return;

    // Map the selected activity to its corresponding marker icon.
    BitmapDescriptor connectorIcon = _getMarkerIcon(activity);

    // Create a data point from the polyline and activity
    _newData.persons.add(PersonInMotion(
      polyline: _tempPolyline!,
      activity: activity,
    ));

    setState(() {
      // Add polyline to set of finished ones
      _polylines.add(_tempPolyline!.copyWith(colorParam: activity.color));

      // Clear temp values previously holding polyline info and turn off tracing
      _polylinePoints.clear();
      _polylineMarkers.clear();
      _tempPolyline = null;
      _isTracingMode = false;
    });
  }

  // Helper method to format elapsed seconds into mm:ss.
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _startTest() {
    setState(() {
      _isTestRunning = true;
      _remainingSeconds = 300; // Reset countdown value
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      // TODO: extract the timer and necessary functionality to its own
      // stateful widget to stop this from forcing the whole screen to
      // need to rebuild every second.
      setState(() {
        if (_remainingSeconds <= 0) {
          timer.cancel();
        }
        _remainingSeconds--;
      });
    });
  }

  void _endTest() async {
    _isTestRunning = false;
    _timer?.cancel();
    _hintTimer?.cancel();
    widget.activeTest.submitData(_newData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Determine which set of points to display in the points menu.
    // final List<LatLng> displayedPoints =
    //     _polylinePoints.isNotEmpty ? _polylinePoints : _loggedPoints;

    return Scaffold(
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
                _endTest();
              } else {
                _startTest();
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
            markers: _polylineMarkers,
            polygons: _polygons,
            polylines: {
              ..._polylines,
              if (_tempPolyline != null) _tempPolyline!
            },
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
                icon: Icon(
                  FontAwesomeIcons.pen,
                  color: Color(0xFF8C2F00),
                ),
                onPressed: _isTracingMode
                    ? null
                    : () {
                        setState(() {
                          _isTracingMode = true;
                          _polylinePoints.clear();
                          _polylineMarkers.clear();
                          _tempPolyline = null;
                        });
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
                      child: Text(
                        "Route Color Guide",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                        itemCount: _newData.persons.length,
                        itemBuilder: (context, index) {
                          final person = _newData.persons[index];
                          final instanceNumber = _newData.persons
                              .take(index + 1)
                              .where((r) => r.activity == person.activity)
                              .length;
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            title: Text(
                              '${person.activity} Route $instanceNumber',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Points: ${person.polyline.points.length}',
                              textAlign: TextAlign.left,
                            ),
                            trailing: IconButton(
                              icon: const Icon(FontAwesomeIcons.trashCan,
                                  color: Color(0xFFD32F2F)),
                              onPressed: () {
                                setState(() {
                                  // Retrieve the route ID from the polyline's id.
                                  // OLD: String routeId = polyline.polylineId.value; (Change back if necessary)
                                  // String routeId =
                                  //     person.timestamp.toIso8601String();
                                  // // Remove associated markers for this route.
                                  // if (_routeMarkerIds.containsKey(routeId)) {
                                  //   for (var markerId
                                  //       in _routeMarkerIds[routeId]!) {
                                  //     _polylineMarkers.removeWhere((marker) =>
                                  //         marker.markerId.value == markerId);
                                  //   }
                                  //   _routeMarkerIds.remove(routeId);
                                  // }

                                  // // Remove the associated polyline from _confirmedPolylines
                                  // _confirmedPolylines.removeWhere((polyline) =>
                                  //     polyline.polylineId.value == routeId);

                                  // _confirmedRoutes.removeAt(index);
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
                                // _confirmedPolylines.clear();
                                // Remove start/end markers from the markers set.
                                // _polylineMarkers.removeWhere((marker) =>
                                //     marker.markerId.value
                                //         .startsWith("start_") ||
                                //     marker.markerId.value.startsWith("end_"));
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
      bottomSheet: (_isTracingMode)
          ? Container(
              color: Color(0xFFDDE6F2),
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Cancel: dismiss sheet, remove temp points for current
                      // polyline, and disable tracing mode.
                      setState(() {
                        _polylinePoints.clear();
                        _polylineMarkers.clear();
                        _tempPolyline = null;
                        _isTracingMode = false;
                      });
                    },
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        (_polylinePoints.length > 1 && _tempPolyline != null)
                            ? () {
                                // Confirm: dismiss sheet and show activity selection.
                                _doActivityDataSheet();
                              }
                            : null,
                    child: Text('Confirm'),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _ActivityForm extends StatefulWidget {
  const _ActivityForm();

  @override
  State<_ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<_ActivityForm> {
  ActivityTypeInMotion? _selectedActivity;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Theme(
        data: theme.copyWith(
          chipTheme: theme.chipTheme.copyWith(
            showCheckmark: false,
            backgroundColor: Colors.grey[200],
            selectedColor: Colors.blue,
            labelStyle: TextStyle(
              color: ChipLabelColor(),
              fontWeight: FontWeight.bold,
            ),
            side: BorderSide.none,
          ),
        ),
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
                children: List<Widget>.generate(
                    ActivityTypeInMotion.values.length, (index) {
                  final List activities = ActivityTypeInMotion.values;
                  return ChoiceChip(
                    label: Text(activities[index].displayName),
                    selected: _selectedActivity == activities[index],
                    onSelected: (selected) {
                      setState(() {
                        _selectedActivity = selected ? activities[index] : null;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),
              // Submit button.
              ElevatedButton(
                onPressed: (_selectedActivity != null)
                    ? () => Navigator.pop(context, _selectedActivity)
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
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
