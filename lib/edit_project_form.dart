import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:p2bp_2025spring_mobile/db_schema_classes.dart';

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
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.activeProject.title);
    _descriptionController =
        TextEditingController(text: widget.activeProject.description);
  }

  void _saveChanges() async {
    try {
      widget.activeProject.title = _nameController.text;
      widget.activeProject.description = _descriptionController.text;

      if (_imageFile != null) {
        final coverImageRef = FirebaseStorage.instance
            .ref('project_covers/${widget.activeProject.id}.jpg');
        await coverImageRef.putFile(_imageFile!);
        widget.activeProject.coverImageUrl =
            await coverImageRef.getDownloadURL();
      }

      await widget.activeProject.update();

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                spacing: 12,
                children: [
                  // Creates little indicator on top of sheet
                  const BarIndicator(bottomPadding: 0),
                  Text(
                    "Edit Project",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p2bpYellow.shade600,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project name text field
                      Expanded(
                        flex: 2,
                        child: EditProjectTextBox(
                          maxLength: 60,
                          maxLines: 2,
                          minLines: 1,
                          labelText: 'Project Name',
                          controller: _nameController,
                          validator: (value) {
                            if (value == null || value.length < 3) {
                              return 'Name must have at least 3 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      // Add photo button
                      InkWell(
                        onTap: () async {
                          final XFile? pickedFile = await ImagePicker()
                              .pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            _imageFile = File(pickedFile.path);
                          }
                        },
                        child: Column(
                          spacing: 3,
                          children: [
                            // PhotoUpload(
                            //   width: 54,
                            //   height: 54,
                            //   icon: Icons.add_photo_alternate,
                            //   onTap: () {},
                            //   circular: true,
                            //   backgroundColor: p2bpYellow,
                            // ),
                            CircleAvatar(
                              radius: 27.0,
                              backgroundColor: p2bpYellow,
                              child: Icon(
                                Icons.add_photo_alternate,
                                size: 36,
                              ),
                            ),
                            Text(
                              'Update Cover',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Project description text field
                  EditProjectTextBox(
                    maxLength: 240,
                    maxLines: 4,
                    minLines: 3,
                    labelText: 'Project Description',
                    controller: _descriptionController,
                    validator: (value) {
                      if (value == null || value.length < 3) {
                        return 'Description must have at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  Row(
                    spacing: 10,
                    children: [
                      // Save Changes button
                      EditButton(
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
                      // Delete project button
                      EditButton(
                        text: 'Delete Project',
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFFD32F2F),
                        icon: Icon(FontAwesomeIcons.trashCan),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        onPressed: () async {
                          final didDelete = await showDeleteProjectDialog(
                            context: context,
                            project: widget.activeProject,
                          );

                          if (!context.mounted) return;
                          if (didDelete == true) {
                            Navigator.pop(context, 'deleted');
                          }
                        },
                      ),
                    ],
                  ),
                  // Cancel button to close bottom sheet
                  InkWell(
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
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
