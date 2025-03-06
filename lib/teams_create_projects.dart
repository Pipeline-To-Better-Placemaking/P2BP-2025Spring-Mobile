// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:image_picker/image_picker.dart';
// import 'widgets.dart';
// import 'theme.dart';
// import 'search_location_screen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:p2bp_2025spring_mobile/project_map_creation.dart';
// import 'package:p2bp_2025spring_mobile/teams_and_invites_page.dart';
// import 'firestore_functions.dart';
// import 'home_screen.dart';
// import 'package:p2bp_2025spring_mobile/db_schema_classes.dart';

// class TeamsCreateProjects extends StatelessWidget {
//   String projectDescription = '';
//   String projectTitle = '';
//   final _formKey = GlobalKey<FormState>();

//   @override
//   Widget build(BuildContext context) {
//     SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark
//         .copyWith(statusBarIconBrightness: Brightness.light));
//     // Calculate the top padding: status bar height + app bar height.
//     final double topPadding =
//         MediaQuery.of(context).padding.top + kToolbarHeight - 70;
//     return Scaffold(
//         extendBodyBehindAppBar: true,
//         appBar: AppBar(
//             systemOverlayStyle: SystemUiOverlayStyle(
//                 statusBarColor: Colors.transparent,
//                 statusBarIconBrightness:
//                     Brightness.dark, // Android status bar color
//                 statusBarBrightness: Brightness.light // iOS status bar color
//                 ),
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             leading: IconButton(
//               icon:
//                   Icon(FontAwesomeIcons.chevronLeft, color: Color(0xFF2F6DCF)),
//               onPressed: () {
//                 Navigator.pop(context); // Navigate back to the previous screen;
//               },
//             ),
//             centerTitle: true,
//             title: ClipRRect(
//               borderRadius: BorderRadius.circular(60),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 32,
//                     vertical: 16,
//                   ),
//                   decoration: BoxDecoration(
//                       gradient: verticalBlueGrad.withOpacity(0.9),
//                       boxShadow: [
//                         BoxShadow(
//                             color: Colors.black.withValues(alpha: 0.16),
//                             offset: Offset(0, 4),
//                             blurRadius: 42)
//                       ] // Adjust to get a pill shape.
//                       ),
//                   child: const Text(
//                     'PROJECTS',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ),
//             )),
//         body: Stack(children: [
//           // Gray-blue background
//           Container(
//             decoration: BoxDecoration(color: Color(0xFFDDE6F2)),
//           ),

//           // Content
//           SafeArea(
//             child: Padding(
//               padding: EdgeInsets.only(top: topPadding),
//               child: Column(
//                 children: [
//                   Container(
//                     // width: 400,
//                     // height: 500,
//                     margin: EdgeInsets.symmetric(horizontal: 16.0),
//                     decoration: BoxDecoration(
//                       color: Colors.transparent,
//                       borderRadius: BorderRadius.all(Radius.circular(10)),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 20, vertical: 40),
//                       child: Column(
//                         children: <Widget>[
//                           Align(
//                             alignment: Alignment.centerLeft,
//                             child: Text(
//                               'Cover Photo',
//                               textAlign: TextAlign.left,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16.0,
//                                 color: Color(0xFF2F6DCF),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 5),
//                           PhotoUpload(
//                             width: 380,
//                             height: 125,
//                             backgroundColor: Colors.grey,
//                             icon: Icons.add_photo_alternate,
//                             circular: false,
//                             onTap: () async {
//                               print('Test');
//                               final XFile? pickedFile = await ImagePicker()
//                                   .pickImage(source: ImageSource.gallery);
//                               if (pickedFile != null) {
//                                 final File imageFile = File(pickedFile.path);
//                                 // Now you have the image file, and you can submit or process it.
//                                 print("Image selected: ${imageFile.path}");
//                               } else {
//                                 print("No image selected.");
//                               }
//                             },
//                           ),
//                           const SizedBox(height: 15.0),
//                           Align(
//                             alignment: Alignment.centerLeft,
//                             child: Text(
//                               'Project Name',
//                               textAlign: TextAlign.left,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16.0,
//                                 color: Color(0xFF2F6DCF),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 5),
//                           const CreationTextBox(
//                             maxLength: 60,
//                             labelText: 'Project Name',
//                             maxLines: 1,
//                             minLines: 1,
//                           ),
//                           const SizedBox(height: 10.0),
//                           Align(
//                             alignment: Alignment.centerLeft,
//                             child: Text(
//                               'Project Description',
//                               textAlign: TextAlign.left,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16.0,
//                                 color: Color(0xFF2F6DCF),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 5),
//                           const CreationTextBox(
//                             maxLength: 240,
//                             labelText: 'Project Description',
//                             maxLines: 3,
//                             minLines: 3,
//                           ),
//                           const SizedBox(height: 10.0),
//                           Align(
//                             alignment: Alignment.bottomRight,
//                             child: EditButton(
//                               text: 'Next',
//                               foregroundColor: Colors.white,
//                               backgroundColor: const Color(0xFF2F6DCF),
//                               icon: const Icon(Icons.chevron_right),
//                               onPressed: () async {
//                                 if (await getCurrentTeam() == null) {
//                                   // TODO: Display error for creating project before team
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(
//                                         content: Text(
//                                             'You are not in a team! Join a team first.')),
//                                   );
//                                 } else if (_formKey.currentState!.validate()) {
//                                   Project partialProject =
//                                       Project.partialProject(
//                                           title: projectTitle,
//                                           description: projectDescription);
//                                   Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                           builder: (context) =>
//                                               ProjectMapCreation(
//                                                   partialProjectData:
//                                                       partialProject)));
//                                 }
//                               },
//                             ),
//                           )
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           )
//         ]));
//   }
// }


// // Remember this hex code for later: 0xFFDDE6F2