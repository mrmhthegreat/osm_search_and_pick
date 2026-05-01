import 'package:flutter/material.dart';
import 'package:osm_search_and_pick/models/lat_long.dart';

/// Represents a zone to be drawn on the map as a circle.
class ZoneData {
  final LatLong center;
  final double radius;
  final Color color;
  final Color borderColor;
  final double borderStrokeWidth;
  final bool useFillColor;
  final Widget? detailWidget;
  final String detail;
  final String title;
  final void Function()? onTap;

  ZoneData({
    required this.center,
    required this.radius,
    this.color = const Color(0x332196F3),
    this.borderColor = const Color(0xFF2196F3),
    this.borderStrokeWidth = 0.0,
    this.useFillColor = true,
    this.detailWidget,
    this.detail = '',
    this.title = '',
    this.onTap,
  });
}
