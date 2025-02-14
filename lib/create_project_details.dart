import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'db_schema_classes.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:p2bp_2025spring_mobile/create_activity_bottom_sheet.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

// IMPORTANT: When navigating to this page, pass in project details. Use
// getProjectInfo() from firestore_functions.dart to retrieve project object w/ data.
// *Note: project is returned as future. Must await response before passing.
class CreateProjectDetails extends StatefulWidget {
  final Project projectData;
  const CreateProjectDetails({super.key, required this.projectData});

  @override
  State<CreateProjectDetails> createState() => _CreateProjectDetailsState();
}

User? loggedInUser = FirebaseAuth.instance.currentUser;

class _CreateProjectDetailsState extends State<CreateProjectDetails> {
  int itemCount = 10;
  bool _isLoading = false;
  Project? project;

  @override
  Widget build(BuildContext context) {
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
                statusBarBrightness: Brightness.dark),
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
                  icon: Icon(Icons.arrow_back,
                      color: Color(0xFF2F6DCF), size: 20),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            // 'Edit Options' button overlayed on right side of cover photo
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
                          color: Color(0xFF2F6DCF),
                        ),
                        onPressed: () {
                          // Calculate button position and menu placement.
                          final RenderBox button =
                              context.findRenderObject() as RenderBox;
                          final Offset buttonPosition =
                              button.localToGlobal(Offset.zero);
                          final double buttonWidth = button.size.width;
                          final double buttonHeight = button.size.height;

                          // Define your desired menu width.
                          const double menuWidth = 200;

                          // Get the screen width.
                          final double screenWidth =
                              MediaQuery.of(context).size.width;

                          // Calculate left offset so the menu is centered below the button.
                          double left = buttonPosition.dx +
                              (buttonWidth / 2) -
                              (menuWidth / 2);

                          // Right-edge padding
                          const double rightPadding = 16.0;

                          // Clamp the left offset so that the menu doesn't go offscreen (with right padding).
                          if (left < 0) {
                            left = 0;
                          } else if (left + menuWidth >
                              screenWidth - rightPadding) {
                            left = screenWidth - rightPadding - menuWidth;
                          }

                          // Top offset so that pop up menu hovers slightly below button
                          final double top =
                              buttonPosition.dy + buttonHeight + 8.0;
                          // Custom pop up menu with frosted glass style design
                          showGeneralDialog<int>(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Menu',
                            barrierColor: Colors.transparent, // No dimming.
                            transitionDuration: Duration(milliseconds: 300),
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
                              return Stack(
                                children: [
                                  // Position the menu using the computed left and top.
                                  Positioned(
                                    left: left,
                                    top: top,
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: SizedBox(
                                        width: menuWidth,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 10, sigmaY: 10),
                                            child: Container(
                                              // #2F6DCF converted to RGB values
                                              color: Color.fromRGBO(
                                                  47, 109, 207, 0.7),
                                              child: IntrinsicWidth(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    // 'Change Project' button
                                                    InkWell(
                                                      onTap: () =>
                                                          Navigator.of(context)
                                                              .pop(0),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16,
                                                                vertical: 12),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                "Change Project Photo",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                            ),
                                                            Icon(
                                                                Icons
                                                                    .camera_alt,
                                                                color: Colors
                                                                    .white),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Divider(
                                                        color: Colors.white54,
                                                        height: 1),
                                                    // 'Edit Project Name' button
                                                    InkWell(
                                                      onTap: () =>
                                                          Navigator.of(context)
                                                              .pop(1),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16,
                                                                vertical: 12),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                "Edit Project Name",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                            ),
                                                            Icon(
                                                                Icons
                                                                    .text_fields,
                                                                color: Colors
                                                                    .white),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Divider(
                                                        color: Colors.white54,
                                                        height: 1),
                                                    // 'Edit Project Description' button
                                                    InkWell(
                                                      onTap: () =>
                                                          Navigator.of(context)
                                                              .pop(2),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16,
                                                                vertical: 12),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                "Edit Project Description",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                            ),
                                                            Icon(
                                                                Icons
                                                                    .description,
                                                                color: Colors
                                                                    .white),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Divider(
                                                        color: Colors.white54,
                                                        height: 1),
                                                    // 'Delete Project' button
                                                    InkWell(
                                                      onTap: () =>
                                                          Navigator.of(context)
                                                              .pop(3),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16,
                                                                vertical: 12),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                "Delete Project",
                                                                style: TextStyle(
                                                                    color: Color(
                                                                        0xFFFD6265),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              ),
                                                            ),
                                                            Icon(Icons.delete,
                                                                color: Color(
                                                                    0xFFFD6265)),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                            transitionBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ).then((value) {
                            if (value != null) {
                              // Handle menu selection.
                              if (value == 0) {
                                print("Change Cover Photo");
                              } else if (value == 1) {
                                print("Edit Project Name");
                              } else if (value == 2) {
                                print("Edit Project Description");
                              } else if (value == 3) {
                                print("Delete Project");
                              }
                            }
                          });
                        },
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
          SliverList(
            delegate: SliverChildListDelegate([
              Container(
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
                              bottom:
                                  BorderSide(color: Colors.white, width: .5),
                            ),
                            color: Color(0x699F9F9F),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 5.0),
                            child: Text.rich(
                              maxLines: 7,
                              overflow: TextOverflow.ellipsis,
                              TextSpan(
                                  text:
                                      "${widget.projectData.description}\n\n\n"),
                              style:
                                  TextStyle(fontSize: 15, color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                        Center(
                          child: Container(
                            width: 300,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Color(0x699F9F9F),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x98474747),
                                  spreadRadius: 3,
                                  blurRadius: 3,
                                  offset: Offset(
                                      0, 3), // changes position of shadow
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 77.5),
                              child: SizedBox(
                                width: 200,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.only(
                                        left: 15, right: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    // foregroundColor: foregroundColor,
                                    backgroundColor: Colors.black,
                                  ),
                                  onPressed: () => {
                                    // TODO: Function
                                  },
                                  label: Text('View Project Area'),
                                  icon: Icon(Icons.location_on),
                                  iconAlignment: IconAlignment.start,
                                ),
                              ),
                            ),
                          ),
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
                                  padding: const EdgeInsets.only(
                                      left: 15, right: 15),
                                  backgroundColor: Color(0xFF62B6FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  // foregroundColor: foregroundColor,
                                  // backgroundColor: backgroundColor,
                                ),
                                onPressed: () => {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled:
                                        true, // allows the sheet to be fully draggable
                                    backgroundColor: Colors
                                        .transparent, // makes the sheet's corners rounded if desired
                                    builder: (BuildContext context) {
                                      return DraggableScrollableSheet(
                                        initialChildSize:
                                            0.7, // initial height as 50% of screen height
                                        minChildSize:
                                            0.3, // minimum height when dragged down
                                        maxChildSize:
                                            0.9, // maximum height when dragged up
                                        builder: (BuildContext context,
                                            ScrollController scrollController) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Color.fromARGB(
                                                  255, 234, 245, 255),
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(16.0),
                                                topRight: Radius.circular(16.0),
                                              ),
                                            ),
                                            child: ActivityFormBottomSheet(),

                                            // Replace this ListView with your desired content
                                          );
                                        },
                                      );
                                    },
                                  ),
                                },
                                label: Text('Create'),
                                icon: Icon(Icons.add),
                                iconAlignment: IconAlignment.end,
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 0,
                          child: Container(
                            // TODO: change depending on size of description box.
                            height: 350,
                            decoration: BoxDecoration(
                              color: Color(0x22535455),
                              border: Border(
                                top: BorderSide(color: Colors.white, width: .5),
                              ),
                            ),
                            child: itemCount > 0
                                ? ListView.separated(
                                    itemCount: itemCount,
                                    padding: const EdgeInsets.only(
                                      left: 15,
                                      right: 15,
                                      top: 25,
                                      bottom: 30,
                                    ),
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return TestCard();
                                    },
                                    separatorBuilder:
                                        (BuildContext context, int index) =>
                                            const SizedBox(
                                      height: 10,
                                    ),
                                  )
                                : _isLoading == true
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : const Center(
                                        child: Text(
                                            'No research activities. Create one first!'),
                                      ),
                            width: double.infinity,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          )
        ],
      ),
    );
  }
}

class TestCard extends StatelessWidget {
  const TestCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: <Widget>[
            // TODO: change corresponding to test type
            CircleAvatar(),
            SizedBox(width: 15),
            Expanded(
              child: Text("Placeholder (Research activity)"),
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
                  // TODO: Actual function (chevron right, project details)
                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => TeamSettingsScreen()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
