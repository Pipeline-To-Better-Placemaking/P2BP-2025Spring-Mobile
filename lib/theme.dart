import 'package:flutter/material.dart';
import 'package:p2bp_2025spring_mobile/custom_material_colors.dart';

// Color constants:
/// Default color used when test buttons are disabled.
const Color disabledGrey = Color(0xCD6C6C6C);

/// Transparency for test hint text (or, the directions at the top of the
/// test map screen).
const Color directionsTransparency = Color(0xDFDDE6F2);

/// Default yellow color, used mainly for text on blue gradient background.
const Color placeYellow = Color(0xFFFFD31F);

/// Colors used for Vegetation in Nature Prevalence Test
class VegetationColors {
  static const Color nativeGreen = Color(0x6508AC12);
  static const Color designGreen = Color(0x656DFD75);
  static const Color openFieldGreen = Color(0x65C7FF80);
  static const Color otherGreen = Color(0x6C00FF3C);
}

/// Colors used for Bodies of Water in Nature Prevalence Test
class WaterBodyColors {
  static const Color oceanBlue = Color(0x651020FF);
  static const Color riverBlue = Color(0x656253EA);
  static const Color lakeBlue = Color(0x652FB3DD);
  static const Color swampBlue = Color(0x65009595);

  /// Used if retrieval from class map is null (should only be used if error)
  static const Color nullBlue = Color(0x934800FF);
}

/// Primary blue color used across the app
final MaterialColor p2bpBlue = generateMaterialColor(const Color(0xFF2F6DCF));

/// Primary accent color, used for buttons on screens with default gradient background
final MaterialColor p2bpBlueAccent =
    generateMaterialColor(const Color(0xFF62B6FF));

/// Dark blue color used for default gradient
final MaterialColor p2bpDarkBlue =
    generateMaterialColor(const Color(0xFF0A2A88));

/// Primary yellow color used across the app
final MaterialColor p2bpYellow = generateMaterialColor(const Color(0xFFFFCC00));

/// Primary bottom sheet background color when a gradient is not used
final MaterialColor bottomSheetBlue =
    generateMaterialColor(const Color(0xFFDDE6F2));

LinearGradient defaultGrad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: <Color>[
    p2bpDarkBlue,
    p2bpBlueAccent,
  ],
);

final LinearGradient verticalBlueGrad = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: <Color>[
    p2bpDarkBlue,
    p2bpBlueAccent,
  ],
);

/// Style for buttons on Test pages that are not toggleable
/// requiring custom conditional color values.
final ButtonStyle testButtonStyle = FilledButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 15),
  foregroundColor: Colors.black,
  backgroundColor: Colors.white,
  disabledBackgroundColor: Color(0xCD6C6C6C),
  iconColor: Colors.black,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
  ),
  textStyle: TextStyle(fontSize: 14),
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
