import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:p2bp_2025spring_mobile/db_schema_classes.dart';

class CreateTestForm extends StatefulWidget {
  const CreateTestForm({super.key});

  @override
  State<CreateTestForm> createState() => _CreateTestFormState();
}

class _CreateTestFormState extends State<CreateTestForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _activityNameController = TextEditingController();

  DateTime? _selectedDateTime;
  String? _selectedTest;

  Future<DateTime?> showDateTimePicker({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    initialDate ??= DateTime.now();
    firstDate ??= initialDate.subtract(const Duration(days: 365 * 100));
    lastDate ??= firstDate.add(const Duration(days: 365 * 200));

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selectedDate == null) return null;

    if (!context.mounted) return selectedDate;

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    return selectedTime == null
        ? selectedDate
        : DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
  }

  @override
  void dispose() {
    _dateTimeController.dispose();
    _activityNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Center(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: <Widget>[
            // Pill notch
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(47, 109, 207, 0.2), // light grey?
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
            ),
            // Vertical padding from the pill notch
            SizedBox(height: 16),
            TextFormField(
              controller: _activityNameController,
              decoration: InputDecoration(
                labelText: "Activity Name",
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: TextStyle(color: Color(0xFF2F6DCF)),
                floatingLabelStyle: TextStyle(color: Color(0xFF1A3C70)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2F6DCF))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1A3C70))),
                border: OutlineInputBorder(),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name for this activity.';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            // Activity Time via a dial spinner (using CupertinoTimerPicker)
            // Activity Time field (replacing the dial spinner)
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Scheduled Time',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: TextStyle(color: Color(0xFF2F6DCF)),
                floatingLabelStyle: TextStyle(color: Color(0xFF1A3C70)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2F6DCF))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1A3C70))),
                border: OutlineInputBorder(),
              ),
              controller: _dateTimeController,
              onTap: () async {
                DateTime? pickedDateTime =
                    await showDateTimePicker(context: context);
                if (pickedDateTime != null) {
                  setState(() {
                    _selectedDateTime = pickedDateTime;
                    _dateTimeController.text =
                        pickedDateTime.toLocal().toString();
                  });
                }
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please schedule a time for this activity.';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            // Dropdown menu for selecting an activity
            DropdownButtonFormField2<String>(
              decoration: InputDecoration(
                labelText: "Select Activity",
                floatingLabelBehavior: FloatingLabelBehavior.never,
                // filled: true,
                // fillColor: Color.fromRGBO(47, 109, 207, 0.1),
                labelStyle: TextStyle(color: Color(0xFF2F6DCF)),
                floatingLabelStyle: TextStyle(color: Color(0xFF1A3C70)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2F6DCF))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1A3C70))),
                border: OutlineInputBorder(),
              ),
              dropdownStyleData: DropdownStyleData(
                width: 370,
                maxHeight: 200, // Sets the popup menu's width to 200 pixels.
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 234, 245, 255),
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: AbsenceOfOrderTest.collectionIDStatic,
                  child: Text(
                    'Absence of Order Locator',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
                DropdownMenuItem(
                  value: LightingProfileTest.collectionIDStatic,
                  child: Text(
                    'Lighting Profile',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
                DropdownMenuItem(
                  value: SectionCutterTest.collectionIDStatic,
                  child: Text(
                    'Section Cutter',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
                DropdownMenuItem(
                  value: IdentifyingAccessTest.collectionIDStatic,
                  child: Text(
                    'Identifying Access',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
                DropdownMenuItem(
                  value: PeopleInPlaceTest.collectionIDStatic,
                  child: Text(
                    'People in Place',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
                DropdownMenuItem(
                  value: PeopleInMotionTest.collectionIDStatic,
                  child: Text(
                    'People in Motion',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
                DropdownMenuItem(
                  value: NaturePrevalenceTest.collectionIDStatic,
                  child: Text(
                    'Nature Prevalence',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
              ],
              onChanged: (value) {
                _selectedTest = value;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null) {
                  return 'Please select an activity type.';
                }
                return null;
              },
            ),
            SizedBox(height: 32),
            // Placeholder for an interactable map
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  "Interactable Map Placeholder",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
            SizedBox(height: 32),
            // Optional: A button to submit the form
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final Map<String, dynamic> newTestInfo = {
                      'title': _activityNameController.text,
                      'scheduledTime': Timestamp.fromDate(_selectedDateTime!),
                      'collectionID': _selectedTest,
                    };
                    // Handle form submission
                    Navigator.of(context).pop(newTestInfo);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2F6DCF),
                ),
                child: Text(
                  "Save Activity",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
