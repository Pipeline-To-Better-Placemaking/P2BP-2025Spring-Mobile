import 'package:flutter/material.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';
import 'package:p2bp_2025spring_mobile/widgets.dart';

class ChangeProjectDescriptionForm extends StatefulWidget {
  final String currentDescription;

  const ChangeProjectDescriptionForm(
      {super.key, required this.currentDescription});

  @override
  State<ChangeProjectDescriptionForm> createState() =>
      _ChangeProjectDescriptionFormState();
}

class _ChangeProjectDescriptionFormState
    extends State<ChangeProjectDescriptionForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.currentDescription;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
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
                    const SizedBox(width: 60),
                    Text(
                      "Edit Project Description",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        Navigator.pop(context, _descriptionController.text);
                      },
                      child: Text(
                        "Done",
                        style: TextStyle(
                            color: Color(0xFF62B6FF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    // Activity Name Input
                    child: TextFormField(
                      controller: _descriptionController,
                      cursorColor: Colors.white,
                      maxLength: 240,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      keyboardType: TextInputType.multiline,
                      minLines: 6,
                      maxLines: null,
                      decoration: InputDecoration(
                        labelText: "Description",
                        labelStyle: TextStyle(color: Colors.white),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white38)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54)),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      ),
                      buildCounter: (
                        BuildContext context, {
                        required int currentLength,
                        required int? maxLength,
                        required bool isFocused,
                      }) {
                        return Text(
                          '$currentLength/${maxLength ?? "∞"}',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        );
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new project description';
                        }
                        if (value.length < 3) {
                          return 'Project description must be at least 3 characters long';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        "Provide a clear and concise summary of your project’s purpose, goals, and key details.",
                        textAlign: TextAlign.start,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "A well-written description helps collaborators understand the scope of the project and ensures clarity for future reference.",
                        textAlign: TextAlign.start,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
