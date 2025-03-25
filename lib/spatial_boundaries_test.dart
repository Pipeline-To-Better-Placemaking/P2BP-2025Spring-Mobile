import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'firestore_functions.dart';
import 'theme.dart';
import 'db_schema_classes.dart';
import 'google_maps_functions.dart';
import 'widgets.dart';
import 'spatial_boundaries_instructions.dart';
import 'dart:io';

class SpatialBoundariesTestPage extends StatefulWidget {
  final Project activeProject;
  final SpatialBoundariesTest activeTest;

  const SpatialBoundariesTestPage({
    super.key,
    required this.activeProject,
    required this.activeTest,
  });

  @override
  State<SpatialBoundariesTestPage> createState() =>
      _SpatialBoundariesTestPageState();
}

class _SpatialBoundariesTestPageState extends State<SpatialBoundariesTestPage> {
  bool _isLoading = true;
  bool _polygonMode = false;
  bool _polylineMode = false;
  bool _outsidePoint = false;
  bool _boundariesVisible = true;
  bool _isBoundariesMenuVisible = false;

  bool _isTestRunning = false;
  int _remainingSeconds = 300;
  Timer? _timer;
  Timer? _hintTimer;

  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  MapType _currentMapType = MapType.satellite; // Default map type
  List<mp.LatLng> _projectArea = [];

  Set<Polygon> _projectPolygon = {}; // Set for project polygon
  Set<Polygon> _userPolygons = {}; // Set of user-created polygons
  List<LatLng> _polygonPoints = []; // Points for the polygon
  Set<Marker> _polygonMarkers = {}; // Set of markers for polygon creation
  Set<Polyline> _polylines = {};
  Set<Marker> _polylineMarkers = {};
  List<LatLng> _polylinePoints = [];

  final SpatialBoundariesData _newData = SpatialBoundariesData();
  BoundaryType? _boundaryType;
  ConstructedBoundaryType? _constructedType;
  MaterialBoundaryType? _materialType;
  ShelterBoundaryType? _shelterType;

  static const List<String> _directionsList = [
    'Select a type of boundary.',
    'Tap to place points outlining the boundary, then tap confirm when done.',
  ];
  late String _directionsActive;
  static const double _bottomSheetHeight = 320;

  BitmapDescriptor?
      polyNodeMarker; // Custom marker for plotting boundary points.

  @override
  void initState() {
    super.initState();
    _initProjectArea();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("PostFrameCallback fired");
      _loadCustomMarker();
      _showInstructionOverlay();
    });
    _directionsActive = _directionsList[0];
  }

  /// Function to load custom marker icons using AssetMapBitmap.
  Future<void> _loadCustomMarker() async {
    final ImageConfiguration configuration =
        createLocalImageConfiguration(context);
    try {
      polyNodeMarker = await AssetMapBitmap.create(
        configuration,
        'assets/temp_point_marker.png',
        width: 40,
        height: 40,
      );

      print("Custom markers loaded successfully.");
    } catch (e) {
      print("Error loading custom markers: $e");
    }
  }

  /// Gets the project polygon, adds it to the current polygon list, and
  /// centers the map over it.
  void _initProjectArea() {
    setState(() {
      _projectPolygon = getProjectPolygon(widget.activeProject.polygonPoints);
      _location = getPolygonCentroid(_projectPolygon.first);
      // Take some latitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      _projectArea = _projectPolygon.first.toMPLatLngList();
      // TODO: dynamic zooming
      _isLoading = false;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToLocation(); // Ensure the map is centered on the current location
  }

  /// Moves camera to project location.
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

  /// Called whenever map is tapped
  Future<void> _togglePoint(LatLng point) async {
    try {
      if (!mp.PolygonUtil.containsLocation(
          mp.LatLng(point.latitude, point.longitude), _projectArea, true)) {
        setState(() {
          _outsidePoint = true;
        });
      }
      if (_polygonMode) _polygonTap(point);
      if (_polylineMode) _polylineTap(point);
      if (_outsidePoint) {
        // TODO: fix delay. delay will overlap with consecutive taps. this means taps do not necessarily refresh the timer and will end prematurely
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _outsidePoint = false;
        });
      }
    } catch (e, stacktrace) {
      print('Error in spatial_boundaries_test.dart, _togglePoint(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  /// Place marker to be used in making polygon.
  void _polygonTap(LatLng point) {
    final markerId = MarkerId(point.toString());
    setState(() {
      _polygonPoints.add(point);
      _polygonMarkers.add(
        Marker(
          markerId: markerId,
          position: point,
          icon: polyNodeMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          consumeTapEvents: true,
          onTap: () {
            // If the marker is tapped again, it will be removed
            setState(() {
              _polygonPoints.remove(point);
              _polygonMarkers
                  .removeWhere((marker) => marker.markerId == markerId);
            });
          },
        ),
      );
    });
  }

  /// Convert markers to polygon and save the data to be submitted later.
  void _finalizePolygon() {
    Set<Polygon> tempPolygon;
    try {
      // Create polygon and add it to the visible set of polygons.
      tempPolygon = finalizePolygon(_polygonPoints);
      final colors = getPolygonColors(_boundaryType!);
      Polygon coloredPolygon = Polygon(
        polygonId: tempPolygon.first.polygonId,
        points: tempPolygon.first.points,
        strokeColor: colors['stroke']!,
        fillColor: colors['fill']!,
        strokeWidth: tempPolygon.first.strokeWidth,
      );
      _userPolygons.add(coloredPolygon);

      if (_boundaryType == BoundaryType.material && _materialType != null) {
        _newData.material.add(MaterialBoundary(
          polygon: coloredPolygon,
          materialType: _materialType!,
        ));
      } else if (_boundaryType == BoundaryType.shelter &&
          _shelterType != null) {
        _newData.shelter.add(ShelterBoundary(
          polygon: coloredPolygon,
          shelterType: _shelterType!,
        ));
      } else {
        throw Exception('Invalid boundary type in _finalizePolygon(), '
            '_boundaryType = $_boundaryType');
      }

      // Reset everything to be able to make new boundary.
      _resetPlacementVariables();
    } catch (e, stacktrace) {
      print('Exception in _finalizePolygon(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  /// Returns stroke and fill colors for a boundary polygon based on its type.
  Map<String, Color> getPolygonColors(BoundaryType type) {
    if (type == BoundaryType.material) {
      return {
        'stroke': Color(0xFF00897B),
        'fill': Color(0xFF4DB6AC).withValues(alpha: 0.3),
      };
    } else if (type == BoundaryType.shelter) {
      return {
        'stroke': Color(0xFFF57C00),
        'fill': Color(0xFFFFB74D).withValues(alpha: 0.3),
      };
    } else {
      throw Exception('Unexpected boundary type');
    }
  }

  /// Place marker to be used in making polyline.
  void _polylineTap(LatLng point) {
    final markerId = MarkerId(point.toString());
    setState(() {
      _polylinePoints.add(point);
      _polylineMarkers.add(
        Marker(
          markerId: markerId,
          position: point,
          icon: polyNodeMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          consumeTapEvents: true,
          onTap: () {
            // If the marker is tapped again, it will be removed
            setState(() {
              _polylinePoints.remove(point);
              _polylineMarkers
                  .removeWhere((marker) => marker.markerId == markerId);
            });
          },
        ),
      );
    });
  }

  /// Convert markers to polyline and save the data to be submitted later.
  void _finalizePolyline() {
    Polyline? tempPolyline;
    try {
      // Create polyline and add it to the visible set of polylines.
      tempPolyline = createPolyline(
        _polylinePoints,
        ConstructedBoundary.polylineColor,
      );
      if (tempPolyline == null) {
        throw Exception('Failed to create Polyline from given points.');
      }

      // Get the correct color for this boundary type
      final polylineColor = getPolylineColor(_boundaryType!);

      // Create a new polyline with the appropriate color
      Polyline coloredPolyline = Polyline(
        polylineId: tempPolyline.polylineId,
        points: tempPolyline.points,
        color: polylineColor,
        width: tempPolyline.width,
      );

      _polylines.add(coloredPolyline);

      if (_boundaryType == BoundaryType.constructed &&
          _constructedType != null) {
        _newData.constructed.add(ConstructedBoundary(
          polyline: coloredPolyline,
          constructedType: _constructedType!,
        ));
      } else {
        throw Exception('Invalid boundary type in _finalizePolyline(),'
            '_boundaryType = $_boundaryType');
      }

      // Reset everything to be able to make new boundary.
      _resetPlacementVariables();
    } catch (e, stacktrace) {
      print('Exception in _finalizePolyline(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  /// Returns stroke color for a boundary polyline based on its type.
  Color getPolylineColor(BoundaryType type) {
    if (type == BoundaryType.constructed) {
      return Color(0xFFD81B60);
    } else {
      throw Exception('Unexpected boundary value');
    }
  }

  /// Resets all state variables relevant to placing boundaries to default.
  void _resetPlacementVariables() {
    setState(() {
      _polylinePoints.clear();
      _polylineMarkers.clear();
      _polylineMode = false;
      _polygonPoints.clear();
      _polygonMarkers.clear();
      _polygonMode = false;

      _boundaryType = null;
      _constructedType = null;
      _materialType = null;
      _shelterType = null;
      _directionsActive = _directionsList[0];
    });
  }

  /// Display constructed modal and use result to adjust state variables.
  void _doConstructedModal(BuildContext context) async {
    final ConstructedBoundaryType? constructed = await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => _ConstructedDescriptionForm(),
    );
    if (constructed != null) {
      setState(() {
        _boundaryType = BoundaryType.constructed;
        _constructedType = constructed;
        _polylineMode = true;
        _directionsActive = _directionsList[1];
      });
    }
  }

  /// Display material modal and use result to adjust state variables.
  void _doMaterialModal(BuildContext context) async {
    final MaterialBoundaryType? material = await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => _MaterialDescriptionForm(),
    );
    if (material != null) {
      setState(() {
        _boundaryType = BoundaryType.material;
        _materialType = material;
        _polygonMode = true;
        _directionsActive = _directionsList[1];
      });
    }
  }

  /// Display shelter modal and use result to adjust state variables.
  void _doShelterModal(BuildContext context) async {
    final ShelterBoundaryType? shelter = await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => _ShelterDescriptionForm(),
    );
    if (shelter != null) {
      setState(() {
        _boundaryType = BoundaryType.shelter;
        _shelterType = shelter;
        _polygonMode = true;
        _directionsActive = _directionsList[1];
      });
    }
  }

  /// Displays instructions for how to conduct Spatial Boundaries test.
  void _showInstructionOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
              horizontal: screenSize.width * 0.05,
              vertical: screenSize.height * 0.005),
          actionsPadding: EdgeInsets.zero,
          title: const Text(
            'How It Works:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: screenSize.width * 0.95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  spatialBoundariesInstructions(),
                  const SizedBox(height: 10),
                  buildLegends(),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: const [
                    Checkbox(value: false, onChanged: null),
                    Text("Don't show this again next time"),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Toggles the user's ability to see boundaries already defined on the map.
  void _toggleBoundariesVisibility() {
    setState(() {
      _boundariesVisible = !_boundariesVisible;
    });
  }

  /// Method to start the test and timer
  void _startTest() {
    setState(() {
      _isTestRunning = true;
      _remainingSeconds = 300;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds <= 0) {
          timer.cancel();
        } else {
          _remainingSeconds--;
        }
      });
    });
  }

  /// Method to end the test and timer.
  void _endTest() {
    _isTestRunning = false;
    _timer?.cancel();
    _hintTimer?.cancel();
    widget.activeTest.submitData(_newData);
    Navigator.pop(context);
  }

  /// Builds a custom AppBar widget that handles the Start/End button and duration timer for the test.
  ///
  /// Additionally, if the device platform is detected to be iOS, changes the status bar color to a white/black depending
  /// on the current map mode to ensure the status bar color contrasts with the map background (unclear if necessary for Android given
  /// the differences in the way the status bar is handled between both platforms).
  AppBar _buildAppBar() {
    return AppBar(
      // Only apply systemOverlayStyle on iOS.
      // Define the systemOverlayStyle based on map type.
      systemOverlayStyle: Platform.isIOS
          ? (_currentMapType == MapType.normal
              // Sets a darker status bar in map view for better visibility.
              ? SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                )
              // Sets a lighter status bar in satellite view for better visibility.
              : SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                ))
          : null,
      toolbarHeight: kToolbarHeight + 10,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 100,
      // Start/End button on the left
      leading: Padding(
        padding: const EdgeInsets.only(top: 5, bottom: 5, left: 20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20), // Rounded rectangle shape.
            ),
            backgroundColor: _isTestRunning ? Colors.red : Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onPressed: () {
            if (_isTestRunning) {
              _endTest();
            } else {
              _startTest();
            }
          },
          child: Text(
            _isTestRunning ? 'End' : 'Start',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
      // Timer on the right
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                formatTime(_remainingSeconds),
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return AdaptiveSafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Stack(
                  children: <Widget>[
                    SizedBox(
                      height: screenHeight,
                      child: GoogleMap(
                        padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                        onMapCreated: _onMapCreated,
                        initialCameraPosition:
                            CameraPosition(target: _location, zoom: 15),
                        markers: {..._polygonMarkers, ..._polylineMarkers},
                        polygons: _boundariesVisible
                            ? _projectPolygon.union(_userPolygons)
                            : _projectPolygon,
                        polylines:
                            _boundariesVisible ? _polylines : <Polyline>{},
                        onTap: _togglePoint,
                        mapType: _currentMapType,
                        myLocationButtonEnabled: false,
                      ),
                    ),
                    // Button for toggling the map mode
                    Positioned(
                        bottom: _bottomSheetHeight + 154,
                        right: 20.0,
                        child: CircularIconMapButton(
                            backgroundColor:
                                Color(0xFF7EAD80).withValues(alpha: 0.9),
                            borderColor: Color(0xFF2D6040),
                            onPressed: _toggleMapType,
                            icon: Icon(Icons.layers))),
                    // Button for toggling instructon overlay
                    if (!_isLoading)
                      Positioned(
                        bottom: _bottomSheetHeight + 92,
                        right: 20,
                        child: CircularIconMapButton(
                          backgroundColor:
                              Color(0xFFBACFEB).withValues(alpha: 0.9),
                          borderColor: Color(0xFF37597D),
                          onPressed: _showInstructionOverlay,
                          icon: Icon(FontAwesomeIcons.info),
                        ),
                      ),
                    Positioned(
                      bottom: _bottomSheetHeight + 30,
                      right: 20.0,
                      child: CircularIconMapButton(
                        backgroundColor:
                            Color(0xFFBD9FE4).withValues(alpha: 0.9),
                        borderColor: Color(0xFF5A3E85),
                        onPressed: () {
                          setState(() {
                            _isBoundariesMenuVisible =
                                !_isBoundariesMenuVisible;
                          });
                        },
                        icon: Icon(
                          Icons.shape_line,
                          color: Color(0xFF5A3E85),
                        ),
                      ),
                    ),
                    // Button for toggling polygon/polyline visibility on the map
                    Positioned(
                      bottom: _bottomSheetHeight + 45,
                      left: 10.0,
                      child: CircularIconMapButton(
                        backgroundColor:
                            Color(0xFFE4E9EF).withValues(alpha: 0.9),
                        borderColor: Color(0xFF4A5D75),
                        onPressed: _toggleBoundariesVisibility,
                        icon: Icon(
                          _boundariesVisible
                              ? FontAwesomeIcons.solidEyeSlash
                              : FontAwesomeIcons.solidEye,
                          color: Color(0xFF4A5D75),
                        ),
                        iconOffset: Offset(-2.0, 0),
                      ),
                    ),
                    // Displays the list of confirmed boundaries and the color legend
                    if (_isBoundariesMenuVisible)
                      Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top +
                              kToolbarHeight +
                              30,
                          bottom: _bottomSheetHeight + 30.0,
                          left: 20.0,
                          right: 20.0,
                        ),
                        child: DataEditMenu(
                          heightMultiplier: (MediaQuery.of(context)
                                      .size
                                      .height -
                                  MediaQuery.of(context).padding.top -
                                  kToolbarHeight -
                                  _bottomSheetHeight -
                                  60.0) / // 60.0 accounts for padding spaces
                              MediaQuery.of(context).size.height,
                          title: 'Boundary Color Guide',
                          colorLegendItems: [
                            for (final type in SpatialBoundaryType.values)
                              ColorLegendItem(
                                label: type.displayName,
                                color: type.color,
                              ),
                          ],
                          placedDataList: _buildPlacedBoundariesList(),
                          onPressedCloseMenu: () => setState(() =>
                              _isBoundariesMenuVisible =
                                  !_isBoundariesMenuVisible),
                          onPressedClearAll: () {},
                        ),
                      ),
                  ],
                ),
              ),
        bottomSheet: _isLoading
            ? SizedBox()
            : SizedBox(
                height: _bottomSheetHeight,
                child: _buildBottomSheetStack(context),
              ),
      ),
    );
  }

  /// (TODO) Builds the list of already placed boundary polygons/polylines
  ListView _buildPlacedBoundariesList() {
    // Returns an empty list to satisfy the required field of the Data Menu
    return ListView();

    // TODO: Adapt this code to work with SpatialBoundaries (I didn't want to mess with it and potentially
    // break anything that's working perfectly fine as is).
    //
    // // Tracks how many elements of each type have been added so far.
    // Map<ActivityTypeInMotion, int> typeCounter = {};
    // return ListView.builder(
    //   padding: EdgeInsets.zero,
    //   itemCount: _newData.persons.length,
    //   itemBuilder: (context, index) {
    //     final person = _newData.persons[index];
    //     // Increment this type's count
    //     typeCounter.update(person.activity, (i) => i + 1, ifAbsent: () => 1);

    //     return ListTile(
    //       contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    //       title: Text(
    //         '${person.activity.displayName} Route ${typeCounter[person.activity]}',
    //         style: const TextStyle(fontWeight: FontWeight.bold),
    //       ),
    //       subtitle: Text(
    //         'Points: ${person.polyline.points.length}',
    //         textAlign: TextAlign.left,
    //       ),
    //       trailing: IconButton(
    //         icon: const Icon(
    //           FontAwesomeIcons.trashCan,
    //           color: Color(0xFFD32F2F),
    //         ),
    //         onPressed: () {
    //           setState(() {
    //             // Delete this polyline and related objects from all sources.
    //             _confirmedPolylineEndMarkers.removeWhere((marker) {
    //               final points = person.polyline.points;
    //               if (marker.markerId.value == points.first.toString() ||
    //                   marker.markerId.value == points.last.toString()) {
    //                 return true;
    //               }
    //               return false;
    //             });
    //             _confirmedPolylines.remove(person.polyline);
    //             _newData.persons.remove(person);
    //           });
    //         },
    //       ),
    //     );
    //   },
    // );
  }

  Stack _buildBottomSheetStack(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            gradient: formGradient,
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
                  'Spatial Boundaries',
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F6DCF),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Text(
                    _directionsActive,
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                spacing: 10,
                children: <Widget>[
                  Expanded(
                    flex: 11,
                    child: FilledButton(
                      style: testButtonStyle,
                      onPressed: (_polygonMode || _polylineMode)
                          ? null
                          : () {
                              _doConstructedModal(context);
                            },
                      child: Text('Constructed'),
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: FilledButton(
                      style: testButtonStyle,
                      onPressed: (_polygonMode || _polylineMode)
                          ? null
                          : () {
                              _doMaterialModal(context);
                            },
                      child: Text('Material'),
                    ),
                  ),
                  Expanded(
                    flex: 7,
                    child: FilledButton(
                      style: testButtonStyle,
                      onPressed: (_polygonMode || _polylineMode)
                          ? null
                          : () {
                              _doShelterModal(context);
                            },
                      child: Text('Shelter'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 15,
                children: <Widget>[
                  Expanded(
                    flex: 9,
                    child: EditButton(
                      text: 'Confirm Shape',
                      foregroundColor: Colors.green,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      icon: const Icon(Icons.check),
                      iconColor: Colors.green,
                      onPressed: (_polygonMode && _polygonPoints.length >= 3)
                          ? _finalizePolygon
                          : (_polylineMode && _polylinePoints.length >= 2)
                              ? _finalizePolyline
                              : null,
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: EditButton(
                      text: 'Cancel',
                      foregroundColor: Colors.red,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      icon: const Icon(Icons.cancel),
                      iconColor: Colors.red,
                      onPressed: (_polygonMode || _polylineMode)
                          ? _resetPlacementVariables
                          : null,
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      label: Text('Back'),
                      icon: Icon(Icons.chevron_left),
                      iconAlignment: IconAlignment.start,
                    ),
                  ),
                  Flexible(
                    child: FilledButton.icon(
                      style: testButtonStyle,
                      onPressed: (_polygonMode || _polylineMode)
                          ? null
                          : () {
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
        _outsidePoint
            ? Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 30.0, horizontal: 100.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red[900],
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'You have placed a point outside of the project area!',
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
              )
            : SizedBox(),
      ],
    );
  }
}

class _ConstructedDescriptionForm extends StatefulWidget {
  const _ConstructedDescriptionForm();

  @override
  State<_ConstructedDescriptionForm> createState() =>
      _ConstructedDescriptionFormState();
}

class _ConstructedDescriptionFormState
    extends State<_ConstructedDescriptionForm> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          gradient: formGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Center(
                child: Text(
                  'Boundary Description',
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F6DCF),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Center(
                  child: Text.rich(
                    textAlign: TextAlign.center,
                    softWrap: true,
                    TextSpan(
                      text: 'Choose the option that ',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'best',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        TextSpan(text: ' describes your boundary.'),
                      ],
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
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ConstructedBoundaryType.curb,
                        );
                      },
                      child: Text(
                        'Curbs',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ConstructedBoundaryType.buildingWall,
                        );
                      },
                      child: Text(
                        'Building Wall',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                spacing: 20,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ConstructedBoundaryType.fence,
                        );
                      },
                      child: Text(
                        'Fences',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ConstructedBoundaryType.planter,
                        );
                      },
                      child: Text(
                        'Planter',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                spacing: 20,
                children: <Widget>[
                  Spacer(flex: 1),
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ConstructedBoundaryType.partialWall,
                        );
                      },
                      child: Text(
                        'Partial Wall',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Spacer(flex: 1),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  color: Color(0xFF7A8DA6),
                ),
              ),
              Row(
                children: [
                  Spacer(flex: 4),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Back',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Spacer(flex: 4),
                ],
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialDescriptionForm extends StatefulWidget {
  const _MaterialDescriptionForm();

  @override
  State<_MaterialDescriptionForm> createState() =>
      _MaterialDescriptionFormState();
}

class _MaterialDescriptionFormState extends State<_MaterialDescriptionForm> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            gradient: formGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Text(
                  'Boundary Description',
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F6DCF),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Center(
                  child: Text.rich(
                    textAlign: TextAlign.center,
                    softWrap: true,
                    TextSpan(
                      text: 'Choose the option that ',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'best',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        TextSpan(text: ' describes your boundary.'),
                      ],
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
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          MaterialBoundaryType.pavers,
                        );
                      },
                      child: Text(
                        'Pavers',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          MaterialBoundaryType.concrete,
                        );
                      },
                      child: Text(
                        'Concrete',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                spacing: 20,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          MaterialBoundaryType.tile,
                        );
                      },
                      child: Text(
                        'Tile',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          MaterialBoundaryType.natural,
                        );
                      },
                      child: Text(
                        'Natural',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                spacing: 20,
                children: <Widget>[
                  Spacer(flex: 1),
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          MaterialBoundaryType.decking,
                        );
                      },
                      child: Text(
                        'Decking',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Spacer(flex: 1),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  color: Color(0xFF7A8DA6),
                ),
              ),
              Row(
                children: [
                  Spacer(flex: 4),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Back',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Spacer(flex: 4),
                ],
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelterDescriptionForm extends StatefulWidget {
  const _ShelterDescriptionForm();

  @override
  State<_ShelterDescriptionForm> createState() =>
      _ShelterDescriptionFormState();
}

class _ShelterDescriptionFormState extends State<_ShelterDescriptionForm> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            gradient: formGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Text(
                  'Boundary Description',
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F6DCF),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Center(
                  child: Text.rich(
                    textAlign: TextAlign.center,
                    softWrap: true,
                    TextSpan(
                      text: 'Choose the option that ',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'best',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        TextSpan(text: ' describes your boundary.'),
                      ],
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
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ShelterBoundaryType.canopy,
                        );
                      },
                      child: Text(
                        'Canopy',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ShelterBoundaryType.tree,
                        );
                      },
                      child: Text(
                        'Trees',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                spacing: 20,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ShelterBoundaryType.furniture,
                        );
                      },
                      child: Text(
                        'Furniture',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ShelterBoundaryType.temporary,
                        );
                      },
                      child: Text(
                        'Temporary',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                spacing: 20,
                children: <Widget>[
                  Spacer(flex: 1),
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ShelterBoundaryType.constructed,
                        );
                      },
                      child: Text(
                        'Constructed',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Spacer(flex: 1),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  color: Color(0xFF7A8DA6),
                ),
              ),
              Row(
                children: [
                  Spacer(flex: 4),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Back',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Spacer(flex: 4),
                ],
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
