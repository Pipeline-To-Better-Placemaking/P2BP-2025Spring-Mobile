import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';
import 'google_maps_functions.dart';
import 'db_schema_classes.dart';
import 'firestore_functions.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

class SectionCreationPage extends StatefulWidget {
  final Project activeProject;
  final List? currentSection;
  const SectionCreationPage(
      {super.key, required this.activeProject, this.currentSection});

  @override
  State<SectionCreationPage> createState() => _SectionCreationPageState();
}

class _SectionCreationPageState extends State<SectionCreationPage> {
  DocumentReference? teamRef;
  GoogleMapController? mapController;
  LatLng _location = defaultLocation; // Default location
  bool _isLoading = true;
  String _directions =
      "Create your section by marking your points. Then click confirm.";
  Set<Polygon> _polygons = {}; // Set of polygons (project area polygon)
  Set<Marker> _markers = {}; // Set of markers for points
  List<LatLng> _linePoints = [];
  MapType _currentMapType = MapType.satellite; // Default map type
  Project? project;
  Set<Polyline> _polyline = {};
  List<mp.LatLng> _projectArea = [];
  bool _sectionSet = false;
  bool _directionsVisible = true;
  bool _outsidePoint = false;

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
      _projectArea = _polygons.first.toMPLatLngList();
      _location = getPolygonCentroid(_polygons.first);
      // Take some latitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      // TODO: dynamic zooming
      if (widget.currentSection != null) {
        final List? currentSection = widget.currentSection;
        _loadCurrentSection(currentSection);
      }
      _isLoading = false;
    });
  }

  void _loadCurrentSection(List? currentSection) {
    final Polyline? polyline =
        createPolyline(currentSection!.toLatLngList(), Colors.green[600]!);
    if (polyline == null) return;
    setState(() {
      _polyline = {polyline};
    });
  }

  Future<void> _polylineTap(LatLng point) async {
    if (_sectionSet) return;
    if (!mp.PolygonUtil.containsLocation(
        mp.LatLng(point.latitude, point.longitude), _projectArea, true)) {
      setState(() {
        _outsidePoint = true;
      });
    }
    final MarkerId markerId = MarkerId('marker_${point.toString()}');
    _linePoints.add(point);
    setState(() {
      _markers.add(
        Marker(
          markerId: markerId,
          position: point,
          consumeTapEvents: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(125),
          onTap: () {
            // If the marker is tapped again, it will be removed
            setState(() {
              _linePoints.remove(point);
              _markers.removeWhere((marker) => marker.markerId == markerId);
            });
          },
        ),
      );
      final Polyline? polyline =
          createPolyline(_linePoints, Colors.green[600]!);
      if (polyline == null) return;
      _polyline = {polyline};
    });
    if (_outsidePoint) {
      // TODO: fix delay. delay will overlap with consecutive taps. this means taps do not necessarily refresh the timer and will end prematurely
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _outsidePoint = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToLocation(); // Ensure the map is centered on the current location
  }

  void _moveToLocation() {
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
                          polylines: _polyline,
                          markers: (_markers.isNotEmpty)
                              ? {_markers.first, _markers.last}
                              : {},
                          mapType: _currentMapType, // Use current map type
                          onTap: _polylineTap,
                        ),
                        DirectionsWidget(
                          onTap: () {
                            setState(() {
                              _directionsVisible = !_directionsVisible;
                            });
                          },
                          text: _directions,
                          visibility: _directionsVisible,
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 10.0, bottom: 130.0),
                            child: FloatingActionButton(
                              tooltip: 'Clear all.',
                              heroTag: null,
                              onPressed: () {
                                setState(() {
                                  _markers = {};
                                  _linePoints = [];
                                  _polyline = {};
                                  _sectionSet = false;
                                  _directions =
                                      "Create your section by marking your points. Then click confirm.";
                                });
                              },
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.delete_sweep,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 10.0, bottom: 50),
                            child: FloatingActionButton(
                              tooltip: 'Change map type.',
                              onPressed: _toggleMapType,
                              backgroundColor: Colors.green,
                              child: const Icon(Icons.map),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.only(left: 15, right: 15),
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
                                        setState(() {
                                          _isLoading = true;
                                        });
                                        Navigator.pop(
                                            context,
                                            _polyline.isEmpty
                                                ? null
                                                : _polyline.single.points
                                                    .toGeoPointList());
                                      } catch (e, stacktrace) {
                                        print(
                                            "Exception in confirming section (section_creation_point.dart): $e");
                                        print("Stacktrace: $stacktrace");
                                      }
                                    },
                              label: Text('Confirm'),
                              icon: const Icon(Icons.check),
                              iconAlignment: IconAlignment.end,
                            ),
                          ),
                        ),
                        _outsidePoint ? TestErrorText() : SizedBox(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
