import 'package:flutter/material.dart';

class ProjectListWidget extends StatelessWidget {
  final bool isMultiSelectMode;
  final Set<int> selectedProjects;
  final Function(int) onToggleSelection;
  final Function(int) onProjectTap;

  const ProjectListWidget({
    super.key,
    required this.isMultiSelectMode,
    required this.selectedProjects,
    required this.onToggleSelection,
    required this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6, // Replace with the actual project count
      itemBuilder: (context, index) {
        bool isSelected = selectedProjects.contains(index);
        return Column(
          children: [
            ListTile(
              // If in multi-select mode, show a checkmark bubble on the left.
              leading: isMultiSelectMode
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => onToggleSelection(index),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Color(0xFF62B6FF)
                                  : Colors.grey.withValues(alpha: 0.3),
                            ),
                            child: isSelected
                                ? Icon(Icons.check,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        ),
                        SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/RedHouse.png', // Replace with project image
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
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
              // Hide trailing chevron when in multi-select mode
              trailing: isMultiSelectMode
                  ? null
                  : Icon(Icons.chevron_right, color: Colors.white),
              onTap: () {
                if (isMultiSelectMode) {
                  onToggleSelection(index);
                } else {
                  onProjectTap(index);
                }
              },
            ),
            isMultiSelectMode
                ? Divider(
                    color: Colors.white.withValues(alpha: 0.3),
                    thickness: 1,
                    indent: 50,
                    endIndent: 16,
                  )
                : Divider(
                    color: Colors.white.withValues(alpha: 0.3),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
          ],
        );
      },
    );
  }
}

// void _settingsButtonPressed(BuildContext context) async {
//   // Calculate button position and menu placement.
//   final RenderBox button = context.findRenderObject() as RenderBox;
//   final Offset buttonPosition = button.localToGlobal(Offset.zero);
//   final double buttonWidth = button.size.width;
//   final double buttonHeight = button.size.height;
//
//   // Define your desired menu width.
//   const double menuWidth = 250;
//
//   // Get the screen width.
//   final double screenWidth = MediaQuery.sizeOf(context).width;
//
//   // Calculate left offset so the menu is centered below the button.
//   double left = buttonPosition.dx + (buttonWidth / 2) - (menuWidth / 2);
//
//   // Right-edge padding
//   const double rightPadding = 16.0;
//
//   // Clamp the left offset so that the menu doesn't go offscreen (with right padding).
//   if (left < 0) {
//     left = 0;
//   } else if (left + menuWidth > screenWidth - rightPadding) {
//     left = screenWidth - rightPadding - menuWidth;
//   }
//
//   // Top offset so that pop up menu hovers slightly below button
//   final double top = buttonPosition.dy + buttonHeight - 2;
//   // Custom pop up menu with frosted glass style design
//   final int? value = await showGeneralDialog<int>(
//     context: context,
//     barrierDismissible: true,
//     barrierLabel: 'Menu',
//     barrierColor: Colors.transparent, // No dimming.
//     transitionDuration: Duration(milliseconds: 300),
//     pageBuilder: (context, animation, secondaryAnimation) {
//       return Stack(
//         children: [
//           // Position the menu using the computed left and top.
//           Positioned(
//             left: left,
//             top: top,
//             child: Material(
//               type: MaterialType.transparency,
//               child: SizedBox(
//                 width: menuWidth,
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(15),
//                   child: BackdropFilter(
//                     filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                     child: Container(
//                       // #2F6DCF converted to RGB values
//                       color: Color.fromRGBO(47, 109, 207, 0.85),
//                       child: IntrinsicWidth(
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             // 'Change Project' button
//                             InkWell(
//                               onTap: () => Navigator.of(context).pop(0),
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 16,
//                                   vertical: 12,
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     Expanded(
//                                       child: Text(
//                                         "Edit Team Name",
//                                         style: TextStyle(color: Colors.white),
//                                       ),
//                                     ),
//                                     Icon(
//                                       Icons.edit,
//                                       color: Colors.white,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             Divider(color: Colors.white54, height: 1),
//                             // 'Edit Project Name' button
//                             InkWell(
//                               onTap: () => Navigator.of(context).pop(1),
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 16, vertical: 12),
//                                 child: Row(
//                                   children: [
//                                     Expanded(
//                                       child: Text(
//                                         "Change Team Color",
//                                         style: TextStyle(color: Colors.white),
//                                       ),
//                                     ),
//                                     Icon(
//                                       Icons.palette_outlined,
//                                       color: Colors.white,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             Divider(color: Colors.white54, height: 1),
//                             // 'Edit Project Description' button
//                             InkWell(
//                               onTap: () => Navigator.of(context).pop(2),
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 16, vertical: 12),
//                                 child: Row(
//                                   children: [
//                                     Expanded(
//                                       child: Text(
//                                         "Select Projects",
//                                         style: TextStyle(color: Colors.white),
//                                       ),
//                                     ),
//                                     Icon(
//                                       Icons.check_circle_outline,
//                                       color: Colors.white,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             Divider(color: Colors.white54, height: 1),
//                             // 'Archive Project' button
//                             InkWell(
//                               onTap: () => Navigator.of(context).pop(3),
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 16, vertical: 12),
//                                 child: Row(
//                                   children: [
//                                     Expanded(
//                                       child: Text(
//                                         "Archive Team",
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                     ),
//                                     Icon(
//                                       FontAwesomeIcons.boxArchive,
//                                       color: Colors.white,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             Divider(color: Colors.white54, height: 1),
//                             // 'Delete Project' button
//                             InkWell(
//                               onTap: () => Navigator.of(context).pop(4),
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 16,
//                                   vertical: 12,
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     Expanded(
//                                       child: Text(
//                                         "Delete Team",
//                                         style: TextStyle(
//                                           color: Color(0xFFFD6265),
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                     Icon(Icons.delete,
//                                         color: Color(0xFFFD6265)),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       );
//     },
//     transitionBuilder: (context, animation, secondaryAnimation, child) {
//       return FadeTransition(
//         opacity: animation,
//         child: child,
//       );
//     },
//   );
//   if (!context.mounted) {
//     return;
//   }
//   // Handle menu selection.
//   if (value != null) {
//     if (value == 0) {
//       print("Edit Team Name");
//       showModalBottomSheet(
//         context: context,
//         isScrollControlled: true, // allows the sheet to be fully draggable
//         backgroundColor: Colors
//             .transparent, // makes the sheet's corners rounded if desired
//         builder: (BuildContext context) {
//           return DraggableScrollableSheet(
//             initialChildSize: 0.7, // initial height as 50% of screen height
//             minChildSize: 0.3, // minimum height when dragged down
//             maxChildSize: 0.9, // maximum height when dragged up
//             builder:
//                 (BuildContext context, ScrollController scrollController) {
//               return Container(
//                 decoration: BoxDecoration(
//                   gradient: defaultGrad,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(16.0),
//                     topRight: Radius.circular(16.0),
//                   ),
//                 ),
//                 child: ChangeTeamNameBottomSheet(),
//                 // Replace this ListView with your desired content
//               );
//             },
//           );
//         },
//       );
//     } else if (value == 1) {
//       print("Change Team Color");
//     } else if (value == 2) {
//       print("Select Projects");
//       // Toggle multi-select mode on the project list
//       toggleMultiSelect();
//     } else if (value == 3) {
//       print("Archive Team");
//     } else if (value == 4) {
//       print("Delete Team");
//       showDialog(
//         context: context,
//         barrierColor: Colors.black.withValues(alpha: 0.5), // Optional overlay
//         builder: (BuildContext context) {
//           return Dialog(
//             // mimics native AlertDialog margin
//             insetPadding: EdgeInsets.symmetric(
//               horizontal: 40.0,
//               vertical: 24.0,
//             ),
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             child: ClipRRect(
//               // default AlertDialog uses a small radius
//               borderRadius: BorderRadius.circular(18.0),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                 child: Container(
//                   // similar to AlertDialog's content padding
//                   padding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 14.0),
//                   decoration: BoxDecoration(
//                     // frosted glass effect
//                     color: p2bpBlue.withValues(alpha: 0.55),
//                     borderRadius: BorderRadius.circular(18.0),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Confirm Deletion",
//                         style: Theme.of(context)
//                             .textTheme
//                             .headlineMedium
//                             ?.copyWith(color: Colors.white),
//                       ),
//                       SizedBox(height: 20),
//                       Text(
//                         "Are you sure you want to delete this team and all associated projects?",
//                         style: Theme.of(context)
//                             .textTheme
//                             .bodyMedium
//                             ?.copyWith(color: Colors.white70),
//                       ),
//                       SizedBox(height: 10),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           TextButton(
//                             onPressed: () => Navigator.of(context).pop(),
//                             child: Text("Cancel",
//                                 style: TextStyle(color: Colors.white)),
//                           ),
//                           TextButton(
//                             onPressed: () {
//                               // Execute deletion logic here
//                               Navigator.of(context).pop();
//                             },
//                             child: Text("Delete",
//                                 style: TextStyle(color: Colors.red)),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     }
//   }
// }
