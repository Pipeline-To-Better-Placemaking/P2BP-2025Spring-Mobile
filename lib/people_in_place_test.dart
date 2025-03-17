import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'google_maps_functions.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:p2bp_2025spring_mobile/firestore_functions.dart';
import 'package:p2bp_2025spring_mobile/db_schema_classes.dart';
import 'package:p2bp_2025spring_mobile/project_details_page.dart';
import 'package:p2bp_2025spring_mobile/people_in_place_instructions.dart';

class PeopleInPlaceTestPage extends StatefulWidget {
  final Project activeProject;
  final PeopleInPlaceTest activeTest;

  const PeopleInPlaceTestPage({
    super.key,
    required this.activeProject,
    required this.activeTest,
  });

  @override
  State<PeopleInPlaceTestPage> createState() => _PeopleInPlaceTestPageState();
}

// IMPORTANT!!!
// The amount and order of strings in each category below MUST match exactly
// with those in the enumerated types for each defined in db_schema_classes.
const List<String> _ageRangeStrings = [
  '0-14',
  '15-21',
  '22-30',
  '30-50',
  '50-65',
  '65+',
];
const List<String> _genderStrings = [
  'Male',
  'Female',
  'Nonbinary',
  'Unspecified',
];
const List<String> _activityStrings = [
  'Socializing',
  'Waiting',
  'Recreation',
  'Eating',
  'Solitary'
];
const List<String> _postureStrings = [
  'Standing',
  'Sitting',
  'Laying Down',
  'Squatting',
];

class _PeopleInPlaceTestPageState extends State<PeopleInPlaceTestPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late GoogleMapController mapController;
  LatLng _currentLocation = defaultLocation; // Default location
  bool _isLoading = true;
  Timer? _hintTimer;
  bool _showHint = false;
  bool _isTestRunning = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  Set<Marker> _markers = {}; // Set of markers for points
  Set<Polygon> _polygons = {}; // Set of polygons
  MapType _currentMapType = MapType.normal; // Default map type
  bool _showErrorMessage = false;
  bool _isPointsMenuVisible = false;
  List<LatLng> _loggedPoints = [];

  // List to store backend‑compatible logged data points.
  final PeopleInPlaceData _newData = PeopleInPlaceData();

  // Custom marker icons

  // Male Markers
  BitmapDescriptor? standingMaleMarker;
  BitmapDescriptor? sittingMaleMarker;
  BitmapDescriptor? layingMaleMarker;
  BitmapDescriptor? squattingMaleMarker;

  // Female Markers
  BitmapDescriptor? standingFemaleMarker;
  BitmapDescriptor? sittingFemaleMarker;
  BitmapDescriptor? layingFemaleMarker;
  BitmapDescriptor? squattingFemaleMarker;

  // N/A Markers
  BitmapDescriptor? standingNAMarker;
  BitmapDescriptor? sittingNAMarker;
  BitmapDescriptor? layingNAMarker;
  BitmapDescriptor? squattingNAMarker;
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

  // Function to load custom marker icons using AssetMapBitmap.
  Future<void> _loadCustomMarkers() async {
    final ImageConfiguration configuration =
        createLocalImageConfiguration(context);
    try {
      standingMaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/standing_male_marker.png',
        width: 36,
        height: 36,
      );
      sittingMaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/sitting_male_marker.png',
        width: 36,
        height: 36,
      );
      layingMaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/laying_male_marker.png',
        width: 36,
        height: 36,
      );
      squattingMaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/squatting_male_marker.png',
        width: 36,
        height: 36,
      );
      standingFemaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/standing_female_marker.png',
        width: 36,
        height: 36,
      );
      sittingFemaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/sitting_female_marker.png',
        width: 36,
        height: 36,
      );
      layingFemaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/laying_female_marker.png',
        width: 36,
        height: 36,
      );
      squattingFemaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/squatting_female_marker.png',
        width: 36,
        height: 36,
      );
      standingNAMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/standing_na_marker.png',
        width: 36,
        height: 36,
      );
      sittingNAMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/sitting_na_marker.png',
        width: 36,
        height: 36,
      );
      layingNAMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/laying_na_marker.png',
        width: 36,
        height: 36,
      );
      squattingNAMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/squatting_na_marker.png',
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
            style: TextStyle(
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: screenSize.width * 0.95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  peopleInPlaceInstructions(),
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

  void _resetHintTimer() {
    // Cancel any existing timer.
    _hintTimer?.cancel();
    // Hide the hint if it was showing.
    setState(() {
      _showHint = false;
    });
    // Start a new timer.
    _hintTimer = Timer(Duration(seconds: 10), () {
      setState(() {
        _showHint = true;
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() {
      if (widget.activeProject.polygonPoints.isNotEmpty) {
        _polygons = getProjectPolygon(widget.activeProject.polygonPoints);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final bounds = _getPolygonBounds(
              widget.activeProject.polygonPoints.toLatLngList());
          mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        });
      } else {
        _moveToCurrentLocation(); // Ensure the map is centered on the current location
      }
    });
  }

  Future<void> _checkAndFetchLocation() async {
    try {
      _currentLocation = await checkAndFetchLocation();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      // Delay popup till after the map has loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInstructionOverlay();
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
      false, // Edge considered outside; change as needed.
    );
  }

  BitmapDescriptor _getMarkerIcon(String key) {
    switch (key) {
      case 'standing_male':
        return standingMaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'sitting_male':
        return sittingMaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'layingDown_male':
        return layingMaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'squatting_male':
        return squattingMaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'standing_female':
        return standingFemaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'sitting_female':
        return sittingFemaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'layingDown_female':
        return layingFemaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'squatting_female':
        return squattingFemaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'standing_nonbinary' || 'standing_unspecified':
        return standingNAMarker ?? BitmapDescriptor.defaultMarker;
      case 'sitting_nonbinary' || 'sitting_unspecified':
        return sittingNAMarker ?? BitmapDescriptor.defaultMarker;
      case 'layingDown_nonbinary' || 'layingDown_unspecified':
        return layingNAMarker ?? BitmapDescriptor.defaultMarker;
      default:
        return squattingNAMarker ?? BitmapDescriptor.defaultMarker;
    }
  }

  // Tap handler for People In Place
  Future<void> _handleMapTap(LatLng point) async {
    _resetHintTimer();
    // Check if tapped point is inside the polygon boundary.
    bool inside = _isPointInsidePolygon(
        point, widget.activeProject.polygonPoints.toLatLngList());
    if (!inside) {
      // If outside, show error message.
      setState(() {
        _showErrorMessage = true;
      });
      Timer(Duration(seconds: 3), () {
        setState(() {
          _showErrorMessage = false;
        });
      });
      return; // Do not proceed with logging the data point.
    }
    // Check if custom markers are loaded
    if (!_customMarkersLoaded) {
      print("Custom markers not loaded yet. Please wait.");
      return; // Prevent creating markers if not loaded
    }
    // Show bottom sheet for classification
    final PersonInPlace? person = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFFDDE6F2),
      builder: (context) => _DescriptionForm(location: point),
    );
    if (person == null) return;

    final MarkerId markerId = MarkerId(point.toString());

    final key = '${person.posture.name}_${person.gender.name}';
    BitmapDescriptor markerIcon = _getMarkerIcon(key);

    // Once classification data is provided, add the marker with an info window.
    setState(() {
      _markers.add(
        Marker(
          markerId: markerId,
          position: point,
          icon: markerIcon,
          infoWindow: InfoWindow(
              title:
                  'Age: ${_ageRangeStrings[person.ageRange.index]}', // for example
              snippet: 'Gender: ${_genderStrings[person.gender.index]}\n'
                  'Activity: ${[
                for (final activity in person.activities)
                  _activityStrings[activity.index]
              ]}\n'
                  'Posture: ${_postureStrings[person.posture.index]}'),
          onTap: () {
            // Print for debugging:
            print("Marker tapped: $markerId");
            // Use a short delay to ensure the marker is rendered,
            // then show its info window using the same markerId.
            if (_openMarkerId == markerId) {
              mapController.hideMarkerInfoWindow(markerId);
              setState(() {
                _openMarkerId = null;
              });
            } else {
              Future.delayed(Duration(milliseconds: 300), () {
                mapController.showMarkerInfoWindow(markerId);
                setState(() {
                  _openMarkerId = markerId;
                });
              });
            }
          },
        ),
      );

      _newData.persons.add(person);
    });
  }

  // Helper method to format elapsed seconds into mm:ss
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Method to start the test and timer
  void _startTest() {
    setState(() {
      _isTestRunning = true;
      _remainingSeconds = 300;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          timer.cancel();
          // TODO: end test/submit data or something?
        }
      });
    });
  }

  void _endTest() {
    widget.activeTest.submitData(_newData);
    Navigator.pop(context);
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
        leadingWidth: 100,
        // Start/End button on the left
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20), // Rounded rectangle shape.
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
        // Persistent prompt in the middle with a translucent background.
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Tap to log data point',
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        centerTitle: true,
        // Timer on the right
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
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen map.
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 14.0,
            ),
            markers: _markers,
            polygons: _polygons,
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
          if (_isPointsMenuVisible)
            Positioned(
              bottom: 220.0,
              left: 20.0,
              right: 20.0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: BoxDecoration(
                  color: Color(0xFFDDE6F2).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(0xFF2F6DCF),
                    width: 2,
                  ),
                ),
                padding: EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Marker Color Guide",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: activityColorsRow(),
                    ),
                    Divider(
                      height: 20,
                      thickness: 2,
                      color: Color(0xFF2F6DCF),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _loggedPoints.length,
                        itemBuilder: (context, index) {
                          final point = _loggedPoints[index];
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
                              icon: const Icon(FontAwesomeIcons.trashCan,
                                  color: Color(0xFFD32F2F)),
                              onPressed: () {
                                setState(() {
                                  // Construct the markerId the same way it was created.
                                  final markerId = MarkerId(point.toString());
                                  // Remove the marker from the markers set.
                                  _markers.removeWhere(
                                      (marker) => marker.markerId == markerId);
                                  // Remove the point from the list.
                                  _loggedPoints.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
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
                                // Clear all logged points.
                                _loggedPoints.clear();
                                // Remove all associated markers.
                                _markers.clear();
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

class _DescriptionForm extends StatefulWidget {
  final LatLng location;

  const _DescriptionForm({super.key, required this.location});

  @override
  State<_DescriptionForm> createState() => _DescriptionFormState();
}

class _DescriptionFormState extends State<_DescriptionForm> {
  static const TextStyle boldTextStyle = TextStyle(fontWeight: FontWeight.bold);

  int? _selectedAgeRange;
  int? _selectedGender;
  final List<bool> _selectedActivities =
      List.of([for (final _ in _activityStrings) false], growable: false);
  int? _selectedPosture;

  void _submitDescription() {
    final PersonInPlace person;

    // Converts activity bool list to type set
    List<ActivityType> types = ActivityType.values;
    Set<ActivityType> activities = {};
    for (int i = 0; i < types.length; i += 1) {
      if (_selectedActivities[i]) {
        activities.add(types[i]);
      }
    }

    person = PersonInPlace(
      location: widget.location,
      ageRange: AgeRangeType.values[_selectedAgeRange!],
      gender: GenderType.values[_selectedGender!],
      activities: activities,
      posture: PostureType.values[_selectedPosture!],
    );
    print(person);

    Navigator.pop(context, person);
  }

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
              // Centered header text.
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Data',
                        style: boldTextStyle.copyWith(fontSize: 24),
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Age group.
                  Text(
                    'Age',
                    style: boldTextStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List<Widget>.generate(
                      _ageRangeStrings.length,
                      (index) {
                        return ChoiceChip(
                          label: Text(_ageRangeStrings[index]),
                          selected: _selectedAgeRange == index,
                          onSelected: (selected) {
                            setState(() {
                              _selectedAgeRange = selected ? index : null;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Gender group.
                  Text(
                    'Gender',
                    style: boldTextStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: List<Widget>.generate(
                      _genderStrings.length,
                      (index) {
                        return ChoiceChip(
                          label: Text(_genderStrings[index]),
                          selected: _selectedGender == index,
                          onSelected: (selected) {
                            setState(() {
                              _selectedGender = selected ? index : null;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Activity group.
                  Text(
                    'Activity',
                    style: boldTextStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: List<Widget>.generate(
                      _activityStrings.length,
                      (index) {
                        return FilterChip(
                          label: Text(_activityStrings[index]),
                          selected: _selectedActivities[index],
                          onSelected: (selected) {
                            setState(() {
                              _selectedActivities[index] =
                                  !_selectedActivities[index];
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Posture group.
                  Text(
                    'Posture',
                    style: boldTextStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: List<Widget>.generate(
                      _postureStrings.length,
                      (index) {
                        return ChoiceChip(
                          label: Text(_postureStrings[index]),
                          selected: _selectedPosture == index,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPosture = selected ? index : null;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (_selectedAgeRange != null &&
                        _selectedGender != null &&
                        _selectedActivities.contains(true) &&
                        _selectedPosture != null)
                    ? _submitDescription
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

class ChipLabelColor extends Color implements WidgetStateColor {
  const ChipLabelColor() : super(_default);

  static const int _default = 0xFF000000;

  @override
  Color resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return Colors.white;
    }
    return Colors.black;
  }
}
