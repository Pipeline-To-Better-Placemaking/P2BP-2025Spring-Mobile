import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/extensions.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';

import 'db_schema_classes.dart';
import 'google_maps_functions.dart';

class SectionCutter extends StatefulWidget {
  final Project activeProject;
  final SectionCutterTest activeTest;

  /// IMPORTANT: When navigating to this page, pass in project details. The
  /// project details page already contains project info, so you should use
  /// that data.
  const SectionCutter(
      {super.key, required this.activeProject, required this.activeTest});

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
  static const double _bottomSheetHeight = 325;
  late DocumentReference teamRef;

  double _zoom = 18;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  MapType _currentMapType = MapType.satellite;

  SectionCutterTest? currentTest;
  final Set<Polygon> _polygons = {};
  Set<Polyline> _polyline = {};
  List<LatLng> _sectionPoints = [];
  bool _directionsVisible = true;

  Project? project;

  @override
  void initState() {
    super.initState();
    _polygons.add(getProjectPolygon(widget.activeProject.polygonPoints));
    _location = getPolygonCentroid(_polygons.first);
    _zoom = getIdealZoom(
      _polygons.first.toMPLatLngList(),
      _location.toMPLatLng(),
    );
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
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: Stack(
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height,
              child: GoogleMap(
                padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                onMapCreated: _onMapCreated,
                initialCameraPosition:
                    CameraPosition(target: _location, zoom: _zoom),
                polygons: _polygons,
                polylines: _polyline,
                mapType: _currentMapType,
                myLocationButtonEnabled: false,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: _directionsVisible
                          ? DirectionsText(
                              onTap: () {
                                setState(() {
                                  _directionsVisible = !_directionsVisible;
                                });
                              },
                              text: _directions,
                            )
                          : SizedBox(),
                    ),
                    SizedBox(width: 15),
                    Column(
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
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomSheet: SizedBox(
          height: _bottomSheetHeight,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            decoration: BoxDecoration(
              gradient: formGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0.0, 1.0),
                  blurRadius: 6.0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 5),
                Text(
                  'Section Cutter',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: p2bpBlue,
                  ),
                ),
                Text(
                  'Upload your section drawing here.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 25),
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
                                    _directions =
                                        "Click finish to finish test.";
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
                                        "Go to designated section. Then upload "
                                        "the section drawing here.";
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
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        child: EditButton(
                          text: 'Finish',
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          icon: const Icon(Icons.chevron_right,
                              color: Colors.black),
                          onPressed: _isLoadingUpload
                              ? null
                              : () async {
                                  final bool? finishSuccess = await showDialog(
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
                                  if (finishSuccess == true) {
                                    setState(() {
                                      _isLoadingUpload = true;
                                    });
                                    Section data = await widget.activeTest
                                        .saveXFile(sectionCutterFile!);
                                    widget.activeTest.submitData(data);
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
