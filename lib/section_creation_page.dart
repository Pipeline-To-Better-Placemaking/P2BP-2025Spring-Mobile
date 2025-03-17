import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'google_maps_functions.dart';
import 'db_schema_classes.dart';
import 'firestore_functions.dart';

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
  String _directions = "Create your section by marking two points.";
  Set<Polygon> _polygons = {}; // Set of polygons
  Set<Marker> _markers = {}; // Set of markers for points
  MapType _currentMapType = MapType.satellite; // Default map type
  Project? project;
  Set<Polyline> _polyline = {};
  LatLng? _currentPoint;
  bool _sectionSet = false;

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

  void _polylineTap(LatLng point) {
    if (_sectionSet) return;
    final MarkerId markerId = MarkerId('marker_${point.toString()}');
    setState(() {
      _markers.add(
        Marker(
          markerId: markerId,
          position: point,
          consumeTapEvents: true,
          onTap: () {
            // If the marker is tapped again, it will be removed
            setState(() {
              _currentPoint = null;
              _markers.removeWhere((marker) => marker.markerId == markerId);
            });
          },
        ),
      );
      if (_currentPoint == null) return;
      final Polyline? polyline =
          createPolyline([_currentPoint!, point], Colors.green[600]!);
      if (polyline == null) return;
      if (_markers.length == 2) _markers = {};
      _polyline = {polyline};
      _sectionSet = true;
      _directions =
          'Section set. Click confirm to save, or delete and start over.';
    });
    _currentPoint = point;
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
                          markers: _markers,
                          mapType: _currentMapType, // Use current map type
                          onTap: _polylineTap,
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
                            padding: const EdgeInsets.only(
                                left: 10.0, bottom: 130.0),
                            child: FloatingActionButton(
                              tooltip: 'Clear all.',
                              heroTag: null,
                              onPressed: () {
                                setState(() {
                                  _markers = {};
                                  _currentPoint = null;
                                  _polyline = {};
                                  _sectionSet = false;
                                  _directions =
                                      "Create your section by marking two points. Then click the check to confirm.";
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
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
