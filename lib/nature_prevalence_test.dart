import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/firestore_functions.dart';
import 'package:p2bp_2025spring_mobile/project_details_page.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';
import 'db_schema_classes.dart';
import 'google_maps_functions.dart';
import 'home_screen.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

class NaturePrevalence extends StatefulWidget {
  final Project activeProject;
  final NaturePrevalenceTest activeTest;

  /// IMPORTANT: When navigating to this page, pass in project details. The
  /// project details page already contains project info, so you should use
  /// that data.
  const NaturePrevalence(
      {super.key, required this.activeProject, required this.activeTest});

  @override
  State<NaturePrevalence> createState() => _NaturePrevalenceState();
}

class _NaturePrevalenceState extends State<NaturePrevalence> {
  bool _isLoading = true;
  bool _polygonMode = false;
  bool _pointMode = false;
  bool _outsidePoint = false;
  bool _deleteMode = false;
  String _errorText = '';
  Set<Polygon> _projectPolygon = {};
  List<mp.LatLng> _projectArea = [];
  String _directions = "Choose a category.";
  bool _directionsVisible = false;
  double _bottomSheetHeight = 300;
  late DocumentReference teamRef;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation; // Default location
  List<LatLng> _polygonPoints = []; // Points for the polygon
  Set<Polygon> _polygons = {}; // Set of polygons
  final Set<Marker> _markers = {}; // Set of markers for points
  Set<Marker> _polygonMarkers = {}; // Set of markers for polygon creation
  MapType _currentMapType = MapType.satellite; // Default map type
  bool _oldVisibility = true;

  Timer? _timer;
  int _remainingSeconds = -1;
  bool _testIsRunning = false;

  final NatureData _natureData = NatureData();

  final List<Animal> _animalData = [];
  final List<Vegetation> _vegetationData = [];
  final List<WaterBody> _waterBodyData = [];
  WeatherData? _weatherData;

  AnimalType? _animalType;
  VegetationType? _vegetationType;
  WaterBodyType? _waterBodyType;
  Map<NatureType, Type> natureToSpecific = {
    NatureType.animal: AnimalType,
    NatureType.vegetation: VegetationType,
    NatureType.waterBody: WaterBodyType,
  };
  NatureType? _natureType;
  String? _otherType;

  @override
  void initState() {
    super.initState();
    initProjectArea();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _setWeatherData();
    });
  }

  void _startTest() {
    setState(() {
      _testIsRunning = true;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds <= 0) {
          _endTest();
          timer.cancel();
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  scrollable: true,
                  title: Center(
                      child: Text(
                    "Time's Up!",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
                  content: Center(
                      child: Text(
                    "Would you like to submit your data?",
                    style: TextStyle(fontSize: 15),
                  )),
                  actions: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _remainingSeconds = 10;
                              });
                              Navigator.pop(context);
                            },
                            child: Text("No, take me back."),
                          ),
                        ),
                        Flexible(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: Text("Yes, submit."),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              });
        } else {
          _remainingSeconds--;
        }
      });
    });
  }

  void _endTest() {
    setState(() {
      _testIsRunning = false;
    });
    _timer?.cancel();
  }

  /// Sets all type variables to null.
  ///
  /// Called after finishing data placement.
  void _clearTypes() {
    _natureType = null;
    _animalType = null;
    _vegetationType = null;
    _waterBodyType = null;
    _otherType = null;
    _directions = 'Choose a category. Or, click finish to submit.';
  }

  String? _getCurrentTypeName() {
    switch (_natureType) {
      case null:
        throw Exception("Type not chosen! "
            "_natureType is null and _getCurrentType() has been invoked.");
      case NatureType.vegetation:
        return _vegetationType?.name;
      case NatureType.waterBody:
        return _waterBodyType?.name;
      case NatureType.animal:
        return _animalType?.name;
    }
  }

  /// Gets the project polygon, adds it to the current polygon list, and
  /// centers the map over it.
  void initProjectArea() {
    setState(() {
      _projectPolygon = getProjectPolygon(widget.activeProject.polygonPoints);
      _location = getPolygonCentroid(_projectPolygon.first);
      // Take some latitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      _projectArea = _projectPolygon.first.toMPLatLngList();
      _remainingSeconds = widget.activeTest.testDuration;
      // TODO: dynamic zooming
      _isLoading = false;
    });
  }

  void _setWeatherData() async {
    WeatherData? weatherData;
    double? temperature;
    bool erroredTemp = false;
    bool erroredSelect = false;
    Map<Weather, bool> selectedMap = {
      Weather.stormy: false,
      Weather.sunny: false,
      Weather.rainy: false,
      Weather.windy: false,
      Weather.cloudy: false,
    };
    try {
      weatherData = await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return StatefulBuilder(builder: (context, StateSetter setState) {
              return AlertDialog(
                scrollable: true,
                title: Column(
                  children: [
                    Text(
                      'Weather',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  spacing: 5,
                  children: [
                    Text(
                      'Temperature',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 10,
                      children: [
                        Flexible(
                          child: DialogTextBox(
                            textAlign: TextAlign.center,
                            inputFormatter: [
                              FilteringTextInputFormatter.allow(
                                  RegExp('[1234567890.-]'))
                            ],
                            keyboardType: TextInputType.numberWithOptions(
                                signed: true, decimal: true),
                            maxLength: 6,
                            labelText: 'Temp.',
                            onChanged: (inputText) {
                              setState(() {
                                erroredTemp = false;
                              });
                              temperature = double.tryParse(inputText);
                            },
                          ),
                        ),
                        Flexible(
                            child: Text(
                          '°F',
                          style: TextStyle(fontSize: 14),
                        ))
                      ],
                    ),
                    erroredTemp
                        ? Text(
                            "Please input a value!",
                            style: TextStyle(color: Colors.red[900]),
                          )
                        : SizedBox(),
                    SizedBox(height: 30),
                    SizedBox(width: MediaQuery.of(context).size.width),
                    Center(
                      child: Text(
                        "Type",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Row(
                      spacing: 5,
                      children: <Widget>[
                        TestButton(
                          buttonText: "Sunny",
                          backgroundColor: selectedMap[Weather.sunny] == true
                              ? Colors.blue
                              : null,
                          onPressed: () {
                            setState(() {
                              erroredSelect = false;
                              selectedMap[Weather.sunny] =
                                  !selectedMap[Weather.sunny]!;
                            });
                          },
                        ),
                        TestButton(
                          buttonText: "Rainy",
                          backgroundColor: selectedMap[Weather.rainy] == true
                              ? Colors.blue
                              : null,
                          onPressed: () {
                            setState(() {
                              erroredSelect = false;
                              selectedMap[Weather.rainy] =
                                  !selectedMap[Weather.rainy]!;
                            });
                          },
                        )
                      ],
                    ),
                    Row(
                      spacing: 5,
                      children: <Widget>[
                        TestButton(
                          buttonText: "Windy",
                          backgroundColor: selectedMap[Weather.windy] == true
                              ? Colors.blue
                              : null,
                          onPressed: () {
                            setState(() {
                              erroredSelect = false;
                              selectedMap[Weather.windy] =
                                  !selectedMap[Weather.windy]!;
                            });
                          },
                        ),
                        TestButton(
                          buttonText: "Stormy",
                          backgroundColor: selectedMap[Weather.stormy] == true
                              ? Colors.blue
                              : null,
                          onPressed: () {
                            setState(() {
                              erroredSelect = false;
                              selectedMap[Weather.stormy] =
                                  !selectedMap[Weather.stormy]!;
                            });
                          },
                        )
                      ],
                    ),
                    Row(
                      spacing: 5,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Spacer(),
                        TestButton(
                          flex: 2,
                          buttonText: "Cloudy",
                          backgroundColor: selectedMap[Weather.cloudy] == true
                              ? Colors.blue
                              : null,
                          onPressed: () {
                            setState(() {
                              erroredSelect = false;
                              selectedMap[Weather.cloudy] =
                                  !selectedMap[Weather.cloudy]!;
                            });
                          },
                        ),
                        Spacer(),
                      ],
                    ),
                    erroredSelect
                        ? Text(
                            "Please select a type!",
                            style: TextStyle(color: Colors.red[900]),
                          )
                        : SizedBox(),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, null);
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      List<Weather> selectedWeather = [];
                      for (Weather weatherType in selectedMap.keys) {
                        if (selectedMap[weatherType] != null &&
                            selectedMap[weatherType] == true) {
                          selectedWeather.add(weatherType);
                        }
                      }
                      if (temperature == null) {
                        setState(() {
                          erroredTemp = true;
                        });
                      }
                      print(erroredSelect);
                      if (selectedWeather.isEmpty) {
                        print("\n");
                        setState(() {
                          erroredSelect = true;
                        });
                      }
                      if (erroredSelect || erroredTemp) {
                        return;
                      }
                      weatherData = WeatherData(
                          weatherTypes: selectedWeather, temp: temperature!);
                      Navigator.pop(context, weatherData);
                      print('${weatherData!.weatherTypes} temp: $temperature');
                    },
                    child: const Text('Next'),
                  ),
                ],
              );
            });
          });
      if (weatherData == null && mounted) {
        Navigator.pop(context);
      } else {
        _weatherData = weatherData;
      }
    } catch (e, stacktrace) {
      print('Error in nature_prevalence_test.dart, _setWeatherData(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  void _chooseWaterBodyType(WaterBodyType waterBodyType) {
    setState(() {
      _natureType = NatureType.waterBody;
      _waterBodyType = waterBodyType;
      _polygonMode = true;
      _directions =
          'Place points to create an outline, then click confirm shape to build the polygon.';
    });
  }

  void showModalWaterBody(BuildContext context) {
    _showTestModalGeneric(
      context,
      title: 'Select the Body of Water',
      subtitle: 'Then mark the boundary on the map.',
      contentList: <Widget>[
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
            TestButton(
              buttonText: 'Ocean',
              onPressed: () {
                _chooseWaterBodyType(WaterBodyType.ocean);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'Lake',
              onPressed: () {
                _chooseWaterBodyType(WaterBodyType.lake);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'River',
              onPressed: () {
                _chooseWaterBodyType(WaterBodyType.river);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        SizedBox(height: 5),
        Row(
          spacing: 20,
          children: <Widget>[
            TestButton(
              buttonText: 'Swamp',
              onPressed: () {
                _chooseWaterBodyType(WaterBodyType.swamp);
                Navigator.pop(context);
              },
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
      ],
    );
  }

  void _chooseVegetationType(VegetationType vegetationType) {
    setState(() {
      _natureType = NatureType.vegetation;
      _vegetationType = vegetationType;
      _polygonMode = true;
      _directions =
          'Place points to create an outline, then click confirm shape to build the polygon.';
    });
  }

  void showModalVegetation(BuildContext context) {
    _showTestModalGeneric(
      context,
      title: 'Vegetation Type',
      subtitle: 'Then mark the boundaries on the map',
      contentList: <Widget>[
        Text(
          'Vegetation Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Row(
          spacing: 20,
          children: <Widget>[
            TestButton(
              buttonText: 'Native',
              onPressed: () {
                _chooseVegetationType(VegetationType.native);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'Design',
              onPressed: () {
                _chooseVegetationType(VegetationType.design);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'Open Field',
              onPressed: () {
                _chooseVegetationType(VegetationType.openField);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _chooseAnimalType(AnimalType animalType) {
    setState(() {
      _natureType = NatureType.animal;
      _animalType = animalType;
      _pointMode = true;
      _directions = 'Place a point where you see the ${animalType.name}.';
    });
  }

  void _showTestModalGeneric(BuildContext context,
      {required String title,
      required String? subtitle,
      required List<Widget> contentList}) {
    showTestModalGeneric(context, onCancel: () {
      setState(() {
        _clearTypes();
      });
      Navigator.pop(context);
    }, title: title, subtitle: subtitle, contentList: contentList);
  }

  void showModalAnimal(BuildContext context) {
    _showTestModalGeneric(
      context,
      title: 'What animal do you see?',
      subtitle: null,
      contentList: <Widget>[
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
            TestButton(
              buttonText: 'Cat',
              onPressed: () {
                _chooseAnimalType(AnimalType.cat);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'Dog',
              onPressed: () {
                _chooseAnimalType(AnimalType.dog);
                Navigator.pop(context);
              },
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
            TestButton(
              buttonText: 'Squirrel',
              onPressed: () {
                _chooseAnimalType(AnimalType.squirrel);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'Bird',
              onPressed: () {
                _chooseAnimalType(AnimalType.bird);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'Rabbit',
              onPressed: () {
                _chooseAnimalType(AnimalType.rabbit);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        Row(
          spacing: 20,
          children: <Widget>[
            TestButton(
              buttonText: 'Turtle',
              onPressed: () {
                _chooseAnimalType(AnimalType.turtle);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'Duck',
              onPressed: () {
                _chooseAnimalType(AnimalType.duck);
                Navigator.pop(context);
              },
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
                  _otherType = otherText;
                },
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    labelText: 'Enter animal name'),
              ),
            ),
            SizedBox(width: 10),
            Flexible(
              flex: 2,
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    _natureType = NatureType.animal;
                    _animalType = AnimalType.other;
                    _pointMode = true;
                    _directions = 'Place a point where you see the animal.';
                  });
                  Navigator.pop(context);
                },
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
      ],
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

  Future<void> _togglePoint(LatLng point) async {
    try {
      if (!mp.PolygonUtil.containsLocation(
          mp.LatLng(point.latitude, point.longitude), _projectArea, true)) {
        setState(() {
          _outsidePoint = true;
        });
      }
      if (_pointMode) _pointTap(point);
      if (_polygonMode) _polygonTap(point);
      if (_outsidePoint) {
        // TODO: fix delay. delay will overlap with consecutive taps. this means taps do not necessarily refresh the timer and will end prematurely
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _outsidePoint = false;
        });
      }
    } catch (e, stacktrace) {
      print('Error in nature_prevalence_test.dart, _togglePoint(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  void _polygonTap(LatLng point) {
    String? type = _getCurrentTypeName();
    if (type == null) return;
    final markerId = MarkerId('${type}_marker_${point.toString()}');
    setState(() {
      _polygonPoints.add(point);
      _polygonMarkers.add(
        Marker(
          markerId: markerId,
          position: point,
          consumeTapEvents: _deleteMode,
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

  void _pointTap(LatLng point) {
    String? type = _getCurrentTypeName();
    if (type != null) {
      final markerId = MarkerId('${type}_marker_${point.toString()}');
      setState(() {
        _markers.add(
          Marker(
            markerId: markerId,
            position: point,
            consumeTapEvents: _deleteMode,
            infoWindow: InfoWindow(
                title:
                    _otherType ?? (type[0].toUpperCase() + type.substring(1)),
                snippet:
                    "(${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)})"),
            icon: AssetMapBitmap(
              'assets/test_markers/${type}_marker.png',
              width: 25,
              height: 25,
            ),
            onTap: () {
              if (_pointMode || _polygonMode) return;
              // If the marker is tapped again, it will be removed
              if (_deleteMode) {
                _animalData.removeWhere((animal) => animal.point == point);
                setState(() {
                  _markers.removeWhere((marker) => marker.markerId == markerId);
                  _deleteMode = false;
                });
              }
            },
          ),
        );
        _directions = 'Choose a category. Or, click finish to submit.';
      });
      _animalData.add(Animal(
          animalType: _animalType!, point: point, otherType: _otherType));
      _pointMode = false;
      _clearTypes();
    }
  }

  void _finalizePolygon() {
    Set<Polygon> tempPolygon;
    try {
      if (_natureType == NatureType.vegetation) {
        tempPolygon = finalizePolygon(
          _polygonPoints,
          polygonColor: Vegetation.vegetationTypeToColor[_vegetationType],
        );
        // Create polygon.
        _polygons = {..._polygons, ...tempPolygon};
        _vegetationData.add(Vegetation(
            vegetationType: _vegetationType!,
            polygon: tempPolygon.first,
            otherType: _otherType));
      } else if (_natureType == NatureType.waterBody) {
        tempPolygon = finalizePolygon(_polygonPoints,
            polygonColor: WaterBody.waterBodyTypeToColor[_waterBodyType]);
        // Create polygon.
        _polygons = {..._polygons, ...tempPolygon};
        _waterBodyData.add(WaterBody(
            waterBodyType: _waterBodyType!, polygon: tempPolygon.first));
      } else {
        throw Exception("Invalid nature type in _finalizePolygon(), "
            "_natureType = $_natureType");
      }
      // Clears polygon points and enter add points mode.
      _polygonPoints = [];

      // Clear markers from screen.
      setState(() {
        _polygonMarkers.clear();
        _polygonMode = false;
        _clearTypes();
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: null,
          automaticallyImplyLeading: false,
          systemOverlayStyle:
              SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
          backgroundColor: Colors.transparent,
          // Timer on the right
          actionsPadding: EdgeInsets.only(top: 15),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8), // Rounded rectangle shape.
                ),
                backgroundColor: _testIsRunning ? Colors.red : Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                if (_testIsRunning) {
                  _endTest();
                } else {
                  _startTest();
                }
              },
              child: Text(
                _testIsRunning ? 'End' : 'Start',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 20),
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
        ),
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
                        polygons: (_oldVisibility || _polygons.isEmpty)
                            ? {..._polygons, ..._projectPolygon}
                            : {_polygons.last, ..._projectPolygon},
                        markers: (_oldVisibility || _markers.isEmpty)
                            ? {..._markers, ..._polygonMarkers}
                            : {_markers.last, ..._polygonMarkers},
                        onTap:
                            (_pointMode || _polygonMode) ? _togglePoint : null,
                        mapType: _currentMapType, // Use current map type
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: kToolbarHeight + 20, right: 20.0),
                      child: Column(
                        spacing: 10,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: DirectionsWidget(
                                onTap: () {
                                  setState(() {
                                    _directionsVisible = !_directionsVisible;
                                  });
                                },
                                text: _directions,
                                visibility: _directionsVisible),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: CircularIconMapButton(
                              backgroundColor: Colors.green,
                              borderColor: Color(0xFF2D6040),
                              onPressed: _toggleMapType,
                              icon: const Icon(Icons.map),
                            ),
                          ),
                          (!_polygonMode && !_pointMode)
                              ? Align(
                                  alignment: Alignment.topRight,
                                  child: CircularIconMapButton(
                                    borderColor: Color(0xFF2D6040),
                                    onPressed: () {
                                      setState(() {
                                        _deleteMode = !_deleteMode;
                                        if (_deleteMode == true) {
                                          _outsidePoint = false;
                                          _errorText =
                                              'You are in delete mode.';
                                        } else {
                                          _outsidePoint = false;
                                          _errorText =
                                              'You tried to place a point outside of the project area!';
                                        }
                                      });
                                    },
                                    backgroundColor:
                                        _deleteMode ? Colors.blue : Colors.red,
                                    icon: Icon(
                                      _deleteMode
                                          ? Icons.location_on
                                          : Icons.delete,
                                      size: 30,
                                    ),
                                  ),
                                )
                              : SizedBox(),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: _bottomSheetHeight + 35, left: 5),
                        child: VisibilitySwitch(
                          visibility: _oldVisibility,
                          onChanged: (value) {
                            // This is called when the user toggles the switch.
                            setState(() {
                              _oldVisibility = value;
                            });
                          },
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
                              DisplayModalButton(
                                  onPressed: (_pointMode ||
                                          _polygonMode ||
                                          _deleteMode ||
                                          !_testIsRunning)
                                      ? null
                                      : () {
                                          showModalAnimal(context);
                                        },
                                  text: 'Animal',
                                  icon: Icon(Icons.pets)),
                              DisplayModalButton(
                                  onPressed: (_pointMode ||
                                          _polygonMode ||
                                          _deleteMode ||
                                          !_testIsRunning)
                                      ? null
                                      : () {
                                          showModalVegetation(context);
                                        },
                                  text: 'Vegetation',
                                  icon: Icon(Icons.grass)),
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
                              DisplayModalButton(
                                  onPressed: (_pointMode ||
                                          _polygonMode ||
                                          _deleteMode ||
                                          !_testIsRunning)
                                      ? null
                                      : () {
                                          showModalWaterBody(context);
                                        },
                                  text: 'Body of Water',
                                  icon: Icon(Icons.water)),
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
                                          onPressed: (_polygonMode &&
                                                  _polygonPoints.length >= 3 &&
                                                  !_deleteMode)
                                              ? () {
                                                  _finalizePolygon();
                                                  setState(() {
                                                    _directions =
                                                        'Choose a category. Or, click finish if done.';
                                                  });
                                                }
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
                                              ((_pointMode || _polygonMode) &&
                                                      !_deleteMode)
                                                  ? () {
                                                      setState(() {
                                                        _pointMode = false;
                                                        _polygonMode = false;
                                                        _polygonMarkers = {};
                                                        _clearTypes();
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
                                      onPressed: (_pointMode ||
                                              _polygonMode ||
                                              _deleteMode ||
                                              _testIsRunning)
                                          ? null
                                          : () {
                                              showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return TestFinishDialog(
                                                        onNext: () {
                                                      _natureData.animals =
                                                          _animalData;
                                                      _natureData.vegetation =
                                                          _vegetationData;
                                                      _natureData.waterBodies =
                                                          _waterBodyData;
                                                      _natureData.weather =
                                                          _weatherData;
                                                      widget.activeTest
                                                          .submitData(
                                                              _natureData);
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
                                                                ProjectDetailsPage(
                                                                    projectData:
                                                                        widget
                                                                            .activeProject),
                                                          ));
                                                    });
                                                  });
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
                    (_outsidePoint || _deleteMode)
                        ? TestErrorText(text: _errorText)
                        : SizedBox(),
                  ],
                ),
              ),
      ),
    );
  }
}

class DisplayModalButton extends StatelessWidget {
  const DisplayModalButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: FilledButton.icon(
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
        onPressed: onPressed,
        label: Text(text),
        icon: icon,
        iconAlignment: IconAlignment.end,
      ),
    );
  }
}
