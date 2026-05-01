import 'package:flutter/material.dart';

/// Defines the style of the routing path and markers drawn on the map.
class RoutingStyle {
  /// The color of the main route path. Defaults to [Colors.blue].
  final Color routeColor;

  /// The stroke width of the main route path. Defaults to 5.0.
  final double routeWidth;

  /// The outer border color of the route path. Defaults to a semi-transparent blue.
  final Color borderColor;

  /// The thickness of the route outer border. Defaults to 2.0.
  final double borderStrokeWidth;

  /// Optional fully custom widget to use for the routing START marker.
  final Widget? startMarkerWidget;

  /// Optional fully custom widget to use for the routing END marker.
  final Widget? endMarkerWidget;

  /// Optional fully custom widget to use for the routing INTERMEDIATE stop markers.
  final Widget? intermediateMarkerWidget;

  const RoutingStyle({
    this.routeColor = Colors.blue,
    this.routeWidth = 5.0,
    this.borderColor = const Color(0x4D2196F3), // Colors.blue.withValues(alpha: 0.3)
    this.borderStrokeWidth = 2.0,
    this.startMarkerWidget,
    this.endMarkerWidget,
    this.intermediateMarkerWidget,
  });
}

/// Defines the style of the bottom sheet routing panel.
class RoutingPanelStyle {
  /// Background color of the routing panel.
  final Color? backgroundColor;

  /// Primary color used for icons, interactive chips, and key texts.
  final Color? primaryColor;

  /// General text color for instructions.
  final Color? textColor;

  /// Radius of the top corners of the bottom sheet. Defaults to 16.0.
  final double borderRadius;

  const RoutingPanelStyle({
    this.backgroundColor,
    this.primaryColor,
    this.textColor,
    this.borderRadius = 16.0,
  });
}
