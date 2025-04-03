import 'package:flutter/material.dart';
import 'package:p2bp_2025spring_mobile/project_map_creation.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';

import 'db_schema_classes.dart';
import 'firestore_functions.dart';

class CreateProjectForm extends StatefulWidget {
  final Team activeTeam;

  const CreateProjectForm({super.key, required this.activeTeam});

  @override
  State<CreateProjectForm> createState() => _CreateProjectFormState();
}

class _CreateProjectFormState extends State<CreateProjectForm> {
  // TODO: add cover photo?
  String projectDescription = '';
  String projectTitle = '';
  String projectAddress = '';
  final _formKey = GlobalKey<FormState>();

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
              spacing: 5,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Cover Photo',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Project Name',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                CreationTextBox(
                  maxLength: 60,
                  labelText: 'Project Name',
                  maxLines: 1,
                  minLines: 1,
                  // Error message field includes validation (3 characters min)
                  errorMessage:
                      'Project names must be at least 3 characters long.',
                  onChanged: (titleText) {
                    setState(() {
                      projectTitle = titleText;
                    });
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Project Description',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                CreationTextBox(
                  maxLength: 240,
                  labelText: 'Project Description',
                  maxLines: 3,
                  minLines: 3,
                  // Error message field includes validation (3 characters min)
                  errorMessage:
                      'Project descriptions must be at least 3 characters long.',
                  onChanged: (descriptionText) {
                    setState(() {
                      projectDescription = descriptionText;
                    });
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
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
                        triggerMode: TooltipTriggerMode.tap,
                        enableTapToDismiss: true,
                        showDuration: Duration(seconds: 3),
                        preferBelow: false,
                        message: 'Enter a central address for the designated '
                            'project location. \nIf no such address exists, '
                            'give an approximate location.',
                        child: Icon(
                          Icons.help,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                CreationTextBox(
                  maxLength: 120,
                  labelText: 'Project Address',
                  maxLines: 2,
                  minLines: 2,
                  errorMessage:
                      'Project address must be at least 3 characters long.',
                  onChanged: (addressText) {
                    setState(() {
                      projectAddress = addressText;
                    });
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
                    onPressed: () async {
                      if (await getCurrentTeam() == null) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'You are not in a team! Join a team first.')),
                        );
                      } else if (_formKey.currentState!.validate()) {
                        Project partialProject = Project.partialProject(
                          title: projectTitle,
                          description: projectDescription,
                          address: projectAddress,
                        );
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjectMapCreation(
                              partialProjectData: partialProject,
                            ),
                          ),
                        );
                      } // function
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
