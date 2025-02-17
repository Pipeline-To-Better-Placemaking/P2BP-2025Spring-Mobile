import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Conversion used for length and area to convert from meters to feet.
// Make sure to multiply twice (or square) for use in area,
const double feetPerMeter = 3.280839895;

// Default position (UCF) if location is denied.
const LatLng defaultLocation = LatLng(28.6024, -81.2001);

/// Requests permission for user's location. If denied defaults to UCF location.
/// If accepted returns the user's current location
Future<LatLng> checkAndFetchLocation() async {
  try {
    Position tempPosition;
    LocationPermission permission = await _checkLocationPermissions();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      return defaultLocation;
    }

    tempPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return LatLng(tempPosition.latitude, tempPosition.longitude);
  } catch (e) {
    print('Error checking location permissions: $e');

    return defaultLocation;
  }
}

/// Checks user's location permission. If denied, requests permission. Returns
/// LocationPermission of user's choice.
Future<LocationPermission> _checkLocationPermissions() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    permission = await Geolocator.requestPermission();
  }
  return permission;
}

/// Sorts the polygonPoints into a clockwise representation. Then creates a
/// polygon out of those points (makes sure the polygon is logical). Returns
/// the singular polygon as a Set so it can be used directly on the GoogleMap
/// widget.
Set<Polygon> finalizePolygon(List<LatLng> polygonPoints) {
  Set<Polygon> polygon = {};
  try {
    // Sort points in clockwise order
    List<LatLng> sortedPoints = _sortPointsClockwise(polygonPoints);

    // Creates polygon ID from time
    final String polygonId = DateTime.now().millisecondsSinceEpoch.toString();

    polygon = {
      Polygon(
        polygonId: PolygonId(polygonId),
        points: sortedPoints,
        strokeColor: Colors.blue,
        strokeWidth: 2,
        fillColor: Colors.blue.withValues(alpha: 0.2),
      ),
    };
  } catch (e, stacktrace) {
    print('Excpetion in finalize_polygon(): $e');
    print('Stacktrace: $stacktrace');
  }
  return polygon;
}

/// Takes a list of LatLng points, sorts them into a clockwise representation
/// to create the ideal polygon. Returns a list of LatLng points.
List<LatLng> _sortPointsClockwise(List<LatLng> points) {
  // Calculate the centroid of the points
  double centerX =
      points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
  double centerY =
      points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;

  // Sort the points based on the angle from the centroid
  points.sort((a, b) {
    double angleA = _calculateAngle(centerX, centerY, a.latitude, a.longitude);
    double angleB = _calculateAngle(centerX, centerY, b.latitude, b.longitude);
    return angleA.compareTo(angleB);
  });

  return points;
}

/// Calculate the angle of the point relative to the centroid. Used to sort the
/// points into a clockwise representation.
double _calculateAngle(double centerX, double centerY, double x, double y) {
  return atan2(y - centerY, x - centerX);
}
