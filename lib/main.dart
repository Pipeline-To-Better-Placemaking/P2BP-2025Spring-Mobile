// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static const customSwatch = MaterialColor(
    0xFFFF5252,
    <int, Color>{
      50: Color(0xFFFFEBEE),
      100: Color(0xFFFFCDD2),
      200: Color(0xFFEF9A9A),
      300: Color(0xFFE57373),
      400: Color(0xFFEF5350),
      500: Color(0xFFFF5252),
      600: Color(0xFFE53935),
      700: Color(0xFFD32F2F),
      800: Color(0xFFC62828),
      900: Color(0xFFB71C1C),
    },
  );

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: customSwatch,
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

class ObscuredTextBox extends StatelessWidget {
  const ObscuredTextBox({super.key});
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 100,
      width: 300,
      child: TextField(
        maxLength: 60,
        style: TextStyle(color: Colors.white),
        cursorColor: Colors.white10,
        decoration: InputDecoration(
          counterStyle: TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          labelText: 'Project Name',
          floatingLabelStyle: TextStyle(
            color: Colors.white,
          ),
          labelStyle: TextStyle(
            color: Colors.white60,
          ),
        ),
      ),
    );
  }
}

class ObscuredTextBox2 extends StatelessWidget {
  const ObscuredTextBox2({super.key});
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      child: TextField(
        style: TextStyle(color: Colors.white),
        maxLength: 240,
        maxLines: 4,
        minLines: 3,
        cursorColor: Colors.white10,
        decoration: InputDecoration(
          counterStyle: TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          labelText: 'Project Description',
          floatingLabelAlignment: FloatingLabelAlignment.start,
          floatingLabelStyle: TextStyle(
            color: Colors.white,
          ),
          labelStyle: TextStyle(
            color: Colors.white60,
          ),
        ),
      ),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("P2BP"),
      ),
      body: SlidingUpPanel(
        backdropEnabled: true, //darken background if panel is open
        color: Colors
            .transparent, //necessary if you have rounded corners for panel
        /// panel itself
        panel: Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              BarIndicator(),
              Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: 20),
                child: Text(
                  "Edit Project",
                  style: TextStyle(
                      color: Colors.yellow[700],
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.only(right: 35),
                    margin: const EdgeInsets.only(left: 20),
                    child: ObscuredTextBox(),
                  ),
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 27.0,
                        backgroundColor: Colors.yellow[700],
                        child: Center(
                            child: Icon(Icons.add_photo_alternate, size: 37)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          'Update Cover',
                          style: TextStyle(color: Colors.yellow[700]),
                        ),
                      )
                    ],
                  )
                ],
              ),
              Container(
                margin: const EdgeInsets.only(left: 20, right: 20),
                child: ObscuredTextBox2(),
              ),
              Row(
                children: [
                  Container(
                    alignment: Alignment.topLeft,
                    margin: const EdgeInsets.only(top: 75, left: 20, right: 5),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.only(left: 15, right: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.yellow[600],
                      ),
                      onPressed: () {},
                      label: const Text('Update Map'),
                      icon: Icon(Icons.gps_fixed),
                      iconAlignment: IconAlignment.end,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 75, left: 5, right: 20),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.only(left: 15, right: 10),
                        elevation: 100,
                        shadowColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        backgroundColor: Colors.black,
                      ),
                      onPressed: () {},
                      label: const Text('Delete Project'),
                      icon: Icon(Icons.delete),
                      iconAlignment: IconAlignment.end,
                    ),
                  ),
                ],
              ),
              InkWell(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Center(
                      child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: Colors.yellow[700]),
                  )),
                ),
                onTap: () {
                  setState(() {});
                },
              )
            ],
          ),
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
        panel: Container(
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

class BarIndicator extends StatelessWidget {
  const BarIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white60,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
    );
  }
}
