import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

/// Conversion used for length and area to convert from meters to feet.
/// Make sure to multiply twice (or square) for use in area,
const double feetPerMeter = 3.280839895;

/// Radius of the Earth in feet.
const double earthRadius = 20925646.3254;

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
Set<Polygon> finalizePolygon(List<LatLng> polygonPoints,
    [Color? polygonColor]) {
  Set<Polygon> polygon = {};
  List<LatLng> polygonPointsCopy = List.of(polygonPoints);
  try {
    // Sort points in clockwise order
    List<LatLng> sortedPoints = _sortPointsClockwise(polygonPointsCopy);

    // Creates polygon ID from time
    final String polygonId = DateTime.now().millisecondsSinceEpoch.toString();

    polygon = {
      Polygon(
        polygonId: PolygonId(polygonId),
        points: sortedPoints,
        strokeColor: polygonColor ?? Colors.blue,
        strokeWidth: 2,
        fillColor: polygonColor ?? Colors.blue.withValues(alpha: 0.2),
      ),
    };
  } catch (e, stacktrace) {
    print('Exception in finalizePolygon(): $e');
    print('Stacktrace: $stacktrace');
  }
  return polygon;
}

/// Takes a list of LatLng points, sorts them into a clockwise representation
/// to create the ideal polygon. Returns a list of LatLng points.
List<LatLng> _sortPointsClockwise(List<LatLng> points) {
  if (points.isEmpty) {
    throw Exception(
        'Empty points List passed to _sortPointsClockwise in google_maps_functions.dart');
  }
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

/// Returns a `Set<Polygon>` with a single `Polygon` made up of the given
/// [polygonPoints].
///
/// <br/> Note: This should render the points in the correct order. However, if
/// points are **not** connected in the correct order, change function to call
/// _sortPointsClockwise first.
Set<Polygon> getProjectPolygon(List<LatLng> polygonPoints) {
  Set<Polygon> projectPolygon = {};
  try {
    projectPolygon.add(Polygon(
      polygonId: PolygonId('project_polygon'),
      points: polygonPoints.toList(),
      fillColor: Color(0x52F34236),
      strokeColor: Colors.red,
      strokeWidth: 1,
    ));

    return projectPolygon;
  } catch (e, stacktrace) {
    print("Error creating project area (getProjectPolygon()) in "
        "google_maps_functions.dart. \nThis is likely due to an incorrect "
        "parameter type. Must be a list of GeoPoints.");
    print("The error is as follows: $e");
    print("Stacktrace: $stacktrace");
  }
  return projectPolygon;
}

LatLng getPolygonCentroid(Polygon polygon) {
  List<LatLng> polygonPoints = polygon.points;
  double latSum = 0;
  double lngSum = 0;
  int numPoints = polygonPoints.length;

  if (numPoints == 0) return defaultLocation;

  for (LatLng point in polygonPoints) {
    latSum += point.latitude.toDouble();
    lngSum += point.longitude.toDouble();
  }

  return LatLng(latSum / numPoints, lngSum / numPoints);
}

/// Creates a [Polyline] from a list of points. Returns that [Polyline]. If no
/// line can be created from the passed set of points returns [null]. Check
/// on function call for [null].
Polyline? createPolyline(List<LatLng> polylinePoints, Color color) {
  Polyline? polyline;
  final String polylineID;
  try {
    // Creates polygon ID from time
    polylineID = DateTime.now().millisecondsSinceEpoch.toString();

    polyline = Polyline(
      polylineId: PolylineId(polylineID),
      width: 4,
      startCap: Cap.squareCap,
      points: List.of(polylinePoints),
      color: color,
    );
  } catch (e, stacktrace) {
    print('Exception in createPolyline(): $e');
    print('Stacktrace: $stacktrace');
  }
  return polyline;
}

/// Gets the the rectangle bounds enclosing a polygon.
///
/// Takes a list of [LatLng] points and returns a [LatLngBounds]. If bounds
/// cannot be created (eg. points is empty) then returns null.
LatLngBounds? getLatLngBounds(List<LatLng> points) {
  LatLng southWest;
  LatLng northEast;

  if (points.isEmpty || points.firstOrNull == null) return null;

  southWest = points.first;
  northEast = points.first;

  for (LatLng point in points) {
    southWest = LatLng(min(point.latitude, southWest.latitude),
        min(point.longitude, southWest.longitude));
    northEast = LatLng(max(point.latitude, northEast.latitude),
        max(point.longitude, northEast.longitude));
  }

  return LatLngBounds(southwest: southWest, northeast: northEast);
}

/// Returns bool for if [point] is inside the [polygon] boundary.
bool isPointInsidePolygon(LatLng point, Polygon polygon) {
  List<LatLng> points = polygon.points.toList();
  final List<mp.LatLng> mpPolygon = points
      .map((latLng) => mp.LatLng(latLng.latitude, latLng.longitude))
      .toList();
  return mp.PolygonUtil.containsLocation(
    mp.LatLng(point.latitude, point.longitude),
    mpPolygon,
    false, // Edge considered outside; change as needed.
  );
}

/// Takes time in seconds and returns that time formatted as `mm:ss`
/// where `m` is minutes and `s` is seconds.
///
/// This is not really a google maps related thing but we have no other
/// file for general functions like this.
String formatTime(int time) {
  final minutes = time ~/ 60;
  final seconds = time % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
