import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:osm_search_and_pick/models/pin_data.dart';
import 'package:osm_search_and_pick/routing/route_result.dart';

export 'package:osm_search_and_pick/routing/route_result.dart';

/// Travel mode for OSRM routing.
enum TravelMode {
  driving('driving'),
  walking('foot'),
  cycling('bike');

  final String osrmProfile;
  const TravelMode(this.osrmProfile);

  String get label => switch (this) {
        TravelMode.driving => 'Driving',
        TravelMode.walking => 'Walking',
        TravelMode.cycling => 'Cycling',
      };

  IconData get icon => switch (this) {
        TravelMode.driving => Icons.directions_car,
        TravelMode.walking => Icons.directions_walk,
        TravelMode.cycling => Icons.directions_bike,
      };
}

/// State for a single routing session.
class RoutingState {
  final List<LatLng> waypoints; // start, optional stops, end
  final TravelMode travelMode;
  final RouteResult? result;
  final bool isFetching;
  final String? error;

  const RoutingState({
    this.waypoints = const [],
    this.travelMode = TravelMode.driving,
    this.result,
    this.isFetching = false,
    this.error,
  });

  RoutingState copyWith({
    List<LatLng>? waypoints,
    TravelMode? travelMode,
    RouteResult? result,
    bool? isFetching,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) =>
      RoutingState(
        waypoints: waypoints ?? this.waypoints,
        travelMode: travelMode ?? this.travelMode,
        result: clearResult ? null : (result ?? this.result),
        isFetching: isFetching ?? this.isFetching,
        error: clearError ? null : (error ?? this.error),
      );

  bool get hasStart => waypoints.isNotEmpty;
  bool get hasEnd => waypoints.length >= 2;
  bool get isComplete => result != null;
}

/// Manages all routing logic separately from the main widget.
/// Keeps [OpenStreetMapSearchAndPick] clean.
class RoutingManager extends ChangeNotifier {
  RoutingManager({
    required this.baseUri,
    required this.userAgentPackageName,
    required http.Client httpClient,
  }) : _client = httpClient;

  final String baseUri;
  final String userAgentPackageName;
  final http.Client _client;

  RoutingState _state = const RoutingState();
  RoutingState get state => _state;

  bool _isPickingMode = false;
  bool get isPickingMode => _isPickingMode;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Enter point-picking mode. The map will capture the next tap.
  void startPicking() {
    _isPickingMode = true;
    notifyListeners();
  }

  /// Add a waypoint from a map tap. Automatically fetches when start+end set.
  Future<void> addWaypointFromTap(LatLng point) async {
    _isPickingMode = false;
    final updated = [..._state.waypoints, point];
    _state = _state.copyWith(waypoints: updated, clearError: true);
    notifyListeners();

    if (_state.hasEnd) {
      await _fetchRoute();
    }
  }

  /// Set the start point from a [PinData] — lets you route pin→pin.
  Future<void> setStartFromPin(PinData pin) async {
    final pt = LatLng(pin.latLong.latitude, pin.latLong.longitude);
    final updated = [pt, ..._state.waypoints.skip(1)];
    _state = _state.copyWith(waypoints: updated, clearResult: true, clearError: true);
    notifyListeners();
    if (_state.hasEnd) await _fetchRoute();
  }

  /// Set the end point from a [PinData].
  Future<void> setEndFromPin(PinData pin) async {
    final pt = LatLng(pin.latLong.latitude, pin.latLong.longitude);
    final List<LatLng> updated = _state.hasStart
        ? [_state.waypoints.first, pt]
        : [pt];
    _state = _state.copyWith(waypoints: updated, clearResult: true, clearError: true);
    notifyListeners();
    if (_state.hasEnd) await _fetchRoute();
  }

  /// Add an intermediate stop. Re-fetches the route.
  Future<void> addWaypoint(LatLng point) async {
    if (!_state.hasEnd) return;
    final end = _state.waypoints.last;
    final middle = _state.waypoints.sublist(1, _state.waypoints.length - 1);
    final updated = [_state.waypoints.first, ...middle, point, end];
    _state = _state.copyWith(waypoints: updated, clearResult: true);
    notifyListeners();
    await _fetchRoute();
  }

  /// Remove a waypoint by index and re-fetch.
  Future<void> removeWaypoint(int index) async {
    if (index < 0 || index >= _state.waypoints.length) return;
    final updated = [..._state.waypoints]..removeAt(index);
    _state = _state.copyWith(
        waypoints: updated, clearResult: true, clearError: true);
    notifyListeners();
    if (_state.hasEnd) await _fetchRoute();
  }

  /// Change travel mode and re-fetch if route exists.
  Future<void> setTravelMode(TravelMode mode) async {
    _state = _state.copyWith(
        travelMode: mode, clearResult: true, clearError: true);
    notifyListeners();
    if (_state.hasEnd) await _fetchRoute();
  }

  /// Clear everything.
  void clear() {
    _isPickingMode = false;
    _state = const RoutingState();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // OSRM fetch
  // ---------------------------------------------------------------------------

  Future<void> _fetchRoute() async {
    if (!_state.hasEnd) return;

    _state = _state.copyWith(isFetching: true, clearResult: true, clearError: true);
    notifyListeners();

    try {
      final coords = _state.waypoints
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');
      final profile = _state.travelMode.osrmProfile;
      final url =
          '$baseUri/route/v1/$profile/$coords?overview=full&geometries=geojson&steps=true&annotations=false';

      if (kDebugMode) print('[RoutingManager] GET $url');

      final response = await _client.get(
        Uri.parse(url),
        headers: {'User-Agent': userAgentPackageName},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('OSRM returned ${response.statusCode}');
      }

      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final code = decoded['code'] as String?;
      if (code != 'Ok') {
        throw Exception('OSRM code: $code — ${decoded['message'] ?? ''}');
      }

      final routes = decoded['routes'] as List<dynamic>;
      if (routes.isEmpty) throw Exception('No route found');

      final route = routes.first as Map<String, dynamic>;
      final distanceM = (route['distance'] as num).toDouble();
      final durationS = (route['duration'] as num).toDouble();

      // Decode GeoJSON polyline
      final coords2 = (route['geometry']['coordinates'] as List<dynamic>)
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();

      // Parse turn-by-turn steps from all legs
      final steps = <RouteStep>[];
      for (final leg in route['legs'] as List<dynamic>) {
        for (final step in leg['steps'] as List<dynamic>) {
          final maneuver =
              step['maneuver'] as Map<String, dynamic>? ?? {};
          final type = maneuver['type'] as String? ?? '';
          final modifier = maneuver['modifier'] as String? ?? '';
          final name = step['name'] as String? ?? '';
          final dist = (step['distance'] as num?)?.toDouble() ?? 0;
          steps.add(RouteStep(
            instruction: _buildInstruction(type, modifier, name),
            distanceMetres: dist,
            maneuverType: type,
          ));
        }
      }
      // Remove the trivial last "arrive" step if it has zero distance
      if (steps.isNotEmpty && steps.last.distanceMetres == 0) {
        steps.removeLast();
      }

      _state = _state.copyWith(
        isFetching: false,
        result: RouteResult(
          points: coords2,
          distanceMetres: distanceM,
          durationSeconds: durationS,
          steps: steps,
          travelMode: _state.travelMode,
        ),
      );
    } on TimeoutException {
      _state = _state.copyWith(
          isFetching: false, error: 'Request timed out. Check your connection.');
    } catch (e) {
      if (kDebugMode) print('[RoutingManager] error: $e');
      _state = _state.copyWith(
          isFetching: false, error: 'Could not find a route.');
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Instruction builder (mirrors Google/Apple style)
  // ---------------------------------------------------------------------------

  static String _buildInstruction(
      String type, String modifier, String name) {
    final road = name.isNotEmpty ? 'onto $name' : '';
    return switch (type) {
      'depart' => 'Head ${modifier.isNotEmpty ? modifier : 'forward'}${road.isNotEmpty ? ' $road' : ''}',
      'turn' => '${_capitalise(modifier)} turn${road.isNotEmpty ? ' $road' : ''}',
      'new name' => 'Continue${road.isNotEmpty ? ' $road' : ''}',
      'merge' => 'Merge${road.isNotEmpty ? ' $road' : ''}',
      'on ramp' => 'Take the ramp${road.isNotEmpty ? ' $road' : ''}',
      'off ramp' => 'Take the exit${road.isNotEmpty ? ' $road' : ''}',
      'fork' => 'Keep ${modifier.isNotEmpty ? modifier : 'straight'} at the fork',
      'end of road' => 'Turn ${modifier.isNotEmpty ? modifier : 'right'} at the end',
      'roundabout' => 'Enter the roundabout',
      'exit roundabout' => 'Exit the roundabout${road.isNotEmpty ? ' $road' : ''}',
      'arrive' => 'Arrive at your destination',
      _ => 'Continue${road.isNotEmpty ? ' $road' : ''}',
    };
  }

  static String _capitalise(String s) =>
      s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1)}';
}

/// Computes a bounding box around a set of [LatLng] points.
/// Used to auto-fit the map camera to the route.
LatLngBounds boundsFromPoints(List<LatLng> points) {
  assert(points.isNotEmpty);
  double minLat = points.first.latitude;
  double maxLat = points.first.latitude;
  double minLon = points.first.longitude;
  double maxLon = points.first.longitude;
  for (final p in points) {
    minLat = math.min(minLat, p.latitude);
    maxLat = math.max(maxLat, p.latitude);
    minLon = math.min(minLon, p.longitude);
    maxLon = math.max(maxLon, p.longitude);
  }
  return LatLngBounds(
    LatLng(minLat, minLon),
    LatLng(maxLat, maxLon),
  );
}
