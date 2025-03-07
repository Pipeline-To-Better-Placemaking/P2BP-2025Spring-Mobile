import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';
import 'google_maps_functions.dart';
import 'db_schema_classes.dart';

final ButtonStyle _testButtonStyle = FilledButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 15),
  foregroundColor: Colors.black,
  backgroundColor: Colors.white,
  disabledBackgroundColor: Color(0xCD6C6C6C),
  iconColor: Colors.black,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
  ),
  textStyle: TextStyle(fontSize: 14),
);

/// Returns a `List` of `TextButton`s using [options] as `Text` child.
/// [selectedList] should be a reference to a list containing the values
/// from [options] that should be selected by default.
/// [onPressed] is used for `onPressed` of the button.
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

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class _AbsenceOfOrderTestPageState extends State<AbsenceOfOrderTestPage> {
  bool _isLoading = true;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  MapType _currentMapType = MapType.satellite; // Default map type
  final Set<Marker> _markers = {}; // Set of markers visible on map
  Set<Polygon> _polygons = {}; // Set of polygons
  final AbsenceOfOrderData _newData = AbsenceOfOrderData();
  DataPoint? _tempDataPoint;

  static const double _bottomSheetHeight = 260;

  @override
  void initState() {
    super.initState();
    _initProjectArea();
  }

  /// Gets the project polygon, adds it to the current polygon list, and
  /// centers the map over it.
  void _initProjectArea() {
    setState(() {
      _polygons = getProjectPolygon(widget.activeProject.polygonPoints);
      print(_polygons);
      _location = getPolygonCentroid(_polygons.first);
      // Take some latitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      // TODO: dynamic zooming
      _isLoading = false;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToLocation(); // Ensure the map is centered on the current location
  }

  void _moveToLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: 17.0),
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
  void _togglePoint(LatLng point) {
    // Add point to data and then add to AbsenceOfOrderData list
    _tempDataPoint!.location = LatLng(point.latitude, point.longitude);
    print('_tempDataPoint: $_tempDataPoint');
    _newData.addDataPoint(_tempDataPoint!);
    print('_newData: $_newData');

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
  }

  void doBehaviorModal(BuildContext context) async {
    final BehaviorPoint? behaviorPoint = await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => _BehaviorDescriptionForm(),
    );
    setState(() {
      _tempDataPoint = behaviorPoint;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDescriptionReady = (_tempDataPoint != null);
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Stack(
                  children: <Widget>[
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: GoogleMap(
                        padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                        onMapCreated: _onMapCreated,
                        initialCameraPosition:
                            CameraPosition(target: _location, zoom: 15),
                        markers: _markers,
                        polygons: _polygons,
                        onTap: isDescriptionReady ? _togglePoint : null,
                        mapType: _currentMapType,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                          bottom: _bottomSheetHeight + 30,
                        ),
                        child: FloatingActionButton(
                          heroTag: null,
                          onPressed: _toggleMapType,
                          backgroundColor: Colors.green,
                          child: const Icon(Icons.map),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        bottomSheet: _isLoading
            ? SizedBox()
            : Container(
                height: _bottomSheetHeight,
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
                        'Absence of Order',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: placeYellow,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Center(
                      child: Text(
                        !isDescriptionReady
                            ? 'Select a type of misconduct.'
                            : 'Drop a pin where the misconduct is.',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Type of Misconduct',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      spacing: 10,
                      children: <Widget>[
                        Expanded(
                          child: FilledButton(
                            style: _testButtonStyle,
                            onPressed: isDescriptionReady
                                ? null
                                : () {
                                    doBehaviorModal(context);
                                  },
                            child: Text('Behavior'),
                          ),
                        ),
                        Expanded(
                          child: FilledButton(
                            style: _testButtonStyle,
                            onPressed: isDescriptionReady ? null : () {},
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
                            style: _testButtonStyle,
                            onPressed: () => Navigator.pop(context),
                            label: Text('Back'),
                            icon: Icon(Icons.chevron_left),
                            iconAlignment: IconAlignment.start,
                          ),
                        ),
                        Flexible(
                          child: FilledButton.icon(
                            style: _testButtonStyle,
                            onPressed: () {
                              // TODO: check isComplete either before submitting or probably before starting test
                              widget.activeTest.submitData(_newData);
                              Navigator.pop(context);
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
    );
  }
}

class _BehaviorDescriptionForm extends StatefulWidget {
  const _BehaviorDescriptionForm({super.key});

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

  void _submitDescription() {
    // Validate other text box and return if invalid
    if (!_formFieldKey.currentState!.validate()) {
      return;
    }

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
          // Container decoration- rounded corners and gradient
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
                    'Description of Behavior Misconduct',
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
                        style: _testButtonStyle,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancel'),
                      ),
                    ),
                    Flexible(
                      child: FilledButton(
                        style: _testButtonStyle,
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
