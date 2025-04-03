import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/firestore_functions.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';
import 'google_maps_functions.dart';
import 'db_schema_classes.dart';

class StandingPointsPage extends StatefulWidget {
  final Project activeProject;
  final List<StandingPoint>? currentStandingPoints;
  const StandingPointsPage(
      {super.key, required this.activeProject, this.currentStandingPoints});

  @override
  State<StandingPointsPage> createState() => _StandingPointsPageState();
}

final AssetMapBitmap disabledIcon = AssetMapBitmap(
  'assets/standing_point_disabled.png',
  width: 48,
  height: 48,
);
final AssetMapBitmap enabledIcon = AssetMapBitmap(
  'assets/standing_point_enabled.png',
  width: 48,
  height: 48,
);

class _StandingPointsPageState extends State<StandingPointsPage> {
  DocumentReference? teamRef;
  late GoogleMapController mapController;
  double _zoom = 18;
  LatLng _location = defaultLocation;
  bool _isLoading = true;
  final String _directions =
      "Select the standing points you want to use in this test. Then click confirm.";
  final Set<Polygon> _polygons = {};
  Set<Marker> _markers = {};
  List<StandingPoint> _standingPoints = [];
  Marker? _currentMarker;
  static const double _bottomSheetHeight = 300;
  MapType _currentMapType = MapType.satellite;
  final List<bool> _checkboxValues = [];
  Project? project;

  // Variables added with page rework on acoustic profile branch by Michael
  // bool _isStandingPointSelected = false;
  // double _sheetExtent = 0.28;
  // static const double bottomOffset = 120.0;
  // final GlobalKey _textContainerKey = GlobalKey();
  // double containerHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _polygons.add(getProjectPolygon(widget.activeProject.polygonPoints));
    _location = getPolygonCentroid(_polygons.first);
    _zoom = getIdealZoom(
      _polygons.first.toMPLatLngList(),
      _location.toMPLatLng(),
    );

    _standingPoints = widget.activeProject.standingPoints.toList();
    _markers = _setMarkersFromStandingPoints(_standingPoints);
    if (widget.currentStandingPoints != null) {
      final List<StandingPoint> currentStandingPoints =
          widget.currentStandingPoints!;
      _loadCurrentStandingPoints(currentStandingPoints);
    }
    _isLoading = false;
  }

  /// Takes a list of points and creates the default markers from their title
  /// and position.
  Set<Marker> _setMarkersFromStandingPoints(
      List<StandingPoint> standingPoints) {
    Set<Marker> markers = {};
    for (final standingPoint in standingPoints) {
      final markerId = MarkerId(standingPoint.toString());
      _checkboxValues.add(false);
      markers.add(
        Marker(
          markerId: markerId,
          position: standingPoint.location,
          icon: disabledIcon,
          infoWindow: InfoWindow(
            title: standingPoint.title,
            snippet: '${standingPoint.location.latitude.toStringAsFixed(5)},'
                ' ${standingPoint.location.latitude.toStringAsFixed(5)}',
          ),
          onTap: () {
            // Get matching marker from id and point index from marker point
            final Marker thisMarker =
                _markers.singleWhere((marker) => marker.markerId == markerId);
            final int listIndex = _standingPoints.indexWhere((standingPoint) =>
                standingPoint.location == thisMarker.position);

            // Update current marker and toggle this point's checkbox
            _currentMarker = thisMarker;
            _checkboxValues[listIndex] = !_checkboxValues[listIndex];
            _toggleMarker();
          },
        ),
      );
    }
    return markers;
  }

  /// Toggles the [_currentMarker] on or off.
  void _toggleMarker() {
    if (_currentMarker == null) return;
    // Adds either an enabled or disabled marker based on whether _currentMarker
    // is disabled or enabled.
    if (_currentMarker?.icon == enabledIcon) {
      setState(() {
        _markers.add(_currentMarker!.copyWith(iconParam: disabledIcon));
      });
    } else if (_currentMarker?.icon == disabledIcon) {
      setState(() {
        _markers.add(_currentMarker!.copyWith(iconParam: enabledIcon));
      });
    }
    // Remove the old outdated marker after the new marker has been added.
    setState(() {
      _markers.remove(_currentMarker);
    });
    _currentMarker = null;
  }

  void _loadCurrentStandingPoints(List<StandingPoint> currentStandingPoints) {
    for (final standingPoint in currentStandingPoints) {
      final Marker thisMarker = _markers
          .singleWhere((marker) => standingPoint.location == marker.position);
      final int listIndex = _standingPoints
          .indexWhere((point) => point.location == thisMarker.position);
      _currentMarker = thisMarker;
      _checkboxValues[listIndex] = !_checkboxValues[listIndex];
      _toggleMarker();
    }
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

  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (_currentMapType == MapType.normal)
          ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: GoogleMap(
                      padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                      onMapCreated: _onMapCreated,
                      initialCameraPosition:
                          CameraPosition(target: _location, zoom: _zoom),
                      polygons: _polygons,
                      markers: _markers,
                      mapType: _currentMapType, // Use current map type
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 4),
                      child: DirectionsText(
                        text: _directions,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 12.0,
                          bottom: _bottomSheetHeight + 50,
                        ),
                        child: CircularIconMapButton(
                          backgroundColor: Colors.green,
                          borderColor: Color(0xFF2D6040),
                          onPressed: _toggleMapType,
                          icon: const Icon(Icons.map),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        bottomSheet: Container(
          height: _bottomSheetHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                child: SizedBox(
                  height: _bottomSheetHeight,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(
                      left: 15.0,
                      right: 15.0,
                      bottom: 50.0,
                    ),
                    itemCount: _markers.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Column(
                        children: [
                          index == 0 ? Divider() : SizedBox(),
                          CheckboxListTile(
                            title: Text(
                              _standingPoints[index].title,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  overflow: TextOverflow.fade),
                            ),
                            subtitle: Text(
                                '${_standingPoints[index].location.latitude.toStringAsFixed(5)},'
                                ' ${_standingPoints[index].location.longitude.toStringAsFixed(5)}'),
                            value: _checkboxValues[index],
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _checkboxValues[index] =
                                          !_checkboxValues[index];
                                    });
                                    _currentMarker = _markers.singleWhere(
                                        (marker) =>
                                            marker.position ==
                                            (_standingPoints[index].location));
                                    _location = _currentMarker!.position;
                                    _moveToLocation();
                                    _toggleMarker();
                                  },
                          ),
                          Divider(),
                        ],
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 10),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      elevation: 3.0,
                      shadowColor: Colors.black,
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black,
                      iconColor: Colors.white,
                      disabledBackgroundColor: disabledGrey,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () {
                            try {
                              if (_checkboxValues.length !=
                                  _standingPoints.length) {
                                throw Exception(
                                    "Checkbox values and standing points do not match!");
                              }
                              setState(() {
                                _isLoading = true;
                              });
                              List<StandingPoint> enabledPoints = [];
                              for (int i = 0; i < _standingPoints.length; i++) {
                                if (_checkboxValues[i]) {
                                  enabledPoints.add(_standingPoints[i]);
                                }
                              }
                              Navigator.pop(context, enabledPoints);
                            } catch (e, stacktrace) {
                              print(
                                  "Exception in confirming standing points (standing_points_page.dart): $e");
                              print("Stacktrace: $stacktrace");
                            }
                          },
                    label: Text('Confirm'),
                    icon: const Icon(Icons.check),
                    iconAlignment: IconAlignment.end,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
