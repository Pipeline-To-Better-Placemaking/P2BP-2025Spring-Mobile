import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Widget tracingInstructions() {
  return RichText(
    text: TextSpan(
      style: TextStyle(fontSize: 15, color: Colors.black),
      children: [
        TextSpan(text: "1. ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "Tap the "),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            width: 24, // Smaller than in the legend
            height: 24,
            decoration: BoxDecoration(
              color: Colors.brown, // Same color as your tracing mode button
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                FontAwesomeIcons.pen,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
        TextSpan(
          text:
              " button to begin tracing points along the route. After each consecutive point placed, a gray line will automatically appear to connect them.\n",
        ),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(text: "2. ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "While tracing, a menu will appear with two options:\n"),
        // Bullet point for Cancel
        TextSpan(text: "   • "),
        TextSpan(text: "If you make a mistake, tap "),
        TextSpan(
            text: "Cancel ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "to clear your current path and start over.\n"),
        // Bullet point for Confirm
        TextSpan(text: "   • "),
        TextSpan(text: "If you're done tracing, tap "),
        TextSpan(
          text: "Confirm ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(
            text: "to store the route and assign an activity type to it.\n"),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(text: "3. ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "Confirmed routes are color coded by activity type:"),
        WidgetSpan(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: activityColorsRow())),
        TextSpan(
          text: "\n4. ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(
            text: "If you finish before the activity period ends, tap the "),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            width: 32,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "End",
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        TextSpan(
            text:
                " button to conclude the activity and save all recorded data.\n"),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(text: "Note: ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "Once a path is confirmed, it "),
        TextSpan(
            text: "cannot ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "be edited.")
      ],
    ),
  );
}

Widget buildLegends() {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Define horizontal spacing between items:
      const double spacing = 16;
      // Calculate the width for each legend item so that 2 items per row fit:
      double itemWidth = (constraints.maxWidth - spacing) / 2;
      return Column(
        children: [
          Text(
            "What the Buttons Do:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              legendItem(Icons.layers, "Toggle Map View", Colors.green,
                  BoxShape.circle, itemWidth),
              legendItem(FontAwesomeIcons.info, "Toggle Instructions",
                  Colors.blue, BoxShape.circle, itemWidth),
              legendItem(FontAwesomeIcons.locationDot, "Recorded Routes",
                  Colors.purple, BoxShape.circle, itemWidth),
              legendItem(FontAwesomeIcons.pen, "Tracing Mode", Colors.brown,
                  BoxShape.circle, itemWidth),
            ],
          ),
        ],
      );
    },
  );
}

Widget legendItem(IconData icon, String label, Color buttonColor,
    BoxShape buttonShape, double width) {
  return Container(
    width: width,
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: buttonColor,
            shape: buttonShape,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 15,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

Widget activityColorsRow() {
  return Wrap(
    spacing: 16,
    runSpacing: 8,
    children: [
      buildActivityColorItem("Walking", Colors.teal),
      buildActivityColorItem("Running", Colors.red),
      buildActivityColorItem("Swimming", Colors.cyan),
      buildActivityColorItem("On Wheels", Colors.orange),
      buildActivityColorItem("Handicap Assisted", Colors.purple),
    ],
  );
}

Widget buildActivityColorItem(String label, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 14)),
    ],
  );
}
