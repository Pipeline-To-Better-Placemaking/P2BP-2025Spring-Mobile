import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:p2bp_2025spring_mobile/db_schema_classes.dart';
import 'package:p2bp_2025spring_mobile/standing_points_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'google_maps_functions.dart';
import 'firestore_functions.dart';
import 'theme.dart';
import 'section_creation_page.dart';

class CreateTestForm extends StatefulWidget {
  final Project activeProject;
  const CreateTestForm({super.key, required this.activeProject});

  @override
  State<CreateTestForm> createState() => _CreateTestFormState();
}

class _CreateTestFormState extends State<CreateTestForm> {
  final _formKey = GlobalKey<FormState>();
  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _activityNameController = TextEditingController();
  final LatLng _currentLocation = defaultLocation;
  bool _isLoading = true;
  Set<Polygon> _polygons = {};

  DateTime? _selectedDateTime;
  String? _selectedTest;

  List _standingPoints = [];

  bool _standingPointsTest = false;
  bool _standingPointsError = false;
  bool _timerTest = false;

  Future<DateTime?> showDateTimePicker({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    initialDate ??= DateTime.now();
    firstDate ??= initialDate.subtract(const Duration(days: 365 * 100));
    lastDate ??= firstDate.add(const Duration(days: 365 * 200));

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selectedDate == null) return null;

    if (!context.mounted) return selectedDate;

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    return selectedTime == null
        ? selectedDate
        : DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
  }

  @override
  void initState() {
    super.initState();
    initProjectArea();
  }

  @override
  void dispose() {
    _dateTimeController.dispose();
    _activityNameController.dispose();
    super.dispose();
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

  /// Gets the project polygon, adds it to the current polygon list, and
  /// centers the map over it.
  void initProjectArea() {
    setState(() {
      _polygons = getProjectPolygon(widget.activeProject.polygonPoints);
      _location = getPolygonCentroid(_polygons.first);
      // Take some latitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      // TODO: dynamic zooming

      _standingPoints = widget.activeProject.standingPoints;
      _isLoading = false;
    });
  }

  void _moveToLocation() {
    if (mapController == null) return;
    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: 14.0),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToLocation(); // Ensure the map is centered on the current location
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Center(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: <Widget>[
            // Pill notch
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(47, 109, 207, 0.2), // light grey?
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
            ),
            // Vertical padding from the pill notch
            SizedBox(height: 16),
            TextFormField(
              controller: _activityNameController,
              decoration: InputDecoration(
                labelText: "Activity Name",
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: TextStyle(color: p2bpBlue),
                floatingLabelStyle: TextStyle(color: Color(0xFF1A3C70)),
                enabledBorder:
                    OutlineInputBorder(borderSide: BorderSide(color: p2bpBlue)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1A3C70))),
                border: OutlineInputBorder(),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name for this activity.';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            // Activity Time via a dial spinner (using CupertinoTimerPicker)
            // Activity Time field (replacing the dial spinner)
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Scheduled Time',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: TextStyle(color: p2bpBlue),
                floatingLabelStyle: TextStyle(color: Color(0xFF1A3C70)),
                enabledBorder:
                    OutlineInputBorder(borderSide: BorderSide(color: p2bpBlue)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1A3C70))),
                border: OutlineInputBorder(),
              ),
              controller: _dateTimeController,
              onTap: () async {
                DateTime? pickedDateTime =
                    await showDateTimePicker(context: context);
                if (pickedDateTime != null) {
                  setState(() {
                    _selectedDateTime = pickedDateTime;
                    _dateTimeController.text =
                        pickedDateTime.toLocal().toString();
                  });
                }
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please schedule a time for this activity.';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            // Dropdown menu for selecting an activity
            DropdownButtonFormField2<String>(
              decoration: InputDecoration(
                labelText: "Select Activity",
                floatingLabelBehavior: FloatingLabelBehavior.never,
                // filled: true,
                // fillColor: Color.fromRGBO(47, 109, 207, 0.1),
                labelStyle: TextStyle(color: p2bpBlue),
                floatingLabelStyle: TextStyle(color: Color(0xFF1A3C70)),
                enabledBorder:
                    OutlineInputBorder(borderSide: BorderSide(color: p2bpBlue)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1A3C70))),
                border: OutlineInputBorder(),
              ),
              dropdownStyleData: DropdownStyleData(
                width: 370,
                maxHeight: 200, // Sets the popup menu's width to 200 pixels.
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 234, 245, 255),
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: AbsenceOfOrderTest.collectionIDStatic,
                  child: Text(
                    'Absence of Order Locator',
                    style: TextStyle(color: p2bpBlue),
                  ),
                ),
                DropdownMenuItem(
                  value: LightingProfileTest.collectionIDStatic,
                  child: Text(
                    'Lighting Profile',
                    style: TextStyle(color: p2bpBlue),
                  ),
                ),
                DropdownMenuItem(
                  value: SectionCutterTest.collectionIDStatic,
                  child: Text(
                    'Section Cutter',
                    style: TextStyle(color: p2bpBlue),
                  ),
                ),
                DropdownMenuItem(
                  value: IdentifyingAccessTest.collectionIDStatic,
                  child: Text(
                    'Identifying Access',
                    style: TextStyle(color: p2bpBlue),
                  ),
                ),
                DropdownMenuItem(
                  value: PeopleInPlaceTest.collectionIDStatic,
                  child: Text(
                    'People in Place',
                    style: TextStyle(color: p2bpBlue),
                  ),
                ),
                DropdownMenuItem(
                  value: PeopleInMotionTest.collectionIDStatic,
                  child: Text(
                    'People in Motion',
                    style: TextStyle(color: p2bpBlue),
                  ),
                ),
                DropdownMenuItem(
                  value: NaturePrevalenceTest.collectionIDStatic,
                  child: Text(
                    'Nature Prevalence',
                    style: TextStyle(color: p2bpBlue),
                  ),
                ),
                DropdownMenuItem(
                  value: AcousticProfileTest.collectionIDStatic,
                  child: Text(
                    'Acoustic Profile',
                    style: TextStyle(color: p2bpBlue),
                  ),
                ),
              ],
              onChanged: (value) {
                _selectedTest = value;
                setState(() {
                  _standingPointsTest =
                      standingPointsTests.contains(_selectedTest);
                });
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null) {
                  return 'Please select an activity type.';
                }
                return null;
              },
            ),
            SizedBox(height: 32),
            _standingPointsTest
                ? SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Static map container
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: GoogleMap(
                            onMapCreated: _onMapCreated,
                            initialCameraPosition: CameraPosition(
                              target: _currentLocation,
                              zoom: 42.0,
                            ),
                            polygons: _polygons,
                            liteModeEnabled: true,
                            myLocationButtonEnabled: false,

                            // Disable gestures to mimic a static image.
                            zoomGesturesEnabled: false,
                            scrollGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                            tiltGesturesEnabled: false,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          // Dimmed Overlay
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final List tempPoints = await Navigator.push(
                                      context, _customRoute());
                                  setState(() {
                                    _standingPoints = tempPoints;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: p2bpBlue,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 3,
                                ),
                                icon: Icon(Icons.location_on,
                                    color: Colors.white),
                                label: Text(
                                  _standingPoints.isEmpty
                                      ? 'Add Standing Points'
                                      : 'Edit Standing Points',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_standingPoints.isNotEmpty) ...[
                                SizedBox(width: 8),
                                Icon(Icons.check_circle, color: Colors.green),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(),
            (_standingPointsError)
                ? Center(
                    child: Text('Please add standing points first.',
                        style: TextStyle(color: Color(0xFFB3261E))),
                  )
                : SizedBox(),
            SizedBox(height: _standingPointsTest ? 32 : 4),
            // Submit activity information to create it
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  final bool validated = _formKey.currentState!.validate();
                  if (_standingPointsTest) {
                    if (_standingPoints.isEmpty) {
                      setState(() {
                        _standingPointsError = true;
                      });
                      return;
                    }
                  }
                  if (validated) {
                    final Map<String, dynamic> newTestInfo = {
                      'title': _activityNameController.text,
                      'scheduledTime': Timestamp.fromDate(_selectedDateTime!),
                      'collectionID': _selectedTest,
                    };
                    if (_standingPointsTest) {
                      newTestInfo.update(
                          'standingPoints', (value) => _standingPoints,
                          ifAbsent: () => _standingPoints);
                    }
                    // Handle form submission
                    Navigator.of(context).pop(newTestInfo);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      p2bpBlue, // Using the Save Activity button color
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  "Save Activity",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Route _customRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        // Conditional navigation based on _selectedTest
        if (_selectedTest?.compareTo(SectionCutterTest.collectionIDStatic) ==
            0) {
          return SectionCreationPage(
            activeProject: widget.activeProject,
            currentSection: _standingPoints.isNotEmpty ? _standingPoints : null,
          );
        } else {
          return StandingPointsPage(
            activeProject: widget.activeProject,
            currentStandingPoints:
                _standingPoints.isNotEmpty ? _standingPoints : null,
          );
        }
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0); // Start from bottom of screen
        const end = Offset.zero; // End at original position
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}
