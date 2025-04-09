import 'package:flutter/material.dart';
import 'package:p2bp_2025spring_mobile/project_map_creation.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';

import 'db_schema_classes.dart';

class CreateProjectForm extends StatefulWidget {
  final Member member;
  final Team activeTeam;

  const CreateProjectForm({
    super.key,
    required this.member,
    required this.activeTeam,
  });

  @override
  State<CreateProjectForm> createState() => _CreateProjectFormState();
}

class _CreateProjectFormState extends State<CreateProjectForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: MediaQuery.viewInsetsOf(context),
          child: Container(
            decoration: BoxDecoration(
              gradient: defaultGrad,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              spacing: 2,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const BarIndicator(),
                Text(
                  'Cover Photo',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: Colors.white,
                  ),
                ),
                PhotoUpload(
                  width: 380,
                  height: 130,
                  icon: Icons.add_photo_alternate,
                  circular: false,
                  onTap: () {
                    // TODO: Actual function (Photo Upload)
                    print('Test');
                    return;
                  },
                ),
                const SizedBox(height: 10.0),
                Text(
                  'Project Name',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: Colors.white,
                  ),
                ),
                EditProjectTextBox(
                  controller: _titleController,
                  labelText: 'Project Name',
                  maxLength: 60,
                  maxLines: 1,
                  minLines: 1,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  validator: (value) {
                    if (value == null || value.length < 3) {
                      return 'Project names must be at least 3 characters long';
                    }
                    return null;
                  },
                ),
                Text(
                  'Project Description',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: Colors.white,
                  ),
                ),
                EditProjectTextBox(
                  controller: _descriptionController,
                  labelText: 'Project Description',
                  maxLength: 240,
                  maxLines: 3,
                  minLines: 3,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  validator: (value) {
                    if (value == null || value.length < 3) {
                      return 'Project descriptions must be at least 3 characters long';
                    }
                    return null;
                  },
                ),
                Row(
                  spacing: 5,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Project Address',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
                    ),
                    Tooltip(
                      verticalOffset: 0,
                      margin: EdgeInsets.all(30),
                      triggerMode: TooltipTriggerMode.tap,
                      enableTapToDismiss: true,
                      showDuration: Duration(seconds: 5),
                      preferBelow: false,
                      message: 'Enter a central address for the designated '
                          'project location. \nIf no such address exists, '
                          'give an approximate location.',
                      child: Icon(
                        Icons.help,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                EditProjectTextBox(
                  controller: _addressController,
                  labelText: 'Project Address',
                  maxLength: 120,
                  maxLines: 2,
                  minLines: 2,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  validator: (value) {
                    if (value == null || value.length < 3) {
                      return 'Project address must be at least 3 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10.0),
                Align(
                  alignment: Alignment.bottomRight,
                  child: EditButton(
                    text: 'Next',
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF4871AE),
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;

                      // TODO add cover image uploading on project creation here
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectMapCreation(
                            member: widget.member,
                            team: widget.activeTeam,
                            title: _titleController.text,
                            description: _descriptionController.text,
                            address: _addressController.text,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
