import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class ActivityFormBottomSheet extends StatefulWidget {
  @override
  _ActivityFormBottomSheetState createState() =>
      _ActivityFormBottomSheetState();
}

class _ActivityFormBottomSheetState extends State<ActivityFormBottomSheet> {
  TimeOfDay? _selectedTime;
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _activityNameController = TextEditingController();

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color.fromRGBO(
                    47, 109, 207, 0.2), // or choose a light grey if you prefer
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          // Vertical padding from the pill notch
          SizedBox(
            height: 16,
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 32.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              // Activity Name Input
              child: TextFormField(
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
              ),
            ),
          ),
          SizedBox(height: 16),
          // Activity Time via a dial spinner (using CupertinoTimerPicker)
          // Activity Time field (replacing the dial spinner)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 100),
            child: TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Start Time',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: TextStyle(color: Color(0xFF2F6DCF)),
                floatingLabelStyle: TextStyle(color: Color(0xFF1A3C70)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2F6DCF))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1A3C70))),
                border: OutlineInputBorder(),
              ),
              controller: _timeController,
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() {
                    _selectedTime = pickedTime;
                    _timeController.text = pickedTime.format(context);
                  });
                }
              },
            ),
          ),
          SizedBox(height: 16),
          // Dropdown menu for selecting an activity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField2<String>(
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
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: 'People In Place',
                  child: Text(
                    'People In Place',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'People in Motion',
                  child: Text('People in Motion',
                      style: TextStyle(color: Color(0xFF2F6DCF))),
                ),
                DropdownMenuItem(
                  value: 'Community Survey',
                  child: Text(
                    'Community Survey',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Spatial Boundaries',
                  child: Text(
                    'Spatial Boundaries',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Nature Prevalence',
                  child: Text(
                    'Nature Prevalence',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Lighting Profile',
                  child: Text(
                    'Lighting Profile',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Acoustical Profile',
                  child: Text(
                    'Acoustical Profile',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Absence of Order Locator',
                  child: Text(
                    'Absence of Order Locator',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Identifying Access',
                  child: Text(
                    'Identifying Access',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Identifying Program',
                  child: Text(
                    'Identifying Program',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Section Cutter',
                  child: Text(
                    'Section Cutter',
                    style: TextStyle(color: Color(0xFF2F6DCF)),
                  ),
                ),
              ],
              onChanged: (value) {
                // Handle selection
              },
              dropdownStyleData: DropdownStyleData(
                  width: 370,
                  maxHeight: 200, // Sets the popup menu's width to 200 pixels.
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 234, 245, 255),
                    borderRadius: BorderRadius.circular(12.0),
                  )),
            ),
          ),

          SizedBox(height: 32),
          // Placeholder for an interactable map
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
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
          ),
          SizedBox(height: 32),
          // Optional: A button to submit the form
          ElevatedButton(
            onPressed: () {
              final newActivity =
                  "Activity: ${_timeController.text} - {_activityNameController.text}";
              // Handle form submission
              Navigator.of(context).pop(newActivity);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2F6DCF),
            ),
            child: Text(
              "Save Activity",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
