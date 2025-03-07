import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'google_maps_functions.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';
import 'db_schema_classes.dart';
import 'dart:math';
import 'firestore_functions.dart';

class StandingPointsPage extends StatefulWidget {
  // TODO: add test data for adding standing points to test
  final Project activeProject;
  const StandingPointsPage({super.key, required this.activeProject});

  @override
  State<StandingPointsPage> createState() => _StandingPointsPageState();
}

final User? loggedInUser = FirebaseAuth.instance.currentUser;
final AssetMapBitmap disabledIcon = AssetMapBitmap(
  'assets/standing_point_disabled_marker.png',
  width: 45,
  height: 45,
);
final AssetMapBitmap enabledIcon = AssetMapBitmap(
  'assets/standing_point_enabled_marker.png',
  width: 45,
  height: 45,
);

class _StandingPointsPageState extends State<StandingPointsPage> {
  DocumentReference? teamRef;
  GoogleMapController? mapController;
  LatLng _location = defaultLocation; // Default location
  bool _isLoading = true;
  String _directions =
      "Select the standing points you want to use in this test.";
  List<LatLng> _standingPoints = [];
  Set<Polygon> _polygons = {}; // Set of polygons
  Set<Marker> _markers = {}; // Set of markers for points
  List<Marker> _markerList = [];
  Marker? _tappedMarker;
  double _bottomSheetHeight = 300;
  MapType _currentMapType = MapType.satellite; // Default map type

  Project? project;

  @override
  void initState() {
    super.initState();
    initProjectArea();
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
      _standingPoints = widget.activeProject.standingPoints.toLatLngList();
      _markers = _setMarkersFromPoints(_standingPoints);
      _markerList = _markers.toList(growable: true);
      _isLoading = false;
    });
  }

  Set<Marker> _setMarkersFromPoints(List<LatLng> points) {
    Set<Marker> markers = {};
    for (LatLng point in points) {
      final markerId = MarkerId(point.toString());
      markers.add(
        Marker(
            markerId: markerId,
            position: point,
            icon: disabledIcon,
            consumeTapEvents: true,
            onTap: () {
              final Marker thisMarker =
                  _markers.firstWhere((marker) => marker.markerId == markerId);
              _tappedMarker = thisMarker;
              _toggleMarker();
            }),
      );
    }
    return markers;
  }

  void _toggleMarker() {
    if (_tappedMarker == null) return;
    if (_tappedMarker?.icon == enabledIcon) {
      setState(() {
        _markers.add(_tappedMarker!.copyWith(iconParam: disabledIcon));
      });
      _markerList.add(_tappedMarker!.copyWith(iconParam: enabledIcon));
    } else if (_tappedMarker?.icon == disabledIcon) {
      print("\n\n\nPL");
      setState(() {
        _markers.add(_tappedMarker!.copyWith(iconParam: enabledIcon));
      });
      _markerList.add(_tappedMarker!.copyWith(iconParam: enabledIcon));
    }
    setState(() {
      _markers.remove(_tappedMarker);
    });
    _markerList.remove(_tappedMarker);
    _tappedMarker = null;
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToCurrentLocation(); // Ensure the map is centered on the current location
  }

  void _moveToCurrentLocation() {
    if (mapController == null) return;
    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: 14.0),
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
    return SafeArea(
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: Stack(
                      children: [
                        GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition:
                              CameraPosition(target: _location, zoom: 14.0),
                          polygons: _polygons,
                          markers: _markers,
                          mapType: _currentMapType, // Use current map type
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20.0, horizontal: 25.0),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              decoration: BoxDecoration(
                                color: directionsTransparency,
                                gradient: defaultGrad,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(10)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _directions,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 10.0, bottom: 50.0),
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
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: EditButton(
                        text: 'Next',
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF4871AE),
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _isLoading ? null : () {},
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 30.0, horizontal: 100.0),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red[900],
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'You tried to place a point outside of the project area!',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[50],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        bottomSheet: SizedBox(
          height: _bottomSheetHeight,
          child: ListView.separated(
            padding: const EdgeInsets.only(
              left: 15,
              right: 15,
              top: 25,
              bottom: 25,
            ),
            itemCount: _markers.length,
            itemBuilder: (BuildContext context, int index) {
              return Row(
                children: <Widget>[
                  Checkbox(
                    onChanged: (bool? value) {
                      setState(() {
                        value = value!;
                      });
                    },
                    value: true,
                  ),
                  Column(
                    children: [
                      Text("Title"),
                      Text(
                          "${_markerList[index].position.latitude}, ${_markerList[index].position.longitude}"),
                    ],
                  ),
                ],
              );
            },
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(
              height: 50,
            ),
          ),
        ),
      ),
    );
  }
}
