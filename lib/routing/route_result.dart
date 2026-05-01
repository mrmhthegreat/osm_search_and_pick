import 'package:latlong2/latlong.dart';
import 'package:osm_search_and_pick/routing/routing_manager.dart';

/// A single turn-by-turn instruction.
class RouteStep {
  final String instruction;
  final double distanceMetres;
  final String maneuverType;

  const RouteStep({
    required this.instruction,
    required this.distanceMetres,
    required this.maneuverType,
  });

  String get formattedDistance {
    if (distanceMetres >= 1000) {
      return '${(distanceMetres / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMetres.round()} m';
  }
}

/// The full result from an OSRM route request.
class RouteResult {
  /// The polyline points to draw on the map.
  final List<LatLng> points;

  /// Total route distance in metres.
  final double distanceMetres;

  /// Total route duration in seconds.
  final double durationSeconds;

  /// Turn-by-turn steps.
  final List<RouteStep> steps;

  /// The travel mode used.
  final TravelMode travelMode;

  const RouteResult({
    required this.points,
    required this.distanceMetres,
    required this.durationSeconds,
    required this.steps,
    required this.travelMode,
  });

  /// Human-readable distance string.
  String get formattedDistance {
    if (distanceMetres >= 1000) {
      return '${(distanceMetres / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMetres.round()} m';
  }

  /// Human-readable ETA string.
  String get formattedDuration {
    final totalMinutes = (durationSeconds / 60).round();
    if (totalMinutes < 60) return '$totalMinutes min';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
  }
}
