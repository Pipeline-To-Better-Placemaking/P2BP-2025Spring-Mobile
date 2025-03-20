import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:p2bp_2025spring_mobile/show_project_options_dialog.dart';
import 'package:p2bp_2025spring_mobile/standing_points_page.dart';
import 'db_schema_classes.dart';
import 'package:flutter/services.dart';
import 'package:p2bp_2025spring_mobile/create_test_form.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'firestore_functions.dart';
import 'package:p2bp_2025spring_mobile/acoustic_profile_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'google_maps_functions.dart';
import 'mini_map.dart';

class ProjectDetailsPage extends StatefulWidget {
  final Project projectData;

  /// IMPORTANT: When navigating to this page, pass in project details. Use
  /// `getProjectInfo()` from firestore_functions.dart to retrieve project
  /// object w/ data.
  /// <br/>Note: project is returned as future, await return before passing.
  const ProjectDetailsPage({super.key, required this.projectData});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
User? loggedInUser = FirebaseAuth.instance.currentUser;

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  late int _testCount;
  bool _isLoading = true;
  Project? project;
  late Widget _testListView;
  LatLng _location = defaultLocation;
  final LatLng _currentLocation = defaultLocation;
  Set<Polygon> _polygons = {};
  late GoogleMapController mapController;

  @override
  void initState() {
    super.initState();
    initProjectArea();
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

  LatLngBounds _getPolygonBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    _testCount = widget.projectData.tests!.length;
    _testListView = _buildTestListView();
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            automaticallyImplyLeading: false, // Disable default back arrow
            leadingWidth: 48,
            systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.white,
                statusBarIconBrightness:
                    Brightness.dark, // Changes Android status bar to white
                statusBarBrightness:
                    Brightness.dark), // Changes iOS status bar to white
            // Custom back arrow button
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Container(
                // Opaque circle container for visibility
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets
                      .zero, // Removes internal padding from IconButton
                  constraints: BoxConstraints(),
                  icon: Icon(Icons.arrow_back, color: p2bpBlue, size: 20),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            // 'Edit Options' button overlaid on right side of cover photo
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Builder(
                  builder: (context) {
                    return Container(
                      // Opaque circle container for visibility
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        icon: Icon(
                          Icons.more_vert,
                          color: p2bpBlue,
                        ),
                        onPressed: () => showProjectOptionsDialog(context),
                      ),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(children: <Widget>[
                // Banner image
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white, width: .5),
                    ),
                    color: Color(0xFF999999),
                  ),
                ),
              ]),
            ),
          ),
          SliverList(delegate: SliverChildListDelegate([_getPageBody()])),
        ],
      ),
    );
  }

  Widget _getPageBody() {
    return Container(
      decoration: BoxDecoration(gradient: defaultGrad),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(
                  widget.projectData.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    'Project Description',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white, width: .5),
                    bottom: BorderSide(color: Colors.white, width: .5),
                  ),
                  color: Color(0x699F9F9F),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 5.0),
                  child: Text.rich(
                    maxLines: 7,
                    overflow: TextOverflow.ellipsis,
                    TextSpan(text: "${widget.projectData.description}\n\n\n"),
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: MiniMap(
                        projectData: widget.projectData,
                      ),
                    )),
              ),
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 25.0, vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Research Activities",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.only(left: 15, right: 15),
                        backgroundColor: Color(0xFF62B6FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        // foregroundColor: foregroundColor,
                        // backgroundColor: backgroundColor,
                      ),
                      onPressed: _showCreateTestModal,
                      label: Text('Create'),
                      icon: Icon(Icons.add),
                      iconAlignment: IconAlignment.end,
                    )
                  ],
                ),
              ),
              Container(
                // TODO: change depending on size of description box.
                height: 350,
                decoration: BoxDecoration(
                  color: Color(0x22535455),
                  border: Border(
                    top: BorderSide(color: Colors.white, width: .5),
                  ),
                ),
                child: _isLoading == true
                    ? const Center(child: CircularProgressIndicator())
                    : _testCount > 0
                        ? _testListView
                        : const Center(
                            child: Text(
                                'No research activities. Create one first!')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateTestModal() async {
    final Map<String, dynamic>? newTestInfo = await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows the sheet to be fully draggable
      backgroundColor:
          Colors.transparent, // makes the sheet's corners rounded if desired
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7, // initial height as 50% of screen height
          minChildSize: 0.3, // minimum height when dragged down
          maxChildSize: 0.9, // maximum height when dragged up
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 234, 245, 255),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: CreateTestForm(
                activeProject: widget.projectData,
              ),
              // Replace this ListView with your desired content
            );
          },
        );
      },
    );
    if (newTestInfo == null) return;
    final Test test;
    test = await saveTest(
      title: newTestInfo['title'],
      scheduledTime: newTestInfo['scheduledTime'],
      projectRef:
          _firestore.collection('projects').doc(widget.projectData.projectID),
      collectionID: newTestInfo['collectionID'],
      standingPoints: newTestInfo.containsKey('standingPoints')
          ? newTestInfo['standingPoints']
          : null,
    );
    setState(() {
      widget.projectData.tests?.add(test);
    });
  }

  Widget _buildTestListView() {
    Widget list = ListView.separated(
      itemCount: _testCount,
      padding: const EdgeInsets.only(
        left: 15,
        right: 15,
        top: 25,
        bottom: 30,
      ),
      itemBuilder: (BuildContext context, int index) => TestCard(
        test: widget.projectData.tests![index],
        project: widget.projectData,
      ),
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 10),
    );
    setState(() {
      _isLoading = false;
    });
    return list;
  }
}

const Map<Type, String> _testInitialsMap = {
  AbsenceOfOrderTest: 'AO',
  LightingProfileTest: 'LP',
  SectionCutterTest: 'SC',
  IdentifyingAccessTest: 'IA',
  PeopleInPlaceTest: 'PP',
  PeopleInMotionTest: 'PM',
  NaturePrevalenceTest: 'NP',
  AcousticProfileTestPage: 'AP',
};

class TestCard extends StatelessWidget {
  final Test test;
  final Project project;

  const TestCard({
    super.key,
    required this.test,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: <Widget>[
            // TODO: change corresponding to test type
            CircleAvatar(
              child: Text(_testInitialsMap[test.runtimeType] ?? ''),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Text(test.title),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: Colors.blue,
                ),
                tooltip: 'Open team settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => test.getPage(project)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
