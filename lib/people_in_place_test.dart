import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/db_schema_classes.dart';
import 'package:p2bp_2025spring_mobile/firestore_functions.dart';
import 'package:p2bp_2025spring_mobile/people_in_place_instructions.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';

import 'google_maps_functions.dart';

final AssetMapBitmap _standingPointMarker = AssetMapBitmap(
  'assets/standing_point_disabled.png',
  width: 48,
  height: 48,
);
final AssetMapBitmap _standingMaleMarker = AssetMapBitmap(
  'assets/custom_icons/test_specific/people_in_place/standing_male_marker.png',
  width: 36,
  height: 36,
);
final AssetMapBitmap _sittingMaleMarker = AssetMapBitmap(
  'assets/custom_icons/test_specific/people_in_place/sitting_male_marker.png',
  width: 36,
  height: 36,
);
final AssetMapBitmap _layingMaleMarker = AssetMapBitmap(
  'assets/custom_icons/test_specific/people_in_place/laying_male_marker.png',
  width: 36,
  height: 36,
);
final AssetMapBitmap _squattingMaleMarker = AssetMapBitmap(
  'assets/custom_icons/test_specific/people_in_place/squatting_male_marker.png',
  width: 36,
  height: 36,
);
final AssetMapBitmap _standingFemaleMarker = AssetMapBitmap(
  'assets/custom_icons/test_specific/people_in_place/standing_female_marker.png',
  width: 36,
  height: 36,
);
final AssetMapBitmap _sittingFemaleMarker = AssetMapBitmap(
  'assets/custom_icons/test_specific/people_in_place/sitting_female_marker.png',
  width: 36,
  height: 36,
);
final AssetMapBitmap _layingFemaleMarker = AssetMapBitmap(
  'assets/custom_icons/test_specific/people_in_place/laying_female_marker.png',
  width: 36,
  height: 36,
);
final AssetMapBitmap _squattingFemaleMarker = AssetMapBitmap(
  'assets/custom_icons/test_specific/people_in_place/squatting_female_marker.png',
  width: 36,
  height: 36,
);
final AssetMapBitmap _standingNAMarker = AssetMapBitmap(
  'assets/custom_icons/test_specific/people_in_place/standing_na_marker.png',
  width: 36,
  height: 36,
);
final AssetMapBitmap _sittingNAMarker = AssetMapBitmap(
  'assets/custom_icons/test_specific/people_in_place/sitting_na_marker.png',
  width: 36,
  height: 36,
);
final AssetMapBitmap _layingNAMarker = AssetMapBitmap(
  'assets/custom_icons/test_specific/people_in_place/laying_na_marker.png',
  width: 36,
  height: 36,
);
final AssetMapBitmap _squattingNAMarker = AssetMapBitmap(
  'assets/custom_icons/test_specific/people_in_place/squatting_na_marker.png',
  width: 36,
  height: 36,
);

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

class _PeopleInPlaceTestPageState extends State<PeopleInPlaceTestPage> {
  bool _isTestRunning = false;
  bool _outsidePoint = false;
  bool _isPointsMenuVisible = false;
  bool _directionsVisible = false;

  double _zoom = 18;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  MapType _currentMapType = MapType.satellite;

  final Set<Polygon> _polygons = {};
  final Set<Marker> _markers = {};
  final List<LatLng> _loggedPoints = [];
  final Set<Marker> _standingPointMarkers = {};

  final PeopleInPlaceData _newData = PeopleInPlaceData();

  int _remainingSeconds = -1;
  Timer? _timer;

  MarkerId? _openMarkerId;

  @override
  void initState() {
    super.initState();
    _polygons.add(getProjectPolygon(widget.activeProject.polygonPoints));
    _location = getPolygonCentroid(_polygons.first);
    _zoom = getIdealZoom(
      _polygons.first.toMPLatLngList(),
      _location.toMPLatLng(),
    );
    _remainingSeconds = widget.activeTest.testDuration;
    for (final point in widget.activeTest.standingPoints) {
      _standingPointMarkers.add(Marker(
        markerId: MarkerId(point.toString()),
        position: point.location,
        icon: _standingPointMarker,
      ));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("PostFrameCallback fired");
      _showInstructionOverlay();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showInstructionOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          actionsPadding: EdgeInsets.zero,
          title: Text(
            'How It Works:',
            style: TextStyle(
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: MediaQuery.sizeOf(context).width,
            child: SingleChildScrollView(
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
                    Navigator.pop(context);
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

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToCurrentLocation();
  }

  /// Moves camera to project location.
  void _moveToCurrentLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: _zoom),
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

  Future<void> _handleMapTap(LatLng point) async {
    // If point is outside the project boundary, display error message
    if (!isPointInsidePolygon(point, _polygons.first)) {
      setState(() {
        _outsidePoint = true;
      });
    }

    // Show bottom sheet for classification
    final PersonInPlace? person = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFFDDE6F2),
      builder: (context) => _DescriptionForm(location: point),
    );
    if (person == null) {
      if (_outsidePoint) {
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _outsidePoint = false;
        });
      }
      return;
    }

    final MarkerId markerId = MarkerId(point.toString());
    final key = '${person.posture.name}_${person.gender.name}';
    AssetMapBitmap markerIcon = _getMarkerIcon(key);

    // Add this data point to set of visible markers and other data lists.
    setState(() {
      _markers.add(
        Marker(
          markerId: markerId,
          position: point,
          icon: markerIcon,
          infoWindow: InfoWindow(
              title: 'Age: ${person.ageRange.displayName}', // for example
              snippet: 'Gender: ${person.gender.displayName}\n'
                  'Activities: ${[
                for (final activity in person.activities) activity.displayName
              ]}\n'
                  'Posture: ${person.posture.displayName}'),
          onTap: () {
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

      _loggedPoints.add(person.location);
      _newData.persons.add(person);
    });

    if (_outsidePoint) {
      // TODO: fix delay. delay will overlap with consecutive taps.
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _outsidePoint = false;
      });
    }
  }

  AssetMapBitmap _getMarkerIcon(String key) {
    switch (key) {
      case 'standing_male':
        return _standingMaleMarker;
      case 'sitting_male':
        return _sittingMaleMarker;
      case 'layingDown_male':
        return _layingMaleMarker;
      case 'squatting_male':
        return _squattingMaleMarker;
      case 'standing_female':
        return _standingFemaleMarker;
      case 'sitting_female':
        return _sittingFemaleMarker;
      case 'layingDown_female':
        return _layingFemaleMarker;
      case 'squatting_female':
        return _squattingFemaleMarker;
      case 'standing_nonbinary' || 'standing_unspecified':
        return _standingNAMarker;
      case 'sitting_nonbinary' || 'sitting_unspecified':
        return _sittingNAMarker;
      case 'layingDown_nonbinary' || 'layingDown_unspecified':
        return _layingNAMarker;
      default:
        return _squattingNAMarker;
    }
  }

  void _startTest() {
    setState(() {
      _isTestRunning = true;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _isTestRunning = false;
          timer.cancel();
          showDialog(
            context: context,
            builder: (context) {
              return TimerEndDialog(onSubmit: () {
                Navigator.pop(context);
                _endTest();
              }, onBack: () {
                setState(() {
                  _remainingSeconds = widget.activeTest.testDuration;
                });
                Navigator.pop(context);
              });
            },
          );
        }
      });
    });
  }

  void _endTest() {
    _timer?.cancel();
    widget.activeTest.submitData(_newData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          systemOverlayStyle:
              SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
        ),
        body: Stack(
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _location,
                  zoom: _zoom,
                ),
                markers: {..._standingPointMarkers, ..._markers},
                polygons: _polygons,
                onTap: (_isTestRunning) ? _handleMapTap : null,
                mapType: _currentMapType,
                myLocationButtonEnabled: false,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 15.0, left: 15.0),
                  child: TimerButtonAndDisplay(
                    onPressed: () {
                      setState(() {
                        if (_isTestRunning) {
                          setState(() {
                            _isTestRunning = false;
                            _timer?.cancel();
                          });
                        } else {
                          _startTest();
                        }
                      });
                    },
                    isTestRunning: _isTestRunning,
                    remainingSeconds: _remainingSeconds,
                  ),
                ),
                Expanded(
                  child: _directionsVisible
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 15.0),
                          child: DirectionsText(
                            onTap: () {
                              setState(() {
                                _directionsVisible = !_directionsVisible;
                              });
                            },
                            text: 'Tap to log data point.',
                          ),
                        )
                      : SizedBox(),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15, right: 15),
                  child: Column(
                    spacing: 10,
                    children: <Widget>[
                      DirectionsButton(
                        onTap: () {
                          setState(() {
                            _directionsVisible = !_directionsVisible;
                          });
                        },
                      ),
                      CircularIconMapButton(
                        backgroundColor:
                            const Color(0xFF7EAD80).withValues(alpha: 0.9),
                        borderColor: Color(0xFF2D6040),
                        onPressed: _toggleMapType,
                        icon: Center(
                          child: Icon(Icons.layers, color: Color(0xFF2D6040)),
                        ),
                      ),
                      CircularIconMapButton(
                        backgroundColor:
                            Color(0xFFBACFEB).withValues(alpha: 0.9),
                        borderColor: Color(0xFF37597D),
                        onPressed: _showInstructionOverlay,
                        icon: Center(
                          child: Icon(
                            FontAwesomeIcons.info,
                            color: Color(0xFF37597D),
                          ),
                        ),
                      ),
                      CircularIconMapButton(
                        backgroundColor:
                            Color(0xFFBD9FE4).withValues(alpha: 0.9),
                        borderColor: Color(0xFF5A3E85),
                        onPressed: () {
                          setState(() {
                            _isPointsMenuVisible = !_isPointsMenuVisible;
                          });
                        },
                        icon: Icon(
                          FontAwesomeIcons.locationDot,
                          color: Color(0xFF5A3E85),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            if (_outsidePoint)
              TestErrorText(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 150),
              ),
            if (_isPointsMenuVisible)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: DataEditMenu(
                    title: 'Marker Color Guide',
                    colorLegendItems: [
                      for (final type in PostureType.values)
                        ColorLegendItem(
                          label: type.displayName,
                          color: type.color,
                        ),
                    ],
                    placedDataList: _buildPlacedPointList(),
                    onPressedCloseMenu: () => setState(
                        () => _isPointsMenuVisible = !_isPointsMenuVisible),
                    onPressedClearAll: () {
                      setState(() {
                        // Clear all logged points.
                        _loggedPoints.clear();
                        _newData.persons.clear();
                        // Remove all associated markers.
                        _markers.clear();
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  ListView _buildPlacedPointList() {
    Map<PostureType, int> typeCounter = {};
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _newData.persons.length,
      itemBuilder: (context, index) {
        final person = _newData.persons[index];
        // Increment this type's count
        typeCounter.update(person.posture, (i) => i + 1, ifAbsent: () => 1);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Text(
            '${person.posture.displayName} Person ${typeCounter[person.posture]}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${person.location.latitude.toStringAsFixed(4)}, '
            '${person.location.longitude.toStringAsFixed(4)}',
            textAlign: TextAlign.left,
          ),
          trailing: IconButton(
            icon:
                const Icon(FontAwesomeIcons.trashCan, color: Color(0xFFD32F2F)),
            onPressed: () {
              setState(() {
                // Construct the markerId the same way it was created.
                final markerId = MarkerId(person.location.toString());
                // Remove the marker from the markers set.
                _markers.removeWhere((marker) => marker.markerId == markerId);
                // Remove the point from data.
                _newData.persons.removeAt(index);
                // Remove the point from the list.
                _loggedPoints.removeWhere((point) => point == person.location);
              });
            },
          ),
        );
      },
    );
  }
}

class _DescriptionForm extends StatefulWidget {
  final LatLng location;

  const _DescriptionForm({required this.location});

  @override
  State<_DescriptionForm> createState() => _DescriptionFormState();
}

class _DescriptionFormState extends State<_DescriptionForm> {
  static const TextStyle boldTextStyle = TextStyle(fontWeight: FontWeight.bold);

  int? _selectedAgeRange;
  int? _selectedGender;
  final List<bool> _selectedActivities = List.of(
      [for (final _ in ActivityTypeInPlace.values) false],
      growable: false);
  int? _selectedPosture;

  void _submitDescription() {
    final PersonInPlace person;

    // Converts activity bool list to type set
    List<ActivityTypeInPlace> types = ActivityTypeInPlace.values;
    Set<ActivityTypeInPlace> activities = {};
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
                      AgeRangeType.values.length,
                      (index) {
                        return ChoiceChip(
                          label: Text(AgeRangeType.values[index].displayName),
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
                      GenderType.values.length,
                      (index) {
                        return ChoiceChip(
                          label: Text(GenderType.values[index].displayName),
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
                    'Activities',
                    style: boldTextStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: List<Widget>.generate(
                      ActivityTypeInPlace.values.length,
                      (index) {
                        return FilterChip(
                          label: Text(
                              ActivityTypeInPlace.values[index].displayName),
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
                      PostureType.values.length,
                      (index) {
                        return ChoiceChip(
                          label: Text(PostureType.values[index].displayName),
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
