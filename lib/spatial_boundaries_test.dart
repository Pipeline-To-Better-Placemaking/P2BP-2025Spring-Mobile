import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'theme.dart';
import 'db_schema_classes.dart';
import 'google_maps_functions.dart';
import 'widgets.dart';

class SpatialBoundariesTestPage extends StatefulWidget {
  final Project activeProject;
  // final Test activeTest;

  const SpatialBoundariesTestPage({
    super.key,
    required this.activeProject,
    // required this.activeTest,
  });

  @override
  State<SpatialBoundariesTestPage> createState() =>
      _SpatialBoundariesTestPageState();
}

class _SpatialBoundariesTestPageState extends State<SpatialBoundariesTestPage> {
  bool _isLoading = true;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  MapType _currentMapType = MapType.satellite; // Default map type
  final Set<Marker> _markers = {}; // Set of markers visible on map
  Set<Polygon> _polygons = {}; // Set of polygons

  String _directions = 'Select a type of boundary.';
  static const double _bottomSheetHeight = 250;

  @override
  void initState() {
    super.initState();
    _initProjectArea();
  }

  /// Gets the project polygon, adds it to the current polygon list, and
  /// centers the map over it.
  void _initProjectArea() {
    setState(() {
      _polygons = getProjectPolygon(widget.activeProject.polygonPoints);
      print(_polygons);
      _location = getPolygonCentroid(_polygons.first);
      // Take some latitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
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

  void _doConstructedModal(BuildContext context) async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => _ConstructedDescriptionForm(),
    );
  }

  void _doMaterialModal(BuildContext context) async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => _MaterialDescriptionForm(),
    );
  }

  void _doShelterModal(BuildContext context) async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => _ShelterDescriptionForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Stack(
                  children: <Widget>[
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: GoogleMap(
                        padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                        onMapCreated: _onMapCreated,
                        initialCameraPosition:
                            CameraPosition(target: _location, zoom: 15),
                        markers: _markers,
                        polygons: _polygons,
                        onTap: null,
                        mapType: _currentMapType,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                          bottom: _bottomSheetHeight + 30,
                        ),
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
                height: _bottomSheetHeight,
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
                  children: <Widget>[
                    Center(
                      child: Text(
                        'Spatial Boundaries',
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
                        _directions,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
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
                            onPressed: () {
                              _doConstructedModal(context);
                            },
                            child: Text('Constructed'),
                          ),
                        ),
                        Expanded(
                          flex: 8,
                          child: FilledButton(
                            style: testButtonStyle,
                            onPressed: () {
                              _doMaterialModal(context);
                            },
                            child: Text('Material'),
                          ),
                        ),
                        Expanded(
                          flex: 7,
                          child: FilledButton(
                            style: testButtonStyle,
                            onPressed: () {
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
                      spacing: 10,
                      children: <Widget>[
                        Expanded(
                          flex: 7,
                          child: EditButton(
                            text: 'Confirm Shape',
                            foregroundColor: Colors.green,
                            backgroundColor: Colors.white,
                            icon: const Icon(Icons.check),
                            iconColor: Colors.green,
                            onPressed: () {},
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: EditButton(
                            text: 'Cancel',
                            foregroundColor: Colors.red,
                            backgroundColor: Colors.white,
                            icon: const Icon(Icons.cancel),
                            iconColor: Colors.red,
                            onPressed: () {},
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: FilledButton.icon(
                            style: testButtonStyle,
                            onPressed: () {
                              // TODO: check isComplete either before submitting or probably before starting test
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
      ),
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
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          decoration: BoxDecoration(
            gradient: defaultGrad,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                const BarIndicator(),
                Center(
                  child: Text(
                    'Boundary Description',
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: placeYellow,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Center(
                    child: Text(
                      'Select the best description for the boundary you marked.',
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[400],
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
                        onPressed: () {},
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
                        onPressed: () {},
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
                        onPressed: () {},
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
                        onPressed: () {},
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
                        onPressed: () {},
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
                  child: Divider(),
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
          decoration: BoxDecoration(
            gradient: defaultGrad,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                const BarIndicator(),
                Center(
                  child: Text(
                    'Boundary Description',
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: placeYellow,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Center(
                    child: Text(
                      'Select the best description for the boundary you marked.',
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[400],
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
                        onPressed: () {},
                        child: Text(
                          'Bricks (pavers)',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextButton(
                        style: testButtonStyle,
                        onPressed: () {},
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
                        onPressed: () {},
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
                        onPressed: () {},
                        child: Text(
                          'Natural (grass)',
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
                        onPressed: () {},
                        child: Text(
                          'Wood (deck)',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Spacer(flex: 1),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
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
          decoration: BoxDecoration(
            gradient: defaultGrad,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                const BarIndicator(),
                Center(
                  child: Text(
                    'Boundary Description',
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: placeYellow,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Center(
                    child: Text(
                      'Select the best description for the boundary you marked.',
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[400],
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
                        onPressed: () {},
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
                        onPressed: () {},
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
                        onPressed: () {},
                        child: Text(
                          'Umbrella Dining',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextButton(
                        style: testButtonStyle,
                        onPressed: () {},
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
                        onPressed: () {},
                        child: Text(
                          'Constructed Ceiling',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Spacer(flex: 1),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
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
      ),
    );
  }
}
