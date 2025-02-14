import 'package:flutter/material.dart';
import 'dart:ui';
import 'create_project_details.dart';
import 'db_schema_classes.dart';

class TeamSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Graident background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A2A88),
                  Color(0xFF62B6FF),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row with Back Arrow and Settings butttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          // Add back navigation
                          Navigator.pop(context);
                        },
                      ),
                      Spacer(), // Push settings icon to the right edge of the screen

                      // Settings button with quick action menu
                      Builder(builder: (context) {
                        return IconButton(
                          icon: Image.asset(
                              'assets/custom_icons/Filter_Icon.png'),
                          onPressed: () {
                            // Calculate button position and menu placement.
                            final RenderBox button =
                                context.findRenderObject() as RenderBox;
                            final Offset buttonPosition =
                                button.localToGlobal(Offset.zero);
                            final double buttonWidth = button.size.width;
                            final double buttonHeight = button.size.height;

                            // Define your desired menu width.
                            const double menuWidth = 250;

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
                                buttonPosition.dy + buttonHeight - 2;
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
                                                    47, 109, 207, 0.85),
                                                child: IntrinsicWidth(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      // 'Change Project' button
                                                      InkWell(
                                                        onTap: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(0),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 12),
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  "Edit Team Name",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                              ),
                                                              Icon(Icons.edit,
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
                                                            Navigator.of(
                                                                    context)
                                                                .pop(1),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 12),
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  "Change Team Color",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                              ),
                                                              Icon(
                                                                  Icons
                                                                      .palette_outlined,
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
                                                            Navigator.of(
                                                                    context)
                                                                .pop(2),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 12),
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  "Select Projects",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                              ),
                                                              Icon(
                                                                  Icons
                                                                      .check_circle_outline,
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
                                                            Navigator.of(
                                                                    context)
                                                                .pop(3),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 12),
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  "Delete Team",
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
                        );
                      }),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // Profile Avatar and Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Avatar on the left
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: AssetImage(
                                'assets/profile_image.jpg'), // Replace with actual image
                          ),
                          GestureDetector(
                            onTap: () {
                              // Open image edit functionality
                            },
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(width: 90), // Space between avatar and team name

                      // Column with Team Name and Team Members Row
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Text
                            Text(
                              'Lake Nona Design Group',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),

                            SizedBox(
                                height:
                                    8), // Space between team name and avatars

                            // Team Members Row
                            SizedBox(
                              height: 36,
                              child: Stack(
                                  clipBehavior: Clip
                                      .none, // Allows the edit button to overlfow slightly
                                  children: [
                                    // Overlapping team members
                                    for (int index = 0; index < 6; index++)
                                      Positioned(
                                        left: index * 24.0, // Overlap amount
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundImage: AssetImage(
                                              'assets/member_$index.jpg'), // Replace with team member profile photos
                                        ),
                                      ),

                                    // Edit button overlapping the last avatar
                                    Positioned(
                                      left: 5 * 24.0 +
                                          20, // Overlap position for the last avatar
                                      top:
                                          12, // Adjust for proper vertical alignment
                                      child: GestureDetector(
                                        onTap: () {
                                          // Open team edit functionality
                                        },
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.blue,
                                          child: Icon(
                                            Icons.edit,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Invite button to the right of the Team Members Profile Avatars
                                    Positioned(
                                        left: 6 * 24.0 +
                                            20, // Place the invite button to the right of the team avatars
                                        top:
                                            -6, // Align with the team avatars vertically
                                        child: // Invite button
                                            ElevatedButton(
                                                onPressed: () {
                                                  // Invite functionality
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: Size(30, 25),
                                                  backgroundColor: Colors.blue,
                                                ),
                                                child: Icon(
                                                  Icons
                                                      .person_add, // Invite icon
                                                  color: Colors.white,
                                                  size: 20,
                                                )))
                                  ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 48),

                // Project Title and Create New Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Projects',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Add create new project logic
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.blue,
                          minimumSize: Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Create New',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Project List
                Expanded(
                  child: ListView.builder(
                    itemCount: 6, // Replace with project list length
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/RedHouse.png', // Replace with project image
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              'Project Title $index',
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing:
                                Icon(Icons.chevron_right, color: Colors.white),
                            onTap: () {
                              // Navigate to project details
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateProjectDetails(
                                      projectData: Project.partialProject(
                                          title: 'No data sent',
                                          description:
                                              'Accessed without project data'),
                                    ),
                                  ));
                            }, // Replace with project title
                          ),
                          Divider(
                            color: Colors.white.withOpacity(0.3),
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// IconButton(
//                         icon: Image.asset('assets/Filter_Icon.png'),
//                         onPressed: () {
//                           // Add settings/edit functionality
//                         },
//                       ),
