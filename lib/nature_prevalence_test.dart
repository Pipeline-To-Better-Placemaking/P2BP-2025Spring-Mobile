import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/project_details_page.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'db_schema_classes.dart';
import 'firestore_functions.dart';
import 'google_maps_functions.dart';
import 'home_screen.dart';

class NaturePrevalence extends StatefulWidget {
  final Project projectData;

  /// IMPORTANT: When navigating to this page, pass in project details. The
  /// project details page already contains project info, so you should use
  /// that data.
  const NaturePrevalence({super.key, required this.projectData});

  @override
  State<NaturePrevalence> createState() => _NaturePrevalenceState();
}

enum Vegetation { native, design, openField }

enum WaterBody { ocean, lake, river, swamp }

enum Animal { cat, dog, squirrel, bird, rabbit, turtle, duck }

class _NaturePrevalenceState extends State<NaturePrevalence> {
  bool _isLoading = true;
  bool _polygonMode = false;
  bool _pointMode = false;
  bool _outsidePoint = false;
  String? _type = 'cat';
  String _directions = "Choose a category.";
  double _bottomSheetHeight = 300;
  late DocumentReference teamRef;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation; // Default location
  //Map<String, Set<LatLng>> a;
  List<LatLng> _polygonPoints = []; // Points for the polygon
  List<mp.LatLng> _mapToolsPolygonPoints = [];
  Set<Polygon> _polygons = {}; // Set of polygons
  List<GeoPoint> _polygonAsGeoPoints =
      []; // The current polygon represented as points (for Firestore).
  Set<Marker> _markers = {}; // Set of markers for points
  Set<Marker> _polygonMarkers = {}; // Set of markers for polygon creation

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
      // Take some latitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      // TODO: dynamic zooming
      _isLoading = false;
    });
  }

  void showModalWaterBody(BuildContext context) {
    showModalBottomSheet<void>(
      sheetAnimationStyle:
          AnimationStyle(reverseDuration: Duration(milliseconds: 100)),
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const BarIndicator(),
                    Center(
                      child: Text(
                        'Select the Body of Water',
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
                        'Then mark the boundaries on the map.',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Body of Waster Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      spacing: 20,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _type = WaterBody.ocean.name;
                                _polygonMode = true;
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Ocean'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _type = WaterBody.lake.name;
                                _polygonMode = true;
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Lake'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _type = WaterBody.river.name;
                                _polygonMode = true;
                              });
                              Navigator.pop(context);
                            },
                            child: Text('River', textAlign: TextAlign.center),
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
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _type = WaterBody.swamp.name;
                                _polygonMode = true;
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Swamp'),
                          ),
                        ),
                        Flexible(
                          flex: 1,
                          child: SizedBox(),
                        ),
                        Flexible(
                          flex: 1,
                          child: SizedBox(),
                        ),
                      ],
                    ),
                    SizedBox(height: 25),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: InkWell(
                        child: const Padding(
                          padding: EdgeInsets.only(right: 20, bottom: 0),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFFD700)),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void showModalVegetation(BuildContext context) {
    showModalBottomSheet<void>(
      sheetAnimationStyle:
          AnimationStyle(reverseDuration: Duration(milliseconds: 100)),
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const BarIndicator(),
                    Center(
                      child: Text(
                        'Select the Type of the Vegetation',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: placeYellow,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Then mark the boundaries on the map.',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Vegetation Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      spacing: 20,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _type = Vegetation.native.name;
                                _polygonMode = true;
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Native'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _type = Vegetation.design.name;
                                _polygonMode = true;
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Design'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _type = Vegetation.openField.name;
                                _polygonMode = true;
                              });

                              Navigator.pop(context);
                            },
                            child:
                                Text('Open Field', textAlign: TextAlign.center),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 25),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: InkWell(
                        child: const Padding(
                          padding: EdgeInsets.only(right: 20, bottom: 0),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFFD700)),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void showModalAnimal(BuildContext context) {
    showModalBottomSheet<void>(
      sheetAnimationStyle:
          AnimationStyle(reverseDuration: Duration(milliseconds: 100)),
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const BarIndicator(),
                    Center(
                      child: Text(
                        'What Animal Do You See?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: placeYellow,
                        ),
                      ),
                    ),
                    Text(
                      'Domesticated',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      spacing: 20,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _type = 'cat';
                                _pointMode = true;
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Cat'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: Text('Dog'),
                            onPressed: () {
                              setState(() {
                                _type = 'dog';
                                _pointMode = true;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        Flexible(flex: 1, child: SizedBox()),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Wild',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      spacing: 20,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _type = 'squirrel';
                                _pointMode = true;
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Squirrel'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _type = 'bird';
                                _pointMode = true;
                              });

                              Navigator.pop(context);
                            },
                            child: Text('Bird'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _type = 'rabbit';
                                _pointMode = true;
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Rabbit'),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 20,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _type = 'turtle';
                                _pointMode = true;
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Turtle'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _type = 'duck';
                                _pointMode = true;
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Duck'),
                          ),
                        ),
                        Flexible(flex: 1, child: SizedBox())
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Other',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Flexible(
                          flex: 3,
                          child: TextField(
                            onChanged: (otherText) {
                              // TODO: use value
                            },
                            decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                labelText: 'Enter animal name'),
                          ),
                        ),
                        SizedBox(width: 10),
                        Flexible(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                            ),
                            child: Text('Submit other'),
                          ),
                        ),
                        Flexible(flex: 1, child: SizedBox())
                      ],
                    ),
                    SizedBox(height: 15),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: InkWell(
                        child: const Padding(
                          padding: EdgeInsets.only(right: 20, bottom: 0),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFFD700)),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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

  void _togglePoint(LatLng point) {
    try {
      // if (mp.PolygonUtil.containsLocation(mp.LatLng(point.latitude, point.longitude), _polygons.first.points, true))
      if (_pointMode) _pointTap(point);
      if (_polygonMode) _polygonTap(point);
    } catch (e, stacktrace) {
      print('Error in nature_prevalence_test.dart, _togglePoint(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  void _polygonTap(LatLng point) {
    if (_type != null) {
      final markerId = MarkerId('${_type}_marker_${point.toString()}');
      setState(() {
        _polygonPoints.add(point);
        _polygonMarkers.add(
          Marker(
            markerId: markerId,
            position: point,
            consumeTapEvents: true,
            icon: AssetMapBitmap('assets/${_type}_marker.png'),
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
      _type = 'cat';
      _pointMode = false;
    }
  }

  void _pointTap(LatLng point) {
    if (_type != null) {
      final markerId = MarkerId('${_type}_marker_${point.toString()}');
      setState(() {
        // TODO: create list of markers for test, add these to it (cat, dog, etc.)
        _markers.add(
          Marker(
            markerId: markerId,
            position: point,
            consumeTapEvents: true,
            icon: AssetMapBitmap('assets/${_type}_marker.png'),
            onTap: () {
              // If placing a point or polygon, don't remove point.
              if (_pointMode || _polygonMode) return;
              // If the marker is tapped again, it will be removed
              setState(() {
                _markers.removeWhere((marker) => marker.markerId == markerId);
                // TODO: create list of points for test
              });
            },
          ),
        );
      });
      _type = 'cat';
      _pointMode = false;
    }
  }

  void _finalizePolygon() {
    try {
      // Create polygon.
      _polygons = {..._polygons, ...finalizePolygon(_polygonPoints)};
      print(_polygons);

      // Cleans up current polygon representations.
      _polygonAsGeoPoints = [];
      _mapToolsPolygonPoints = [];

      // Creating points representations for Firestore storage and area calculation
      for (LatLng coordinate in _polygonPoints) {
        _polygonAsGeoPoints
            .add(GeoPoint(coordinate.latitude, coordinate.longitude));
        _mapToolsPolygonPoints
            .add(mp.LatLng(coordinate.latitude, coordinate.longitude));
      }

      // Clears polygon points and enter add points mode.
      _polygonPoints = [];

      // Clear markers from screen.
      setState(() {
        _polygonMarkers.clear();
        _polygonMode = false;
      });
    } catch (e, stacktrace) {
      print('Exception in _finalize_polygon(): $e');
      print('Stacktrace: $stacktrace');
    }
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
                        padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                        onMapCreated: _onMapCreated,
                        initialCameraPosition:
                            CameraPosition(target: _location, zoom: 14),
                        polygons: _polygons,
                        markers: {..._markers, ..._polygonMarkers},
                        onTap: _togglePoint,
                        mapType: _currentMapType, // Use current map type
                      ),
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
                        padding: EdgeInsets.only(
                            bottom: _bottomSheetHeight + 50, left: 5),
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
            : SizedBox(
                height: _bottomSheetHeight,
                child: Stack(
                  children: [
                    Container(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 5),
                          Center(
                            child: Text(
                              'Nature Prevalence',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: placeYellow,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Natural Boundaries',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 5),
                          Row(
                            spacing: 10,
                            children: [
                              Flexible(
                                child: buildTestButton(
                                    onPressed: (BuildContext context) {
                                      showModalWaterBody(context);
                                    },
                                    context: context,
                                    text: 'Body of Water',
                                    icon: Icon(Icons.water)),
                              ),
                              Flexible(
                                child: buildTestButton(
                                  text: 'Vegetation',
                                  icon: Icon(Icons.grass, color: Colors.black),
                                  context: context,
                                  onPressed: (BuildContext context) {
                                    showModalVegetation(context);
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Animals',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            spacing: 10,
                            children: [
                              Flexible(
                                child: buildTestButton(
                                  text: 'Animal',
                                  icon: Icon(Icons.pets, color: Colors.black),
                                  context: context,
                                  onPressed: (BuildContext context) {
                                    showModalAnimal(context);
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Expanded(
                            child: Row(
                              spacing: 10,
                              children: <Widget>[
                                Expanded(
                                  child: Row(
                                    spacing: 10,
                                    children: <Widget>[
                                      Flexible(
                                        child: EditButton(
                                          text: 'Confirm Shape',
                                          foregroundColor: Colors.green,
                                          backgroundColor: Colors.white,
                                          icon: const Icon(Icons.check),
                                          iconColor: Colors.green,
                                          onPressed: (_polygonMode)
                                              ? _finalizePolygon
                                              : null,
                                        ),
                                      ),
                                      Flexible(
                                        child: EditButton(
                                          text: 'Cancel',
                                          foregroundColor: Colors.red,
                                          backgroundColor: Colors.white,
                                          icon: const Icon(Icons.cancel),
                                          iconColor: Colors.red,
                                          onPressed:
                                              (_pointMode || _polygonMode)
                                                  ? () {
                                                      setState(() {
                                                        _pointMode = false;
                                                        _polygonMode = false;
                                                        _polygonMarkers = {};
                                                      });
                                                      _polygonPoints = [];
                                                    }
                                                  : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  flex: 0,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: EditButton(
                                      text: 'Finish',
                                      foregroundColor: Colors.black,
                                      backgroundColor: Colors.white,
                                      icon: const Icon(Icons.chevron_right,
                                          color: Colors.black),
                                      onPressed: () async {
                                        // todo: await saveTest()
                                        // saveTest()
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  HomeScreen(),
                                            ));
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CreateProjectDetails(
                                                      projectData:
                                                          widget.projectData),
                                            ));
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
                    _outsidePoint
                        ? Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 30.0, horizontal: 100.0),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red[900],
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10)),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
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
                ),
              ),
      ),
    );
  }

  FilledButton buildTestButton(
      {required BuildContext context,
      required String text,
      required Function(BuildContext) onPressed,
      required Icon icon}) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.only(left: 15, right: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        iconColor: Colors.black,
        disabledBackgroundColor: disabledGrey,
      ),
      onPressed: (_pointMode || _polygonMode) ? null : () => onPressed(context),
      label: Text(text),
      icon: icon,
      iconAlignment: IconAlignment.end,
    );
  }
}
