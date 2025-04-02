import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:p2bp_2025spring_mobile/db_schema_classes.dart';

import 'firestore_functions.dart';
import 'theme.dart';
import 'widgets.dart';

class EditProjectForm extends StatefulWidget {
  final Project activeProject;
  const EditProjectForm({super.key, required this.activeProject});

  @override
  State<EditProjectForm> createState() => _EditProjectFormState();
}

class _EditProjectFormState extends State<EditProjectForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.activeProject.title);
    descriptionController =
        TextEditingController(text: widget.activeProject.description);
  }

  Widget _deleteProjectDialog() {
    return GenericConfirmationDialog(
      titleText: 'Delete Project?',
      contentText:
          'This will delete the selected project and all the tests within it. '
          'This cannot be undone. '
          'Are you absolutely certain you want to delete this project?',
      declineText: 'No, go back',
      confirmText: 'Yes, delete it',
      onConfirm: () async {
        await deleteProject(widget.activeProject);

        if (!mounted) return;
        Navigator.pop(context, true);
      },
    );
  }

  void _saveChanges() {
    try {
      widget.activeProject.title = nameController.text;
      widget.activeProject.description = descriptionController.text;

      FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.activeProject.projectID)
          .update({
        'title': widget.activeProject.title,
        'description': widget.activeProject.description,
      });

      if (!mounted) return;
      Navigator.pop(context, 'altered');
    } catch (e, s) {
      print('Error updating project: $e');
      print('Stacktrace: $s');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Padding(
          // Padding for keyboard opening
          padding: MediaQuery.viewInsetsOf(context),
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
                    Center(
                      child: Text(
                        "Edit Project",
                        style: TextStyle(
                            color: p2bpYellow.shade600,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 20),
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
                              controller: nameController,
                              validator: (value) {
                                if (value == null || value.length < 3) {
                                  return 'Name must have at least 3 characters';
                                }
                                return null;
                              },
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
                        controller: descriptionController,
                        validator: (value) {
                          if (value == null || value.length < 3) {
                            return 'Description must have at least 3 characters';
                          }
                          return null;
                        },
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
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _saveChanges();
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
                              onPressed: () async {
                                final didDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => _deleteProjectDialog(),
                                );

                                if (!context.mounted) return;
                                if (didDelete == true) {
                                  Navigator.pop(context, 'deleted');
                                }
                              },
                            ),
                          ),
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
                        style:
                            TextStyle(fontSize: 16, color: Color(0xFFFFD700)),
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
      ),
    );
  }
}
