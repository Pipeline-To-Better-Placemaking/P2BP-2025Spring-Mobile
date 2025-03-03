import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show
        AssetMapBitmap,
        BitmapDescriptor,
        CameraPosition,
        CameraUpdate,
        GoogleMap,
        GoogleMapController,
        InfoWindow,
        LatLng,
        LatLngBounds,
        MapType,
        Marker,
        MarkerId,
        Polygon,
        Polyline,
        PolylineId,
        createLocalImageConfiguration;
import 'package:shared_preferences/shared_preferences.dart';
import 'google_maps_functions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

class PeopleInMotionTest extends StatefulWidget {
  final List<LatLng> polygonPoints;
  final Set<Polygon> polygon;
  const PeopleInMotionTest({
    Key? key,
    required this.polygonPoints,
    required this.polygon,
  }) : super(key: key);

  @override
  State<PeopleInMotionTest> createState() => _PeopleInMotionTestState();
}

class _PeopleInMotionTestState extends State<PeopleInMotionTest> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late GoogleMapController mapController;
  LatLng _currentLocation = defaultLocation; // Default location
  bool _isLoading = true;
  Timer? _hintTimer;
  bool _showHint = false;
  bool _isTestRunning = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  Set<Marker> _markers = {}; // Set of markers for points
  MapType _currentMapType = MapType.normal; // Default map type
  bool _showErrorMessage = false;
  bool _isPointsMenuVisible = false;
  List<LatLng> _loggedPoints = [];

  // --- New Tracing Mode State ---
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
  bool _customMarkersLoaded = false;

  MarkerId? _openMarkerId;

  @override
  void initState() {
    super.initState();
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
      _elapsedSeconds = 0;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  // Method to end the test and cancel the timer.
  void _endTest() {
    setState(() {
      _isTestRunning = false;
    });
    _timer?.cancel();
  }

  void _showInstructionOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Instructions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isTracingMode
                  ? 'Tracing mode active. Tap the map to draw your path.'
                  : 'Tap to log data point.'),
              Row(
                children: [
                  Checkbox(
                    value: false,
                    onChanged: (_) {},
                  ),
                  Text("Don't show this again"),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
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
    if (widget.polygonPoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final bounds = _getPolygonBounds(widget.polygonPoints);
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
    if (!_isPointInsidePolygon(point, widget.polygonPoints)) {
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
      BitmapDescriptor connectorIcon;
      // Using a different hue for temporary markers.
      final Marker marker = Marker(
        markerId: markerId,
        position: point,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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
        'assets/custom_icons/square_marker_red.png',
        width: 36,
        height: 36,
      );
      swimmingConnector = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_motion/square_marker_cyan.png',
        width: 36,
        height: 36,
      );
      wheelsConnector = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_motion/square_marker_orange.png',
        width: 36,
        height: 36,
      );
      handicapConnector = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_motion/square_marker_purple.png',
        width: 36,
        height: 36,
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
                  // Cancel: dismiss the sheet and disable tracing mode.
                  // Cancel: remove temporary markers and polyline, then disable tracing.
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

            // Now update the markers for the current tracing session to use the custom icon.
            final updatedMarkers = _markers.map((marker) {
              if (_currentTracingMarkerIds.contains(marker.markerId.value)) {
                // Create a new marker with the same position but with the new icon.
                return Marker(
                    markerId: marker.markerId,
                    position: marker.position,
                    icon: connectorIcon,
                    anchor: Offset(0.5, 0.98));
              }
              return marker;
            }).toSet();

            // Define colors for each activity type.
            final Map<String, Color> activityColors = {
              'Walking': Colors.teal,
              'Running': Colors.red,
              'Swimming': Colors.cyan,
              'Activity on Wheels': Colors.orange,
              'Handicap Assisted Wheels': Colors.purple,
            };

            // Remove the temporary tracing polyline and add a colored one.
            setState(() {
              _markers = updatedMarkers;
              _confirmedPolylines
                  .removeWhere((poly) => poly.polylineId.value == "tracing");
              final polylineId =
                  PolylineId(DateTime.now().millisecondsSinceEpoch.toString());
              _confirmedPolylines.add(
                Polyline(
                  polylineId: polylineId,
                  points: List<LatLng>.from(_tracedPolylinePoints),
                  color: activityColors[selectedActivity] ?? Colors.black,
                  width: 5,
                ),
              );
              // Optionally, update the points menu with traced points.
              _loggedPoints.addAll(_tracedPolylinePoints);
              _tracedPolylinePoints.clear();
              _currentTracingMarkerIds.clear();
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
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _isTracingMode
                ? 'Tracing mode: tap to trace path'
                : 'Tap to log data point',
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
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
                  _formatTime(_elapsedSeconds),
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
            polygons: widget.polygon,
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
          // Overlayed button for toggling map type.
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 8.0,
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
                icon: Center(
                  child: Icon(Icons.layers, color: Colors.white),
                ),
                onPressed: _toggleMapType,
              ),
            ),
          ),
          // Overlayed button for toggling instructions.
          if (!_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 70.0,
              right: 20,
              child: Container(
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
                  icon: Icon(FontAwesomeIcons.info, color: Colors.white),
                  onPressed: _showInstructionOverlay,
                ),
              ),
            ),
          // Overlayed button for toggling points menu.
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 132.0,
            right: 20.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(FontAwesomeIcons.locationDot, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isPointsMenuVisible = !_isPointsMenuVisible;
                  });
                },
              ),
            ),
          ),
          // NEW: Overlayed button for activating tracing mode.
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 194.0,
            right: 20.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.brown,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(FontAwesomeIcons.pen, color: Colors.white),
                onPressed: () {
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
              bottom: 220.0,
              left: 20.0,
              right: 20.0,
              child: Container(
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
                        itemCount: displayedPoints.length,
                        itemBuilder: (context, index) {
                          final point = displayedPoints[index];
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            title: Text(
                              'Point ${index + 1}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                              textAlign: TextAlign.left,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  if (_tracedPolylinePoints.isNotEmpty) {
                                    _tracedPolylinePoints.removeAt(index);
                                    _tempPolyline =
                                        _tracedPolylinePoints.isNotEmpty
                                            ? Polyline(
                                                polylineId: PolylineId("temp"),
                                                points: _tracedPolylinePoints,
                                                color: Colors.grey,
                                                width: 5,
                                              )
                                            : null;
                                  } else {
                                    final markerId = MarkerId(point.toString());
                                    _markers.removeWhere((marker) =>
                                        marker.markerId == markerId);
                                    _loggedPoints.removeAt(index);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
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
