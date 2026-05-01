import 'package:flutter/material.dart';
import 'package:osm_search_and_pick/models/lat_long.dart';

/// Represents a pin to be drawn on the map.
class PinData {
  /// The geographical coordinates of the pin.
  final LatLong latLong;

  /// The primary title or label of the pin.
  final String title;

  /// Additional details or subtitle of the pin.
  final String detail;

  /// The color of the default pin icon. Defaults to [Colors.red].
  /// Ignored if [child] is provided.
  final Color color;

  /// The icon to draw for the pin. Defaults to [Icons.location_on].
  /// Ignored if [child] is provided.
  final IconData icon;

  /// Optional fully custom widget that replaces the default pin icon entirely.
  /// If provided, [icon] and [color] are ignored.
  final Widget? child;

  /// Optional widget to display in a popup/overlay when the pin is tapped or selected.
  final Widget? detailWidget;

  /// Optional callback triggered when the pin is tapped.
  final void Function()? onTap;

  PinData({
    required this.latLong,
    this.title = '',
    this.detail = '',
    this.color = Colors.red,
    this.icon = Icons.location_on,
    this.child,
    this.detailWidget,
    this.onTap,
  });
}
