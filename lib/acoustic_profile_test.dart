import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/db_schema_classes.dart';
import 'package:p2bp_2025spring_mobile/firestore_functions.dart';
import 'package:p2bp_2025spring_mobile/google_maps_functions.dart';
import 'package:p2bp_2025spring_mobile/project_details_page.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/acoustic_instructions.dart'; // for _showInstructionOverlay

/// AcousticProfileTestPage displays a Google Map (with the project polygon)
/// in the background and uses a timer to prompt the researcher for sound
/// measurements at fixed intervals.
class AcousticProfileTestPage extends StatefulWidget {
  final Project activeProject;
  final AcousticProfileTest activeTest;

  const AcousticProfileTestPage({
    super.key,
    required this.activeProject,
    required this.activeTest,
  });

  @override
  State<AcousticProfileTestPage> createState() =>
      _AcousticProfileTestPageState();
}

/// Icon for a standing point that hasn't been measured yet
final AssetMapBitmap incompleteIcon = AssetMapBitmap(
  'assets/standing_point_disabled.png',
  width: 48,
  height: 48,
);

/// Icon for a standing point that has completed its measurement
final AssetMapBitmap completedIcon = AssetMapBitmap(
  'assets/standing_point_enabled.png',
  width: 48,
  height: 48,
);

/// Icon for a standing point that is actively being measured
final AssetMapBitmap activeIcon = AssetMapBitmap(
  'assets/standing_point_disabled.png',
  width: 48,
  height: 48,
);

class _AcousticProfileTestPageState extends State<AcousticProfileTestPage> {
  late GoogleMapController mapController;
  LatLng _currentLocation = defaultLocation; // Default location
  bool _isLoading = true;
  Timer? _intervalTimer;
  int _currentInterval = 0;
  Set<Polygon> _polygons = {};
  Set<Circle> _circles = <Circle>{};
  Set<Marker> _markers = {};
  List _standingPoints = [];
  final int _maxIntervals = 5; // Total number of intervals
  // List to store acoustic measurements for each interval.
  Map<int, List<AcousticMeasurement>> _measurementsPerPoint = {};
  List<bool> _completedStandingPoints = [];
  // Timer (in seconds) for each interval (e.g. 4 seconds).
  final int _intervalDuration = 4;
  // Controls whether the test is running.
  bool _isTestRunning = false;
  MapType _currentMapType = MapType.normal;
  // Firestore instance.
  bool _showErrorMessage = false;
  int _remainingSeconds = 0;
  bool _isBottomSheetOpen = false;
  int? _selectedStandingPointIndex;

  @override
  void initState() {
    super.initState();
    // Center the map based on the project polygon.
    _initProjectArea();
    // Delay starting the interval timer until the map is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  void dispose() {
    _intervalTimer?.cancel();
    super.dispose();
  }

  /// Initializes the project area by setting up the polygon for the project,
  /// centering the map based on the polygon's centroid, creating markers for each
  /// standing point, and loading any pre-existing standing point data.
  void _initProjectArea() async {
    setState(() {
      _polygons = getProjectPolygon(widget.activeProject.polygonPoints);
      if (_polygons.isNotEmpty) {
        _currentLocation = getPolygonCentroid(_polygons.first);
        // Adjust the location slightly.
        _currentLocation = LatLng(
            _currentLocation.latitude * 0.999999, _currentLocation.longitude);
      }
      // TODO: dynamic zooming
      _markers = _setMarkersFromPoints(widget.activeTest.standingPoints);
      _standingPoints = widget.activeTest.standingPoints;
      print(_standingPoints);
      // Initialize the completion status for each standing point.
      _completedStandingPoints = List.filled(_standingPoints.length, false);
      _isLoading = false;
    });
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

  /// Toggle the map type between normal and satellite view.
  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
  }

  /// Initialize the map controller and adjust the camera:
  /// - If the project has defined polygon points, zoom to fit the project area.
  /// - Otherwise, center the map on the user's current location
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

  /// Create a marker for each standing point. Markers include an onTap callback
  /// that toggles selection (or deselection) if the marker's interval cycle hasn't been
  /// completed.
  Set<Marker> _setMarkersFromPoints(List points) {
    Set<Marker> markers = {};
    for (int i = 0; i < points.length; i++) {
      final Map point = points[i];
      final markerId = MarkerId(point.toString());

      // Choose the appropriate icon for this standing point based on its state:
      // - Use completedIcon if the measurement for this point is complete.
      // - Use activeIcon if this point is currently selected for measurement.
      // - Otherwise, use incompleteIcon to indicate it hasn't been measured yet.
      AssetMapBitmap markerIcon;
      if (_completedStandingPoints[i]) {
        markerIcon = completedIcon;
      } else if (_selectedStandingPointIndex == i) {
        markerIcon = activeIcon;
      } else {
        markerIcon = incompleteIcon;
      }

      markers.add(
        Marker(
          markerId: markerId,
          position: (point['point'] as GeoPoint).toLatLng(),
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: point['title'],
            snippet:
                '${point['point'].latitude.toStringAsFixed(5)}, ${point['point'].latitude.toStringAsFixed(5)}',
          ),
          onTap: () {
            // Only allow selection if the marker doesn't have a completed interval cycle.
            if (!_completedStandingPoints[i]) {
              setState(() {
                // Toggle marker selection: if the tapped marker is already selected, deselect it;
                // otherwise, select it.
                if (_selectedStandingPointIndex == i) {
                  // Deselect if tapped again.
                  _selectedStandingPointIndex = null;
                } else {
                  _selectedStandingPointIndex = i;
                }
              });
            }
          },
        ),
      );
    }
    return markers;
  }

  // Helper method to format elapsed seconds into mm:ss
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Starts the interval timer. Every [_intervalDuration] seconds, this timer
  /// pauses and launches the acoustic measurement sequence.
  void _startAcousticTest() {
    // Begin the acoustic test by setting the test running flag, resetting the interval counter,
    // and initializing the countdown timer.
    setState(() {
      _isTestRunning = true;
      _currentInterval = 0;
      _remainingSeconds =
          _intervalDuration; // Start the countdown at the interval duration.
    });

    _executeIntervalCycle();
  }

  /// Execute a single interval cycle:
  /// - Start a countdown using a periodic timer
  /// - Update the remaining seconds each tick.
  /// - Once the countdown reaches zero, trigger the bottom sheet sequence to collect data,
  ///   then move on to the next interval or end the cycle if all intervals are complete
  void _executeIntervalCycle() {
    // Record the exact start time for this interval.
    final DateTime intervalStart = DateTime.now();
    // Set the initial remaining time.
    setState(() {
      _remainingSeconds = _intervalDuration;
    });

    // Create a periodic timer that fires every second.
    _intervalTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      // Calculate elapsed seconds using the stored start time.
      final int elapsed = DateTime.now().difference(intervalStart).inSeconds;
      final int remaining = _intervalDuration - elapsed;

      // Update the remaining seconds for the UI.
      setState(() {
        _remainingSeconds = remaining;
      });

      // When the countdown reaches 0 or less, stop the timer and launch the measurement sequence.
      if (remaining <= 0) {
        timer.cancel();
        // Proceed with the asynchronous bottom sheet sequence.
        await _showAcousticBottomSheetSequence();
        _currentInterval++;

        // If there are still intervals left, restart the next inerval.
        if (_currentInterval < _maxIntervals) {
          _executeIntervalCycle();
        } else {
          // Cycle is complete.
          await _endTest();
        }
      }
    });
  }

  /// Displays a series of bottom sheets in sequence:
  /// 1. Sound Decibel Level input.
  /// 2. Sound Types multi-select.
  /// 3. Main Sound Type single-select.
  ///
  /// Each step collects data which is then stored as an AcousticMeasurement for the current
  /// standing point.
  Future<void> _showAcousticBottomSheetSequence() async {
    setState(() {
      _isBottomSheetOpen = true;
    });

    // 1. Bottom sheet for Sound Decibel Level.
    double? decibel;
    if (!mounted) return;
    decibel = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      backgroundColor: const Color(0xFFDDE6F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        final TextEditingController decibelController = TextEditingController();
        final _formKey = GlobalKey<FormState>();
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sound Decibel Level',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 250,
                      child: TextFormField(
                        textAlign: TextAlign.center,
                        controller: decibelController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 24),
                        decoration: InputDecoration(
                          label: Center(child: Text('Enter decibel value')),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a value';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: p2bpBlue),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context,
                            double.parse(decibelController.text.trim()));
                      }
                    },
                    child: const Text(
                      'Submit',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // If no decibel value was entered, default to 0.
    decibel ??= 0.0;

    // 2. Bottom sheet for Sound Types (multi-select).
    List<String> selectedSoundTypes = [];
    selectedSoundTypes = await showModalBottomSheet<List<String>>(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.5),
          backgroundColor: const Color(0xFFDDE6F2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          builder: (context) {
            // List of available sound types.
            final List<String> soundOptions = [
              'Water',
              'Traffic',
              'People',
              'Animals',
              'Wind',
              'Music'
            ];
            // Use a local set to track selection.
            final Set<String> selections = {};
            // Form key for input validation
            final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
            String? errorMessage;
            // Tracks user input for the other section.
            final TextEditingController _otherController =
                TextEditingController();
            bool isOtherSelected = false;
            _otherController.addListener(() {
              setState(() {});
            });

            return StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                  padding: MediaQuery.of(context).viewInsets,
                  child: Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Sound Types',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Select all of the sounds you heard during the measurement',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 3, // Three columns
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(), // Prevent scrolling inside the sheet
                            mainAxisSpacing: 1,
                            crossAxisSpacing: 2,
                            padding: const EdgeInsets.only(bottom: 8),
                            childAspectRatio:
                                2, // Adjust to change the height/width ratio of each cell
                            children: soundOptions.map((option) {
                              final bool isSelected =
                                  selections.contains(option);
                              return ChoiceChip(
                                label: Text(option),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      selections.add(option);
                                    } else {
                                      selections.remove(option);
                                    }
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(20), // Pill shape
                                  side: BorderSide(
                                    color: isSelected
                                        ? p2bpBlue
                                        : Color(
                                            0xFFB0C4DE), // Distinct border when selected
                                    width: 2.0,
                                  ),
                                ),
                                selectedColor: p2bpBlue
                                    .shade100, // Background color when selected
                                backgroundColor: Color(
                                    0xFFE3EBF4), // Default background color
                              );
                            }).toList(),
                          ),
                          // Other option text field and select button.
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                    controller: _otherController,
                                    decoration: InputDecoration(
                                      labelText: 'Other',
                                      suffixIcon:
                                          _otherController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(Icons.clear),
                                                  onPressed: () {
                                                    setState(() {
                                                      _otherController.clear();
                                                    });
                                                  },
                                                )
                                              : null,
                                    ),
                                    // Validate only if the chip is selected
                                    validator: (value) {
                                      if (isOtherSelected &&
                                          (value == null ||
                                              value.trim().isEmpty)) {
                                        return 'Please enter a value';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      setState(() {});
                                    }),
                              ),
                              const SizedBox(width: 8),
                              // Always display the chip; disable it if there's no text.
                              ChoiceChip(
                                label: Text(
                                  _otherController.text.trim().isEmpty
                                      ? "Other"
                                      : _otherController.text.trim(),
                                ),
                                // Use the selections set to determine if the chip is selected.
                                selected: isOtherSelected,
                                onSelected: (selected) {
                                  if (_otherController.text.trim().isNotEmpty) {
                                    setState(() {
                                      isOtherSelected = selected;
                                      if (selected) {
                                        selections
                                            .add(_otherController.text.trim());
                                      } else {
                                        selections.remove(
                                            _otherController.text.trim());
                                      }
                                    });
                                  }
                                },
                                backgroundColor: Color(0xFFE3EBF4),
                                disabledColor: Color(0xFFE3EBF4),
                                selectedColor: p2bpBlue.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isOtherSelected
                                        ? p2bpBlue
                                        : Color(0xFFB0C4DE),
                                    width: 2.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Display an error message if no chip is selected.
                          if (errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: p2bpBlue),
                            onPressed: () {
                              // Check that at least one chip is selected.
                              if (selections.isEmpty) {
                                setState(() {
                                  errorMessage =
                                      'Please select at least one sound type';
                                });
                                return;
                              }
                              // Validate the "Other" field if its chip is selected.
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }
                              Navigator.pop(context, selections.toList());
                            },
                            child: const Text('Submit',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ) ??
        [];

    // 3. Bottom sheet for Main Sound Type (single-select).
    String? mainSoundType;
    mainSoundType = await showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFDDE6F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        final List<String> soundOptions = selectedSoundTypes;
        String? selectedOption;
        String? errorMessage;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Main Sound Type',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select the main source of sound that you heard during the measurement',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3, // Three columns
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // Prevent scrolling inside the sheet
                      mainAxisSpacing: 1,
                      crossAxisSpacing: 2,
                      padding: const EdgeInsets.only(bottom: 8),
                      childAspectRatio:
                          2, // Adjust to change the height/width ratio of each cell
                      children: soundOptions.map((option) {
                        final bool isSelected = selectedOption == option;
                        return ChoiceChip(
                          label: Text(option),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedOption = selected ? option : null;
                              // Clear error when a chip is selected.
                              if (selectedOption != null) errorMessage = null;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20), // Pill shape
                            side: BorderSide(
                              color: isSelected
                                  ? p2bpBlue
                                  : Color(
                                      0xFFB0C4DE), // Distinct border when selected
                              width: 2.0,
                            ),
                          ),
                          selectedColor: p2bpBlue
                              .shade100, // Background color when selected
                          backgroundColor: Color(0xFFE3EBF4),
                        );
                      }).toList(),
                    ),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: p2bpBlue),
                      onPressed: () {
                        if (selectedOption == null) {
                          setState(() {
                            errorMessage = 'Please select a main sound type.';
                          });
                          return;
                        }
                        Navigator.pop(context, selectedOption);
                      },
                      child: const Text('Submit',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    setState(() {
      _isBottomSheetOpen = false;
    });

    // Construct an AcousticMeasurement using the collected data.
    final measurement = AcousticMeasurement(
      decibels: decibel,
      soundTypes: selectedSoundTypes,
      mainSoundType: mainSoundType ?? '',
      other: '',
    );
    // Use the selected standing point index, defaulting to 0 if none is selected.
    int index = _selectedStandingPointIndex ?? 0;

    // Initialize the measureme list for this standing point if it doesn't exist.
    if (!_measurementsPerPoint.containsKey(index)) {
      _measurementsPerPoint[index] = [];
    }
    _measurementsPerPoint[index]!.add(measurement);
  }

  /// Finalize the interval cycle by stopping the test-running state.
  /// Process and aggregate the measurement data for each standing point:
  /// - Calculate average decibel values.
  /// - Draw a circle around the point representing the data as a 'heat map'
  /// Update the completed status of each standing point
  /// If all points are completed, navigate to the Project Details Page
  Future<void> _endTest() async {
    setState(() {
      _isTestRunning = false;
    });
    try {
      // TODO: Bsckend logic when interval cycle completes
      // await _firestore
      //     .collection(widget.activeTest.collectionID)
      //     .doc(widget.activeTest.testID)
      //     .update({
      //   'data': acousticMeasurementsToJson(measurements),
      //   'isComplete': true,
      // });
      print("Acoustic Profile test data submitted successfully.");
    } catch (e, stacktrace) {
      print("Error submitting Acoustic Profile test data: $e");
      print("Stacktrace: $stacktrace");
    }
    _measurementsPerPoint.forEach((index, measurements) {
      if (measurements.isNotEmpty) {
        final avgDecibel =
            measurements.map((m) => m.decibels).reduce((a, b) => a + b) /
                measurements.length;
        final scaleFactor = 10;
        final circleRadius = avgDecibel * scaleFactor;

        // Calculate the most frequently chosen main sound type.
        Map<String, int> mainSoundTypeCount = {};
        for (final measurement in measurements) {
          final type = measurement.mainSoundType;
          mainSoundTypeCount[type] = (mainSoundTypeCount[type] ?? 0) + 1;
        }
        String mainSoundTypeMode = '';
        int maxCount = 0;
        mainSoundTypeCount.forEach((type, cnt) {
          if (cnt > maxCount) {
            maxCount = cnt;
            mainSoundTypeMode = type;
          }
        });

        // Determine the center for the circle.
        // Use the selected marker index. If none is selected, default to 0.
        int index = _selectedStandingPointIndex ?? 0;
        LatLng circleCenter = _currentLocation;
        if (_standingPoints.isNotEmpty && index < _standingPoints.length) {
          final currentStandingPoint = _standingPoints[index];
          if (currentStandingPoint is Map &&
              currentStandingPoint.containsKey('point') &&
              currentStandingPoint['point'] is GeoPoint) {
            circleCenter =
                (currentStandingPoint['point'] as GeoPoint).toLatLng();
          }
        }

        setState(() {
          _circles.add(
            Circle(
              circleId: CircleId('acousticHeatmap_$index'),
              center: circleCenter,
              radius: circleRadius,
              fillColor: Colors.purple.shade100.withValues(alpha: 0.3),
              strokeWidth: 0,
            ),
          );
          // Mark this standing point as completed.
          if (index < _completedStandingPoints.length) {
            _completedStandingPoints[index] = true;
          }

          // Clear the current selection.
          _selectedStandingPointIndex = null;
          // Refresh markers so that the icon updates.
          _markers = _setMarkersFromPoints(_standingPoints);
        });
      } else {
        print("No measurements available to calculate average decibel.");
      }
    });

    // If all standing points have a corresponding circle, navigate out to Project Details Page.
    if (_completedStandingPoints.every((completed) => completed)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProjectDetailsPage(projectData: widget.activeProject),
        ),
      );
    }
  }

  /// Displays an instruction overlay that explains how Acoustic Profile works.
  /// This overlay is shown immediately when the screen loads.
  void _showInstructionOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
              horizontal: screenSize.width * 0.05,
              vertical: screenSize.height * 0.005),
          actionsPadding: EdgeInsets.zero,
          title: const Text(
            'How It Works:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: screenSize.width * 0.95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  acousticInstructions(),
                  buildLegends(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: const [
                    Checkbox(value: false, onChanged: null),
                    Text("Don't show this again next time"),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Overlay widget to display a centered message instructing the user not to leave the application
  /// once the test has started.
  Widget _buildInstructionMessage() {
    // Only display if no bottom sheet is open.
    if (_isBottomSheetOpen) return SizedBox.shrink();
    // Choose message based on whether the test has started.
    String message = !_isTestRunning
        ? "Do not leave the application once the activity has started"
        : "Listen carefully to your surroundings";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// Build the main UI for Acoustic Profile.
  /// This includes the Google Map with project boundaries, the Start button (which is enabled
  /// upon marker selection), a timer display, and overlays for instructions and messages.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle:
            const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        // Start/End button (for this test, we rely solely on the interval timer)
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: _isTestRunning ? Colors.grey : Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: (!_isTestRunning && _selectedStandingPointIndex != null)
                ? () {
                    setState(() {
                      _isTestRunning = true;
                      _startAcousticTest(); // Start the countdown timer when pressed
                    });
                  }
                : null,
            child: const Text(
              'Start',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        // Centered message reminding the user not to leave the app.
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: // Interval counter (e.g. "Interval 3/15")
                  Text(
                '${_currentInterval + 1} / $_maxIntervals',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        centerTitle: true,
        // Timer display on the right (shows remaining seconds for current interval)
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen map displaying the project polygon.
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition:
                CameraPosition(target: _currentLocation, zoom: 14.0),
            polygons: _polygons,
            circles: _circles,
            mapType: _currentMapType,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          // Optionally, display an error message if the user taps outside the polygon.
          if (_showErrorMessage)
            Positioned(
              bottom: 100.0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
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
                border: Border.all(color: const Color(0xFF2D6040), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Center(
                  child: Icon(Icons.layers, color: const Color(0xFF2D6040)),
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
                  color: const Color(0xFFBACFEB).withValues(alpha: 0.9),
                  border: Border.all(color: const Color(0xFF37597D), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(FontAwesomeIcons.info,
                      color: const Color(0xFF37597D)),
                  onPressed: _showInstructionOverlay,
                ),
              ),
            ),
          if (!_isBottomSheetOpen) _buildInstructionMessage(),
        ],
      ),
    );
  }
}
