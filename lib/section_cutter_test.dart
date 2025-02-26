import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';
import 'db_schema_classes.dart';
import 'firestore_functions.dart';
import 'google_maps_functions.dart';
import 'package:file_selector/file_selector.dart';

class SectionCutter extends StatefulWidget {
  final Project projectData;

  /// IMPORTANT: When navigating to this page, pass in project details. The
  /// project details page already contains project info, so you should use
  /// that data.
  const SectionCutter({super.key, required this.projectData});

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
  bool _isLoading = false;
  bool _failedToUpload = false;
  XFile? sectionCutterFile;
  late DocumentReference teamRef;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation; // Default location

  Set<Polygon> _polygons = {}; // Set of polygons

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
      _polygons = getProjectPolygon(widget.projectData.polygonPoints);
      _location = getPolygonCentroid(_polygons.first);
      // Take some lattitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      // TODO: dynamic zooming
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToLocation(); // Ensure the map is centered on the current location
  }

  void _moveToLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: 14),
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Stack(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: GoogleMap(
                        // TODO: size based off of bottomsheet container
                        padding: EdgeInsets.symmetric(vertical: 300),
                        onMapCreated: _onMapCreated,
                        initialCameraPosition:
                            CameraPosition(target: _location, zoom: 14),
                        polygons: _polygons,
                        mapType: _currentMapType, // Use current map type
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                height: 300,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 5),
                    Text(
                      'Section Cutter',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow[600],
                      ),
                    ),
                    Text(
                      'Take your photo <ask about terms here> and upload it here.',
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
                                      });
                                    } else {
                                      setState(() {
                                        _failedToUpload = true;
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
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
                          child: _uploaded
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
                                text: 'Failed to upload new image.',
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
                                onPressed: () async {
                                  // todo: await saveTest()
                                  // saveTest()
                                  //   Navigator.pushReplacement(
                                  //       context,
                                  //       MaterialPageRoute(
                                  //         builder: (context) => HomeScreen(),
                                  //       ));
                                  //   // TODO: Push to project details page.
                                  //   Navigator.push(
                                  //       context,
                                  //       MaterialPageRoute(
                                  //         builder: (context) => HomeScreen(),
                                  //       ));
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
