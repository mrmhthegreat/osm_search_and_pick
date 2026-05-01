import 'package:flutter/material.dart';
import 'package:osm_search_and_pick/models/lat_long.dart';

/// Represents a polyline route to be drawn on the map.
class RouteData {
  /// The list of waypoints that form the route.
  final List<LatLong> points;

  /// The colour of the route line. Defaults to blue.
  final Color color;

  /// The stroke width of the route line. Defaults to 4.0.
  final double strokeWidth;

  /// Whether the route line should be dotted. Defaults to false.
  final bool isDotted;

  /// Optional label shown alongside the route.
  final String? label;

  const RouteData({
    required this.points,
    this.color = Colors.blue,
    this.strokeWidth = 4.0,
    this.isDotted = false,
    this.label,
  });
}
