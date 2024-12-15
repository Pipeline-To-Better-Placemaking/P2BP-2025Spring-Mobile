import 'package:flutter/material.dart';

LinearGradient defaultGrad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: <Color>[
    Color(0xFF0A2A88),
    Color(0xFF62B6FF),
  ],
);

// List<ThemeData> appThemes = [
//   ThemeData(
//     //
//   ),
//
//   ThemeData(
//     //backgroundColor: Colors.grey,
//   ),
//
//   ThemeData(
//     //backgroundColor: Colors.grey,
//   ),
//
//   ThemeData(
//     //backgroundColor: Colors.grey,
//   ),
// ]

// GRADIENT: start = 0xFF0A2A88 end = 0x62B6FF  (top left to bottom right)
// Button color = 0xFFFFCC00
// TEXT COLOR = 0xFF333333
// TEXT LINK COLOR = 0xFFFFD700

// Bar Indicator for the Sliding Up Panels (Edit Project, Results)
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
