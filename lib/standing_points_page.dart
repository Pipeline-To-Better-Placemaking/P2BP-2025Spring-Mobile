import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'google_maps_functions.dart';
import 'db_schema_classes.dart';
import 'firestore_functions.dart';

/// Build the header for the bottom sheet, including a draggable handle.
class _BottomSheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  _BottomSheetHeaderDelegate({required this.height});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFDDE6F2),
        border: Border.all(color: bottomSheetBlue.shade900, width: 2.0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      child: Column(
        children: [
          // Pill-shaped drag handle.
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Center(
              child: Container(
                width: 40.0,
                height: 5.0,
                decoration: BoxDecoration(
                  color: bottomSheetBlue.shade700,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          // Header text.
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: Text(
              "Standing Points",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class StandingPointsPage extends StatefulWidget {
  final Project activeProject;
  final List? currentStandingPoints;
  const StandingPointsPage(
      {super.key, required this.activeProject, this.currentStandingPoints});

  @override
  State<StandingPointsPage> createState() => _StandingPointsPageState();
}

final User? loggedInUser = FirebaseAuth.instance.currentUser;

/// Icon for when the standing point isn't selected
final AssetMapBitmap disabledIcon = AssetMapBitmap(
  'assets/standing_point_disabled.png',
  width: 48,
  height: 48,
);

/// Icon for when the standing point has been selected
final AssetMapBitmap enabledIcon = AssetMapBitmap(
  'assets/standing_point_enabled.png',
  width: 48,
  height: 48,
);

class _StandingPointsPageState extends State<StandingPointsPage> {
  DocumentReference? teamRef;
  GoogleMapController? mapController;
  LatLng _location = defaultLocation; // Default location
  bool _isLoading = true;
  final String _directions =
      "Tap a marker to choose standing points for your activity.";
  Set<Polygon> _polygons = {}; // Set of polygons
  Set<Marker> _markers = {}; // Set of markers for points
  List _standingPoints = [];
  Marker? _currentMarker;
  double _bottomSheetHeight = 300;

  MapType _currentMapType = MapType.normal; // Default map type
  final List<bool> _checkboxValues = [];
  bool _isStandingPointSelected = false;
  Project? project;
  double _sheetExtent = 0.28;
  static const double bottomOffset = 120.0;
  final GlobalKey _textContainerKey = GlobalKey();
  double containerHeight = 0.0;

  @override
  void initState() {
    super.initState();
    initProjectArea();
    // Measure the text container after the first frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? box =
          _textContainerKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        setState(() {
          containerHeight = box.size.height;
        });
      }
    });
  }

  /// Initialize the project area: create the polygon boundary, center the map, set markers for each
  /// standing point, and load any pre-existing standing point data.
  void initProjectArea() async {
    setState(() {
      _polygons = getProjectPolygon(widget.activeProject.polygonPoints);
      _location = getPolygonCentroid(_polygons.first);
      // Adjust the location slightly.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      // TODO: dynamic zooming
      _markers = _setMarkersFromPoints(widget.activeProject.standingPoints);
      _standingPoints = widget.activeProject.standingPoints;
      // If there are any current standing points, load them.
      if (widget.currentStandingPoints != null) {
        final List? currentStandingPoints = widget.currentStandingPoints;
        _loadCurrentStandingPoints(currentStandingPoints);
      }
      _isLoading = false;
    });
  }

  /// Takes a list of points and creates the default markers from their title
  /// and position.
  Set<Marker> _setMarkersFromPoints(List points) {
    Set<Marker> markers = {};
    // Create markers for each standing point with onTap callbacks to toggle selection.
    for (Map point in points) {
      final markerId = MarkerId(point.toString());
      _checkboxValues.add(false);
      markers.add(
        Marker(
            markerId: markerId,
            position: (point['point'] as GeoPoint).toLatLng(),
            icon: disabledIcon,
            infoWindow: InfoWindow(
              title: point['title'],
              snippet:
                  '${point['point'].latitude.toStringAsFixed(5)}, ${point['point'].latitude.toStringAsFixed(5)}',
            ),
            onTap: () {
              final Marker thisMarker =
                  _markers.singleWhere((marker) => marker.markerId == markerId);
              final int listIndex = _standingPoints.indexWhere((namePointMap) =>
                  namePointMap['point'] == thisMarker.position.toGeoPoint());
              _currentMarker = thisMarker;
              // Toggle marker selection on tap: update _currentMarker, toggle the corresponding
              // checkbox value, and call _toggleMarker()
              if (!_isStandingPointSelected) {
                setState(() {
                  _isStandingPointSelected = true;
                });
              }
              _checkboxValues[listIndex] = !_checkboxValues[listIndex];
              _toggleMarker();
            }),
      );
    }
    return markers;
  }

  /// Toggles the [_currentMarker] on or off.
  /// Toggles between enabled and disabled icons.
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

  /// Load any pre-existing standing point data.
  void _loadCurrentStandingPoints(List? currentStandingPoints) {
    if (currentStandingPoints == null) return;
    for (Map point in currentStandingPoints) {
      final Marker thisMarker = _markers.singleWhere(
          (marker) => point['point'] == marker.position.toGeoPoint());
      final int listIndex = _standingPoints.indexWhere((namePointMap) =>
          namePointMap['point'] == thisMarker.position.toGeoPoint());
      _currentMarker = thisMarker;
      _checkboxValues[listIndex] = false;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Map created: assign the controller and center the map on the current location.
    _moveToLocation();
  }

  /// Animate the map camera to focus on the current _location.
  void _moveToLocation() {
    if (mapController == null) return;
    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: 14.0),
      ),
    );
  }

  /// Toggle the map view between normal and satellite modes.
  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
  }

  /// Build the main Scaffold for the Standing Points Page including:
  /// - The Google Map display with polygons and markers.
  /// - A toggle button for switching map types.
  /// - An instructions overlay for user guidance.
  /// - A draggable bottom sheet for selecting standing points.
  /// - A confirm button section to finalize selecions.
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    // Calculate available height for the draggable sheet.
    final double availableHeight = screenHeight - bottomOffset;
    // Current height of the bottom sheet.
    double currentSheetHeight = _sheetExtent * availableHeight;
    // Fixed gap for the map toggle button above the bottom sheet
    double toggleButtonBottom;

    if (!_isStandingPointSelected && containerHeight > 0) {
      // Calculate the top of the text container.
      double textContainerTop = screenHeight - (50.0 + containerHeight);
      // Position the toggle button 10 pixels above the text container's top.
      toggleButtonBottom = screenHeight - textContainerTop + 20.0;
    } else {
      toggleButtonBottom = bottomOffset + currentSheetHeight + 10.0;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 88.0,
        systemOverlayStyle:
            SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: UnconstrainedBox(
              child: SizedBox(
                  width: 48,
                  height: 48,
                  child: _currentMapType == MapType.normal
                      ? IconButton(
                          style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.9),
                              shape: CircleBorder(),
                              padding: EdgeInsets.zero,
                              minimumSize: Size(48, 48)),
                          iconSize: 24.0,
                          icon: Icon(Icons.close, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        )
                      : IconButton(
                          style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.7),
                              shape: CircleBorder(),
                              padding: EdgeInsets.zero,
                              minimumSize: Size(48, 48)),
                          iconSize: 24.0,
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        )),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Stack(
                    children: [
                      GoogleMap(
                        padding: EdgeInsets.only(bottom: bottomOffset),
                        onMapCreated: _onMapCreated,
                        initialCameraPosition:
                            CameraPosition(target: _location, zoom: 14.0),
                        myLocationButtonEnabled: false,
                        polygons: _polygons,
                        markers: _markers,
                        mapType: _currentMapType, // Use current map type
                      ),
                      // Overlaid button for toggling map type.
                      Positioned(
                        right: 20.0,
                        bottom: toggleButtonBottom,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                const Color(0xFF7EAD80).withValues(alpha: 0.9),
                            border:
                                Border.all(color: Color(0xFF2D6040), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6.0,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Center(
                              child:
                                  Icon(Icons.layers, color: Color(0xFF2D6040)),
                            ),
                            onPressed: _toggleMapType,
                          ),
                        ),
                      ),
                      if (_isStandingPointSelected)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: bottomOffset,
                          child: SizedBox(
                            height: availableHeight,
                            child: NotificationListener<
                                DraggableScrollableNotification>(
                              onNotification: (notification) {
                                setState(() {
                                  _sheetExtent = notification.extent;
                                });
                                return true;
                              },
                              child: DraggableScrollableSheet(
                                initialChildSize: 0.28,
                                minChildSize: 0.2,
                                maxChildSize: 0.5,
                                builder: (context, scrollController) {
                                  return _buildBottomSheetContent(
                                      scrollController);
                                },
                              ),
                            ),
                          ),
                        ),

                      if (!_isStandingPointSelected)
                        Positioned(
                          bottom: 50.0,
                          left: 20.0,
                          right: 20.0,
                          child: Container(
                            key: _textContainerKey,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.8),
                                  Colors.black.withValues(alpha: 0.5),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                              border:
                                  Border.all(color: Colors.white70, width: 1.5),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 20.0),
                            child: Text(
                              _directions,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                                height: 1.4,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 4.0,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
      bottomSheet:
          _isStandingPointSelected ? _buildConfirmButtonSection() : null,
    );
  }

  /// Build an enhanced, custom scrollable bottom sheet with a pinned header and a list of selected
  /// standing points.
  Widget _buildBottomSheetContent(ScrollController scrollController) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      child: Container(
        color: Color(0xFFDDE6F2),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            // Pinned header
            SliverPersistentHeader(
              pinned: true,
              delegate: _BottomSheetHeaderDelegate(height: 80),
            ),

            // Expanded scrollable list of standing points.
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (!_checkboxValues[index]) return SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 5.0),
                    child: ListTile(
                      title: Text(
                        "${_standingPoints[index]['title']}",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${_standingPoints[index]['point'].latitude.toStringAsFixed(5)}, ${_standingPoints[index]['point'].longitude.toStringAsFixed(5)}",
                      ),
                      trailing: IconButton(
                        icon: Icon(
                            _checkboxValues[index]
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: _checkboxValues[index]
                                ? Colors.teal
                                : Colors.grey),
                        onPressed: _isLoading
                            ? null
                            : () {
                                try {
                                  if (_checkboxValues.length !=
                                      _standingPoints.length) {
                                    throw Exception("Data mismatch!");
                                  }
                                  setState(() {
                                    // For each standing point, if it's selected, update the marker icon.
                                    for (int i = 0;
                                        i < _standingPoints.length;
                                        i++) {
                                      if (_checkboxValues[i]) {
                                        // Find the marker corresponding to this standing point.
                                        final Marker marker =
                                            _markers.firstWhere((m) =>
                                                m.position ==
                                                (_standingPoints[i]['point']
                                                        as GeoPoint)
                                                    .toLatLng());
                                        // Remove the old marker and add a new one with enabledIcon.
                                        _markers.remove(marker);
                                        _markers.add(marker.copyWith(
                                            iconParam: enabledIcon));
                                      }
                                    }
                                  });

                                  List enabledPoints = [];
                                  for (int i = 0;
                                      i < _standingPoints.length;
                                      i++) {
                                    if (_checkboxValues[i]) {
                                      enabledPoints.add(_standingPoints[i]);
                                    }
                                  }
                                } catch (e, stacktrace) {
                                  print("Error confirming standing points: $e");
                                  print("Stacktrace: $stacktrace");
                                }
                              },
                      ),
                    ),
                  );
                },
                childCount: _markers.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the fixed bottom section that contains the Confirm button for finalizing standing
  /// points selections.
  Widget _buildConfirmButtonSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 30.0),
      decoration: BoxDecoration(
        color: Color(0xFFDDE6F2),
        border: Border(
          top: BorderSide(color: Colors.grey, width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 60, // Increased height for proportional look.
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal, // This can be conditional if needed.
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
          onPressed: _isLoading
              ? null
              : () {
                  // Confirm action: gather selected standing points and navigate out of the screen
                  try {
                    if (_checkboxValues.length != _standingPoints.length) {
                      throw Exception("Data mismatch!");
                    }
                    List enabledPoints = [];
                    for (int i = 0; i < _standingPoints.length; i++) {
                      if (_checkboxValues[i]) {
                        enabledPoints.add(_standingPoints[i]);
                      }
                    }
                    Navigator.pop(context, enabledPoints);
                  } catch (e, stacktrace) {
                    print("Error confirming standing points: $e");
                    print("Stacktrace: $stacktrace");
                  }
                },
          child: Text(
            'Confirm',
            style: TextStyle(
                fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
