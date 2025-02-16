import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';

import 'firestore_functions.dart';

class NaturePrevalence extends StatefulWidget {
  const NaturePrevalence({super.key});

  @override
  State<NaturePrevalence> createState() => _NaturePrevalenceState();
}

class _NaturePrevalenceState extends State<NaturePrevalence> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // getProjectInfo (for polygon area)
    // PolygonUtil.containsLocation -- warning if outside
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  SizedBox(height: 20),
                  Text(
                    "Follow the instructions.",
                    style: TextStyle(fontSize: 24),
                  ),
                  Center(
                    child: SizedBox(
                      // TODO: Explore alternative approaches. Maps widgets automatically sizes to infinity unless declared.
                      height: MediaQuery.of(context).size.height * .8,
                      child: Padding(
                        // TODO: Define padding
                        padding: const EdgeInsets.all(0),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                  target: const LatLng(45.521563, -122.677433)),
                              // onMapCreated: _onMapCreated,
                              // initialCameraPosition: CameraPosition(
                              //     target: _currentPosition, zoom: 14.0),
                              // polygons: _polygon,
                              // markers: _markers,
                              // onTap: _addPointsMode ? _togglePoint : null,
                              // mapType: _currentMapType, // Use current map type
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 60.0, vertical: 90.0),
                                // child: FloatingActionButton(
                                //   heroTag: null,
                                //   onPressed: _toggleMapType,
                                //   backgroundColor: Colors.green,
                                //   child: const Icon(Icons.map),
                                // ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 60.0, vertical: 20.0),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                // child: FloatingActionButton(
                                //   heroTag: null,
                                //   onPressed: () {
                                //     setState(() {
                                //       if (_polygonPoints.isEmpty) {
                                //         _polygonMode = true;
                                //       } else {
                                //         _finalizePolygon();
                                //       }
                                //     });
                                //   },
                                //   backgroundColor: Colors.blue,
                                //   child: const Icon(
                                //     Icons.check,
                                //     size: 35,
                                //   ),
                                // ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 10,
                      children: [
                        EditButton(
                          text: 'Wild',
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF4871AE),
                          icon: Icon(Icons.animation),
                          onPressed: () {},
                        ),
                        EditButton(
                          text: 'Domesticated',
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF4871AE),
                          icon: Icon(Icons.animation),
                          onPressed: () {},
                        ),
                        EditButton(
                          text: 'Finish',
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF4871AE),
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () async {
                            // if (_polygon.isNotEmpty) {
                            //   await saveProject(
                            //     projectTitle: widget.partialProjectData.title,
                            //     description:
                            //         widget.partialProjectData.description,
                            //     teamRef: await getCurrentTeam(),
                            //     polygonPoints: _polygonAsPoints,
                            //     // Polygon area is square meters
                            //     // (miles *= 0.00062137 * 0.00062137)
                            //     polygonArea: mp.SphericalUtil.computeArea(
                            //         _mapToolsPolygonPoints),
                            //   );
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
                            // } else {
                            //   ScaffoldMessenger.of(context).showSnackBar(
                            //     const SnackBar(
                            //         content: Text(
                            //             'Please designate your project area, and confirm with the check button.')),
                            //   );
                            // }
                          },
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
