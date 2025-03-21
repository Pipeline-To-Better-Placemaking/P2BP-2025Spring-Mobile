import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/firestore_functions.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';
import 'project_details_page.dart';
import 'db_schema_classes.dart';
import 'google_maps_functions.dart';
import 'package:file_selector/file_selector.dart';

import 'home_screen.dart';

class SectionCutter extends StatefulWidget {
  final Project projectData;
  final SectionCutterTest activeTest;

  /// IMPORTANT: When navigating to this page, pass in project details. The
  /// project details page already contains project info, so you should use
  /// that data.
  const SectionCutter(
      {super.key, required this.projectData, required this.activeTest});

  @override
  State<SectionCutter> createState() => _SectionCutterState();
}

const XTypeGroup acceptedFileTypes = XTypeGroup(
  label: 'section cutter uploads',
  extensions: <String>['jpg', 'png', 'pdf'],
);

class _SectionCutterState extends State<SectionCutter> {
  bool _isLoadingUpload = false;
  bool _uploaded = false;
  bool _failedToUpload = false;
  String _errorText = 'Failed to upload new image.';
  String _directions =
      "Go to designated section. Then upload the section drawing here.";
  XFile? sectionCutterFile;
  final double _bottomSheetHeight = 300;
  late DocumentReference teamRef;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation; // Default location
  SectionCutterTest? currentTest;
  Set<Polygon> _polygons = {}; // Set of polygons
  Set<Polyline> _polyline = {};
  List<LatLng> _sectionPoints = [];
  bool _directionsVisible = true;

  MapType _currentMapType = MapType.satellite; // Default map type

  Project? project;

  double _zoom = 14;

  @override
  void initState() {
    super.initState();
    initProjectArea();
  }

  /// Gets the project polygon, adds it to the current polygon list, and
  /// centers the map over it.
  void initProjectArea() {
    setState(() {
      _polygons = getProjectPolygon(widget.projectData.polygonPoints);
      _location = getPolygonCentroid(_polygons.first);
      // Take some latitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      // TODO: dynamic zooming
      _sectionPoints = widget.activeTest.linePoints;
      _polyline = {
        Polyline(
          polylineId:
              PolylineId(DateTime.now().millisecondsSinceEpoch.toString()),
          points: _sectionPoints,
          color: Colors.green,
          width: 4,
        )
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToLocation(); // Ensure the map is centered on the current location
  }

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
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: Center(
          child: Stack(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height,
                child: GoogleMap(
                  // TODO: size based off of bottomsheet container
                  padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                  onMapCreated: _onMapCreated,
                  initialCameraPosition:
                      CameraPosition(target: _location, zoom: _zoom),
                  polygons: _polygons,
                  polylines: _polyline,
                  mapType: _currentMapType, // Use current map type
                ),
              ),
              DirectionsWidget(
                  onTap: () {
                    setState(() {
                      _directionsVisible = !_directionsVisible;
                    });
                  },
                  text: _directions,
                  visibility: _directionsVisible),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding:
                      EdgeInsets.only(bottom: _bottomSheetHeight + 50, left: 5),
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
        bottomSheet: Container(
          height: _bottomSheetHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 5),
              Text(
                'Section Cutter',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: placeYellow,
                ),
              ),
              Text(
                'Upload your section drawing here.',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: 35),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: SizedBox(),
                  ),
                  _isLoadingUpload
                      ? const Center(child: CircularProgressIndicator())
                      : Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () async {
                              sectionCutterFile = await openFile(
                                acceptedTypeGroups: <XTypeGroup>[
                                  acceptedFileTypes
                                ],
                              );
                              setState(() {
                                _isLoadingUpload = true;
                              });
                              if (sectionCutterFile != null) {
                                // save to firebase
                                setState(() {
                                  _failedToUpload = false;
                                  _uploaded = true;
                                  _directions = "Click finish to finish test.";
                                });
                              } else {
                                setState(() {
                                  _failedToUpload = true;
                                  _errorText = 'Failed to upload new image.';
                                });
                                print("No file selected");
                              }
                              setState(() {
                                _isLoadingUpload = false;
                              });
                            },
                            label: Text(
                              'Upload File',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            icon: _uploaded
                                ? Icon(Icons.check)
                                : Icon(Icons.upload_file),
                            iconAlignment: IconAlignment.end,
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 20),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              iconColor: Colors.black,
                              iconSize: 25,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ),
                        ),
                  Expanded(
                    flex: 1,
                    child: (_uploaded && !_isLoadingUpload)
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () {
                                if (sectionCutterFile != null) {
                                  sectionCutterFile = null;
                                }
                                setState(() {
                                  _failedToUpload = false;
                                  _uploaded = false;
                                  _directions =
                                      "Go to designated section. Then upload the section drawing here.";
                                });
                              },
                              icon: Icon(Icons.cancel),
                              color: Colors.red[700],
                            ),
                          )
                        : SizedBox(),
                  ),
                ],
              ),
              SizedBox(height: 5),
              _failedToUpload
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Text.rich(
                        TextSpan(
                          text: _errorText,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.red,
                        ),
                      ),
                    )
                  : SizedBox(),
              SizedBox(height: 5),
              Text(
                'Accepted formats: .png, .pdf, .jpg',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: Row(
                  spacing: 10,
                  children: <Widget>[
                    EditButton(
                      text: 'Back',
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      onPressed: _isLoadingUpload
                          ? null
                          : () => Navigator.pop(context, 'Back'),
                      iconAlignment: IconAlignment.start,
                      icon: Icon(Icons.chevron_left, color: Colors.black),
                    ),
                    Flexible(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: EditButton(
                          text: 'Finish',
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          icon: const Icon(Icons.chevron_right,
                              color: Colors.black),
                          onPressed: _isLoadingUpload
                              ? null
                              : () async {
                                  final bool finishSuccess = await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return TestFinishDialog(
                                            onNext: () async {
                                          if (sectionCutterFile == null) {
                                            Navigator.pop(context, false);
                                            setState(() {
                                              _failedToUpload = true;
                                              _errorText =
                                                  'No file uploaded. Please upload an image first.';
                                            });
                                            print("No file uploaded.");
                                            return;
                                          }
                                          Navigator.pop(context, true);
                                        });
                                      });
                                  if (finishSuccess) {
                                    setState(() {
                                      _isLoadingUpload = true;
                                    });
                                    Section data = await widget.activeTest!
                                        .saveXFile(sectionCutterFile!);
                                    widget.activeTest!.submitData(data);
                                    if (!context.mounted) return;
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HomeScreen(),
                                        ));
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProjectDetailsPage(
                                                  projectData:
                                                      widget.projectData),
                                        ));
                                  }
                                },
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
