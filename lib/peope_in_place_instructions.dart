import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Widget peopleInPlaceInstructions() {
  return RichText(
    text: TextSpan(
      style: TextStyle(fontSize: 16, color: Colors.black),
      children: [
        TextSpan(text: "1. ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(
            text:
                "After starting the activity, tap the screen inside the boundary to begin placing data points.\n"),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(text: "2. ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(
            text:
                "After placing a point, a menu will appear that will allow you to classify the age, gender, activity type, "
                "and current posture of the person you are logging.\n"),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(text: "3. ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(
            text:
                "Once logged, this invidual will be represented on the map via a color coded marker based on posture type.\n"),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(
          text: "4. ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(text: "Tapping the "),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            width: 24, // Smaller than in the legend
            height: 24,
            decoration: BoxDecoration(
              color: Colors.purple, // Same color as your tracing mode button
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                FontAwesomeIcons.locationDot,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
        TextSpan(
            text:
                " button will bring up a menu displaying each logged point. Here, you can delete indvidual points or all points on the map.\n"),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(
          text: "5. ",
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
              legendItem(FontAwesomeIcons.locationDot, "Logged Points",
                  Colors.purple, BoxShape.circle, itemWidth),
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
