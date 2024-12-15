import 'package:flutter/material.dart';
import 'theme.dart';

class ResultsPanel extends StatefulWidget {
  final ScrollController controller;

  const ResultsPanel({
    super.key,
    required this.controller,
  });

  @override
  State<ResultsPanel> createState() => _ResultsPanelState();
}

class _ResultsPanelState extends State<ResultsPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // background color of panel
        color: Colors.blueAccent,
        // rounded corners of panel
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BarIndicator(),
          Center(
            child: Text(
              "Results",
              style: TextStyle(
                  color: Colors.yellow[700],
                  fontSize: 32,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
