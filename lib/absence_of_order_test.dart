import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:p2bp_2025spring_mobile/firestore_functions.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';
import 'google_maps_functions.dart';
import 'db_schema_classes.dart';

/// Returns a `List<TextButton>` using [options] as `Text` child.
/// [selectedList] should be a reference to a list containing the values
/// from [options] that should be selected by default (typically none).
/// [onPressed] is used for `onPressed` of all buttons.
List<Widget> buildToggleButtonList({
  required List<String> options,
  required List<String> selectedList,
  required void Function(String) onPressed,
}) {
  List<Widget> buttonList = options.map((option) {
    final bool isSelected = selectedList.contains(option);
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () => onPressed(option),
      child: Text(option),
    );
  }).toList();
  return buttonList;
}

/// Page for completing and submitting data for an Absence of Order Test.
class AbsenceOfOrderTestPage extends StatefulWidget {
  final Project activeProject;
  final AbsenceOfOrderTest activeTest;

  const AbsenceOfOrderTestPage({
    super.key,
    required this.activeProject,
    required this.activeTest,
  });

  @override
  State<StatefulWidget> createState() => _AbsenceOfOrderTestPageState();
}

class _AbsenceOfOrderTestPageState extends State<AbsenceOfOrderTestPage> {
  bool _isLoading = true;
  bool _outsidePoint = false;
  bool _isTestRunning = false;
  bool _directionsVisible = false;

  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  double _zoom = 18;
  MapType _currentMapType = MapType.satellite; // Default map type
  List<mp.LatLng> _projectArea = [];
  final Set<Marker> _markers = {}; // Set of markers visible on map
  final Set<Polygon> _polygons = {}; // Set of polygons
  final AbsenceOfOrderData _newData = AbsenceOfOrderData();
  DataPoint? _tempDataPoint;

  int _remainingSeconds = -1;
  static const double _bottomSheetHeight = 165;

  @override
  void initState() {
    super.initState();
    _polygons.add(getProjectPolygon(widget.activeProject.polygonPoints));
    _location = getPolygonCentroid(_polygons.first);
    _projectArea = _polygons.first.toMPLatLngList();
    _zoom = getIdealZoom(_projectArea, _location.toMPLatLng());
    _isLoading = false;
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToLocation();
  }

  /// Moves camera to project location.
  void _moveToLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: _zoom),
      ),
    );
  }

  /// Toggles map type between satellite and normal
  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
  }

  /// Places point on the map and adds that location and the description from
  /// [_tempDataPoint] to the appropriate `List` in [_newData].
  void _togglePoint(LatLng point) async {
    try {
      if (!mp.PolygonUtil.containsLocation(
          mp.LatLng(point.latitude, point.longitude), _projectArea, true)) {
        setState(() {
          _outsidePoint = true;
          print('outside!');
        });
      }
      // Add point to data and then add to AbsenceOfOrderData list
      _tempDataPoint!.location = LatLng(point.latitude, point.longitude);
      _newData.addDataPoint(_tempDataPoint!);

      final markerId = MarkerId(point.toString());
      setState(() {
        // Create marker
        _markers.add(
          Marker(
            markerId: markerId,
            position: point,
            consumeTapEvents: true,
            onTap: () {
              // If the marker is tapped again, it will be removed
              _newData.removeDataPoint(point);
              setState(() {
                _markers.removeWhere((marker) => marker.markerId == markerId);
              });
            },
          ),
        );

        _tempDataPoint = null;
      });
      if (_outsidePoint) {
        // TODO: fix delay. delay will overlap with consecutive taps. this means taps do not necessarily refresh the timer and will end prematurely
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _outsidePoint = false;
        });
      }
    } catch (e, stacktrace) {
      print('Error in absence_of_order_test.dart, _togglePoint(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  /// Uses [showModalBottomSheet] on [_BehaviorDescriptionForm] and then
  /// stores the results in [_tempDataPoint].
  void _doBehaviorModal(BuildContext context) async {
    final BehaviorPoint? behaviorPoint = await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => _BehaviorDescriptionForm(),
    );
    setState(() {
      _tempDataPoint = behaviorPoint;
    });
  }

  /// Uses [showModalBottomSheet] on [_MaintenanceDescriptionForm] and then
  /// stores the results in [_tempDataPoint].
  void _doMaintenanceModal(BuildContext context) async {
    final MaintenancePoint? maintenancePoint = await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => _MaintenanceDescriptionForm(),
    );
    setState(() {
      _tempDataPoint = maintenancePoint;
    });
  }

  void _endTest() {
    widget.activeTest.submitData(_newData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Updates flag for whether _tempDataPoint has a description for data point
    bool isDescriptionReady = (_tempDataPoint != null);
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: <Widget>[
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height,
                    child: GoogleMap(
                      padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                      onMapCreated: _onMapCreated,
                      initialCameraPosition:
                          CameraPosition(target: _location, zoom: _zoom),
                      markers: _markers,
                      polygons: _polygons,
                      onTap: isDescriptionReady ? _togglePoint : null,
                      mapType: _currentMapType,
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
                              _isTestRunning = !_isTestRunning;
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
                                        _directionsVisible =
                                            !_directionsVisible;
                                      });
                                    },
                                    text: !isDescriptionReady
                                        ? 'Select a type of misconduct.'
                                        : 'Drop a pin where the misconduct is.'),
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
                              backgroundColor: Colors.green,
                              borderColor: Color(0xFF2D6040),
                              onPressed: _toggleMapType,
                              icon: const Icon(Icons.map),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_outsidePoint)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: _bottomSheetHeight),
                      child: TestErrorText(),
                    ),
                ],
              ),
        bottomSheet: _isLoading
            ? SizedBox()
            : SizedBox(
                height: _bottomSheetHeight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    gradient: defaultGrad,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24.0),
                      topRight: Radius.circular(24.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(0.0, 1.0), //(x,y)
                        blurRadius: 6.0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      Center(
                        child: Text(
                          'Absence of Order Locator',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: placeYellow,
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        spacing: 10,
                        children: <Widget>[
                          Expanded(
                            child: FilledButton(
                              style: testButtonStyle,
                              onPressed: isDescriptionReady
                                  ? null
                                  : () {
                                      _doBehaviorModal(context);
                                    },
                              child: Text('Behavior'),
                            ),
                          ),
                          Expanded(
                            child: FilledButton(
                              style: testButtonStyle,
                              onPressed: isDescriptionReady
                                  ? null
                                  : () {
                                      _doMaintenanceModal(context);
                                    },
                              child: Text('Maintenance'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        spacing: 10,
                        children: <Widget>[
                          Flexible(
                            child: FilledButton.icon(
                              style: testButtonStyle,
                              onPressed: () => Navigator.pop(context),
                              label: Text('Back'),
                              icon: Icon(Icons.chevron_left),
                              iconAlignment: IconAlignment.start,
                            ),
                          ),
                          Flexible(
                            child: FilledButton.icon(
                              style: testButtonStyle,
                              onPressed: (isDescriptionReady)
                                  ? null
                                  : () {
                                      showDialog(
                                          context: context,
                                          builder: (context) =>
                                              TestFinishDialog(onNext: () {
                                                Navigator.pop(context);
                                                _endTest();
                                              }));
                                    },
                              label: Text('Finish'),
                              icon: Icon(Icons.chevron_right),
                              iconAlignment: IconAlignment.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Form for providing description of behavior misconduct.
///
/// This is only used with [showModalBottomSheet] when completing an
/// Absence of Order Test.
class _BehaviorDescriptionForm extends StatefulWidget {
  const _BehaviorDescriptionForm();

  @override
  State<_BehaviorDescriptionForm> createState() =>
      _BehaviorDescriptionFormState();
}

class _BehaviorDescriptionFormState extends State<_BehaviorDescriptionForm> {
  final GlobalKey<FormFieldState> _formFieldKey = GlobalKey<FormFieldState>();
  late List<Widget> _buttonList;
  static const List<String> _buttonOptions = [
    'Panhandling',
    'Boisterous Voice',
    'Dangerous Wildlife',
    'Reckless Behavior',
    'Unsafe Equipment',
    'Living in Public',
  ];
  final List<String> _selectedTypes = [];
  bool _otherSelected = false;
  final TextEditingController _otherTextController = TextEditingController();

  /// Validates the form and if successful pops this Modal Sheet and
  /// returns a [BehaviorPoint] containing data from this form.
  void _submitDescription() {
    // Validate 'other' text box and return if invalid
    if (!_formFieldKey.currentState!.validate()) {
      return;
    }

    // Creates a BehaviorPoint with all form values
    // Because _buttonOptions is iterated through in order, the order for
    // all bool arguments must remain the same relative to that.
    final BehaviorPoint point;
    point = BehaviorPoint.noLocation(
      panhandling: _selectedTypes.contains(_buttonOptions[0]),
      boisterousVoice: _selectedTypes.contains(_buttonOptions[1]),
      dangerousWildlife: _selectedTypes.contains(_buttonOptions[2]),
      recklessBehavior: _selectedTypes.contains(_buttonOptions[3]),
      unsafeEquipment: _selectedTypes.contains(_buttonOptions[4]),
      livingInPublic: _selectedTypes.contains(_buttonOptions[5]),
      other: _otherTextController.text,
    );
    Navigator.pop(context, point);
  }

  @override
  Widget build(BuildContext context) {
    _buttonList = buildToggleButtonList(
      options: _buttonOptions,
      selectedList: _selectedTypes,
      onPressed: (option) {
        setState(() {
          if (_selectedTypes.contains(option)) {
            _selectedTypes.remove(option);
          } else {
            _selectedTypes.add(option);
          }
        });
      },
    );
    if (_buttonList.length != 6) {
      print('buttonList in BehaviorDescriptionForm is wrong length');
      return SingleChildScrollView();
    }
    return SingleChildScrollView(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          decoration: BoxDecoration(
            gradient: defaultGrad,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: <Widget>[
                const BarIndicator(),
                Center(
                  child: Text(
                    'Description of Misconduct',
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: placeYellow,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Center(
                    child: Text(
                      'Select all of the following that describes the misconduct.',
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  spacing: 20,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: _buttonList[0],
                    ),
                    Expanded(
                      flex: 1,
                      child: _buttonList[1],
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  spacing: 20,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: _buttonList[2],
                    ),
                    Expanded(
                      flex: 1,
                      child: _buttonList[3],
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  spacing: 20,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: _buttonList[4],
                    ),
                    Expanded(
                      flex: 1,
                      child: _buttonList[5],
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  spacing: 20,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        key: _formFieldKey,
                        enabled: _otherSelected,
                        controller: _otherTextController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          hintText: 'Other...',
                        ),
                        validator: (value) {
                          // If other button was selected verify text box is not empty
                          if (_otherSelected &&
                              (value == null || value.isEmpty)) {
                            return 'Please describe the misconduct.';
                          }
                          return null;
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              _otherSelected ? Colors.blue : Colors.white,
                          foregroundColor:
                              _otherSelected ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _otherSelected = !_otherSelected;
                          });
                        },
                        child: Text('Select Other'),
                      ),
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: FilledButton(
                        style: testButtonStyle,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancel'),
                      ),
                    ),
                    Flexible(
                      child: FilledButton(
                        style: testButtonStyle,
                        // Confirm button disabled when no option selected
                        onPressed: (_selectedTypes.isNotEmpty || _otherSelected)
                            ? _submitDescription
                            : null,
                        child: Text('Confirm'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Form for providing description of maintenance misconduct.
///
/// This is only used with [showModalBottomSheet] when completing an
/// Absence of Order Test.
class _MaintenanceDescriptionForm extends StatefulWidget {
  const _MaintenanceDescriptionForm();

  @override
  State<_MaintenanceDescriptionForm> createState() =>
      _MaintenanceDescriptionFormState();
}

class _MaintenanceDescriptionFormState
    extends State<_MaintenanceDescriptionForm> {
  final GlobalKey<FormFieldState> _formFieldKey = GlobalKey<FormFieldState>();
  late List<Widget> _buttonList;
  static const List<String> _buttonOptions = [
    'Broken Environment',
    'Dirty/Unmaintained',
    'Unwanted Graffiti',
    'Littering',
    'Overfilled Trashcan',
    'Unkept Landscape',
  ];
  final List<String> _selectedTypes = [];
  bool _isOtherSelected = false;
  final TextEditingController _otherTextController = TextEditingController();

  /// Validates the form and if successful pops this Modal Sheet and
  /// returns a [MaintenancePoint] containing data from this form.
  void _submitDescription() {
    // Validate 'other' text box and return if invalid
    if (!_formFieldKey.currentState!.validate()) {
      return;
    }

    // Creates a MaintenancePoint with all form values
    // Because _buttonOptions is iterated through in order, the order for
    // all bool arguments must remain the same relative to that.
    final MaintenancePoint point;
    point = MaintenancePoint.noLocation(
      brokenEnvironment: _selectedTypes.contains(_buttonOptions[0]),
      dirtyOrUnmaintained: _selectedTypes.contains(_buttonOptions[1]),
      unwantedGraffiti: _selectedTypes.contains(_buttonOptions[2]),
      littering: _selectedTypes.contains(_buttonOptions[3]),
      overfilledTrash: _selectedTypes.contains(_buttonOptions[4]),
      unkeptLandscape: _selectedTypes.contains(_buttonOptions[5]),
      other: _otherTextController.text,
    );
    Navigator.pop(context, point);
  }

  @override
  Widget build(BuildContext context) {
    _buttonList = buildToggleButtonList(
      options: _buttonOptions,
      selectedList: _selectedTypes,
      onPressed: (option) {
        setState(() {
          if (_selectedTypes.contains(option)) {
            _selectedTypes.remove(option);
          } else {
            _selectedTypes.add(option);
          }
        });
      },
    );
    if (_buttonList.length != 6) {
      print('buttonList in MaintenanceDescriptionForm is wrong length');
      return SingleChildScrollView();
    }
    return SingleChildScrollView(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          decoration: BoxDecoration(
            gradient: defaultGrad,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: <Widget>[
                const BarIndicator(),
                Center(
                  child: Text(
                    'Description of Misconduct',
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: placeYellow,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Center(
                    child: Text(
                      'Select all of the following that describes the misconduct.',
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  spacing: 20,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: _buttonList[0],
                    ),
                    Expanded(
                      flex: 1,
                      child: _buttonList[1],
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  spacing: 20,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: _buttonList[2],
                    ),
                    Expanded(
                      flex: 1,
                      child: _buttonList[3],
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  spacing: 20,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: _buttonList[4],
                    ),
                    Expanded(
                      flex: 1,
                      child: _buttonList[5],
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  spacing: 20,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        key: _formFieldKey,
                        enabled: _isOtherSelected,
                        controller: _otherTextController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          hintText: 'Other...',
                        ),
                        validator: (value) {
                          // If other button was selected verify text box is not empty
                          if (_isOtherSelected &&
                              (value == null || value.isEmpty)) {
                            return 'Please describe the misconduct.';
                          }
                          return null;
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              _isOtherSelected ? Colors.blue : Colors.white,
                          foregroundColor:
                              _isOtherSelected ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _isOtherSelected = !_isOtherSelected;
                          });
                        },
                        child: Text('Select Other'),
                      ),
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: FilledButton(
                        style: testButtonStyle,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancel'),
                      ),
                    ),
                    Flexible(
                      child: FilledButton(
                        style: testButtonStyle,
                        // Confirm button disabled when no option selected
                        onPressed:
                            (_selectedTypes.isNotEmpty || _isOtherSelected)
                                ? _submitDescription
                                : null,
                        child: Text('Confirm'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
