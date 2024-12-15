// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'theme.dart';
import 'results_panel.dart';
import 'edit_project_panel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          // Insert theme here
          ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Scaffold buildSlide() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("P2BP"),
      ),
      body: SlidingUpPanel(
        backdropEnabled: true, //darken background if panel is open
        color: Colors
            .transparent, //necessary if you have rounded corners for panel
        /// panel itself
        panelBuilder: (controller) => EditProjectPanel(
          controller: controller,
        ),

        /// header of panel while collapsed
        collapsed: Container(
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Column(
            children: [
              BarIndicator(),
              Center(
                child: Text(
                  "Temporary until Project Home Page Integration",
                  style: TextStyle(color: Colors.yellow[700]),
                ),
              ),
            ],
          ),
        ),

        /// widget behind panel

        body: Center(
          child: ElevatedButton(
            child: const Text('Go to Results Page'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SecondRoute()),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: buildSlide());
  }
}

class SecondRoute extends StatelessWidget {
  const SecondRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results Page'),
      ),
      body: SlidingUpPanel(
        backdropEnabled: true, //darken background if panel is open
        color: Colors
            .transparent, //necessary if you have rounded corners for panel
        /// panel itself
        panelBuilder: (controller) => ResultsPanel(
          controller: controller,
        ),

        /// header of panel while collapsed
        collapsed: Container(
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Column(
            children: [
              BarIndicator(),
              Center(
                child: Text(
                  "Results",
                  style: TextStyle(color: Colors.yellow[700]),
                ),
              ),
            ],
          ),
        ),

        /// widget behind panel

        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Back to Home/Edit Project'),
          ),
        ),
      ),
    );
  }
}
