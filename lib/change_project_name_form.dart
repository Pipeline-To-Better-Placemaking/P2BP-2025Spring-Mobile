import 'package:flutter/material.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';

class ChangeProjectNameForm extends StatefulWidget {
  const ChangeProjectNameForm({super.key});

  @override
  State<ChangeProjectNameForm> createState() => _ChangeProjectNameFormState();
}

class _ChangeProjectNameFormState extends State<ChangeProjectNameForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                const BarIndicator(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 80),
                    Text(
                      "Edit Project Name",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) return;
                            Navigator.pop(context, _nameController.text);
                          },
                          child: Text(
                            "Done",
                            style: TextStyle(
                              color: Color(0xFF62B6FF),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    controller: _nameController,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      label: Text(
                        "Project Name",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54)),
                      prefix: SizedBox(width: 12.0),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new project name';
                      }
                      if (value.length < 3) {
                        return 'Project name must be at least 3 characters long';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 26),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        "Choose a name that clearly represents your project's purpose or objectives.",
                        textAlign: TextAlign.start,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Use a title that’s easy to recognize for collaborators and aligns with your project’s goals. If this is a client project, consider including the client’s name or a relevant keyword.",
                        textAlign: TextAlign.start,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "A well-chosen project name helps with organization and ensures team members can easily identify it.",
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      )
                    ],
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
