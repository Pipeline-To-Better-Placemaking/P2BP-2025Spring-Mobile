import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';
import 'google_maps_functions.dart';
import 'db_schema_classes.dart';

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
  bool _isTypeSelected = false;
  MisconductType? _selectedType;

  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  MapType _currentMapType = MapType.satellite; // Default map type
  final Set<Marker> _markers = {}; // Set of markers visible on map
  Set<Polygon> _polygons = {}; // Set of polygons

  Set<LatLng> _allPoints = {};
  AbsenceOfOrderData _newData = AbsenceOfOrderData();
  BehaviorPoint _tempBehavior = BehaviorPoint.empty();
  MaintenancePoint _tempMaintenance = MaintenancePoint.empty();

  ButtonStyle _testButtonStyle = FilledButton.styleFrom();
  static const double _bottomSheetHeight = 300;

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

  void _togglePoint(LatLng point) {
    _allPoints.add(point);
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
            _allPoints.remove(point);
            setState(() {
              _markers.removeWhere((marker) => marker.markerId == markerId);
            });
          },
        ),
      );

      // Reset selected light type
      _setMisconductType(null);
    });
  }

  void _setMisconductType(MisconductType? type) {
    setState(() {
      _selectedType = type;
      _isTypeSelected = _selectedType != null;
    });
  }

  /// Toggles map type between satellite and normal
  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
  }

  void _setButtonStyle() {
    _testButtonStyle = FilledButton.styleFrom(
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
  }

  void showBehaviorModal(BuildContext context) {
    _tempBehavior = BehaviorPoint.empty();
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
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
                  SizedBox(height: 10),
                  Row(
                    spacing: 20,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _tempBehavior.panhandling
                                ? Colors.blue
                                : Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              _tempBehavior.panhandling =
                                  !(_tempBehavior.panhandling);
                              print(_tempBehavior.panhandling);
                            });
                          },
                          child: Text('Panhandling'),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _tempBehavior.boisterousVoice
                                ? Colors.blue
                                : Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              _tempBehavior.boisterousVoice =
                                  !(_tempBehavior.boisterousVoice);
                              print(_tempBehavior.boisterousVoice);
                            });
                          },
                          child: Text('Boisterous Voice'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    spacing: 20,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _tempBehavior.panhandling
                                ? Colors.blue
                                : Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Dangerous Wildlife'),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _tempBehavior.panhandling
                                ? Colors.blue
                                : Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Reckless Behavior'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    spacing: 20,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _tempBehavior.panhandling
                                ? Colors.blue
                                : Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Unsafe Equipment'),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _tempBehavior.panhandling
                                ? Colors.blue
                                : Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Living in Public'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Other',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }

  void showMaintenanceModal(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    _setButtonStyle();
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
                        onTap: _isTypeSelected ? _togglePoint : null,
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
                        !_isTypeSelected
                            ? 'Select a type of misconduct.'
                            : 'Drop a pin where the misconduct is.',
                        style: TextStyle(
                          fontSize: 22,
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
                        Flexible(
                          child: FilledButton(
                            style: _testButtonStyle,
                            onPressed: () {
                              showBehaviorModal(context);
                            },
                            child: Text('Behavior'),
                          ),
                        ),
                        Flexible(
                          child: FilledButton(
                            style: _testButtonStyle,
                            onPressed: (_isTypeSelected)
                                ? null
                                : () {
                                    _setMisconductType(
                                        MisconductType.maintenance);
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
