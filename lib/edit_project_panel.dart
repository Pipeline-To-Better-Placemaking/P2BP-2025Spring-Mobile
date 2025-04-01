import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:p2bp_2025spring_mobile/db_schema_classes.dart';
import 'theme.dart';
import 'widgets.dart';
import 'firestore_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProjectPanel extends StatefulWidget {
  final Project projectData;
  const EditProjectPanel({super.key, required this.projectData});

  @override
  State<EditProjectPanel> createState() => _EditProjectPanel();
}

class _EditProjectPanel extends State<EditProjectPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            showEditProjectModalSheet(context, widget.projectData);
          },
          child: const Text('Open bottom sheet'),
        ),
      ),
    );
  }
}

Future<bool> showEditProjectModalSheet(
    BuildContext context, Project projectData) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) {
          return buildEditSheet(context, projectData);
        },
      ) ??
      false;
}

// Function to return the content of the modal sheet for the Edit Button.
// Button should: propagate fields with relevant information then, on save,
// send that information to database. On cancel, clear fields and close.
Padding buildEditSheet(BuildContext context, Project projectData) {
  print(
      "Project data received: ${projectData.title}, ${projectData.description}");
  final TextEditingController projectNameController =
      TextEditingController(text: projectData.title);

  final TextEditingController projectDescController =
      TextEditingController(text: projectData.description);
  return Padding(
    // Padding for keyboard opening
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: SingleChildScrollView(
      child: Container(
        // Container decoration- rounded corners and gradient
        decoration: BoxDecoration(
          gradient: defaultGrad,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
        ),
        child: Column(
          children: [
            // Creates little indicator on top of sheet
            const BarIndicator(),
            Column(
              children: [
                ListView(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  children: <Widget>[
                    // Text for title of sheet
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        "Edit Project",
                        style: TextStyle(
                            color: p2bpYellow.shade600,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Project name text field
                        Expanded(
                          flex: 2,
                          child: Container(
                            // alignment: Alignment.center,
                            padding: const EdgeInsets.only(bottom: 20),
                            margin: const EdgeInsets.only(left: 20),
                            child: EditProjectTextBox(
                              maxLength: 60,
                              maxLines: 2,
                              minLines: 1,
                              labelText: 'Project Name',
                              controller: projectNameController,
                            ),
                          ),
                        ),

                        // Add photo button
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 27.0,
                                backgroundColor: p2bpYellow,
                                child: Center(
                                  child:
                                      Icon(Icons.add_photo_alternate, size: 37),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Text(
                                  'Update Cover',
                                  style: TextStyle(
                                    color: Color(0xFFFFD700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Project description text field
                    Container(
                      padding: const EdgeInsets.only(bottom: 20),
                      margin: const EdgeInsets.only(left: 20, right: 20),
                      child: EditProjectTextBox(
                        maxLength: 240,
                        maxLines: 4,
                        minLines: 3,
                        labelText: 'Project Description',
                        controller: projectDescController,
                      ),
                    ),
                    Row(
                      children: [
                        // Save Changes button
                        Expanded(
                          flex: 4,
                          child: Container(
                            alignment: Alignment.topLeft,
                            margin: const EdgeInsets.only(left: 20, right: 5),
                            child: EditButton(
                              text: 'Save Changes',
                              foregroundColor: Colors.black,
                              backgroundColor: p2bpYellow,
                              icon: const Icon(Icons.save),
                              iconColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              onPressed: () async {
                                try {
                                  print(
                                      "Saving changes - Project title: ${projectNameController.text}");
                                  print(
                                      "Saving changes - Project description: ${projectDescController.text}");

                                  if (projectNameController.text.length >= 3) {
                                    projectData.title =
                                        projectNameController.text;
                                  }
                                  if (projectDescController.text.length >= 3) {
                                    projectData.description =
                                        projectDescController.text;
                                  }

                                  await FirebaseFirestore.instance
                                      .collection('projects')
                                      .doc(projectData.projectID)
                                      .update({
                                    'title': projectData.title,
                                    'description': projectData.description,
                                  });

                                  if (context.mounted) {
                                    Navigator.pop(context, true);
                                  }
                                } catch (e) {
                                  print("Error updating project: $e");
                                }
                              },
                            ),
                          ),
                        ),

                        // Delete project button
                        Expanded(
                          flex: 4,
                          child: Container(
                            alignment: Alignment.topLeft,
                            margin: const EdgeInsets.only(left: 5, right: 20),
                            child: EditButton(
                              text: 'Delete Project',
                              foregroundColor: Colors.white,
                              backgroundColor: Color(0xFFD32F2F),
                              icon: Icon(FontAwesomeIcons.trashCan),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              // TODO: edit w/ actual function (delete project)
                              onPressed: () async {
                                bool confirmDelete = await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Delete Project?'),
                                          content: Text(
                                              'Are you sure you want to delete "${projectData.title}"? This cannot be undone.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: Text('Delete',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ),
                                          ],
                                        );
                                      },
                                    ) ??
                                    false;

                                if (confirmDelete) {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('projects')
                                        .doc(projectData.projectID)
                                        .delete();

                                    if (projectData.teamRef != null) {
                                      await projectData.teamRef!.update({
                                        'projects': FieldValue.arrayRemove([
                                          FirebaseFirestore.instance
                                              .collection('projects')
                                              .doc(projectData.projectID)
                                        ])
                                      });
                                    }

                                    Navigator.pop(context, true);
                                  } catch (e) {
                                    print("Error deleting project: $e");
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Cancel button to close bottom sheet
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: Color(0xFFFFD700)),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
