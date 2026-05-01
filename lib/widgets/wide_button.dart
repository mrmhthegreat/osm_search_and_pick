import 'package:flutter/material.dart';

/// A full-width (or constrained) elevated button widget.
class WideButton extends StatelessWidget {
  const WideButton(
    this.text, {
    super.key,
    this.padding = 0.0,
    this.height = 45,
    required this.onPressed,
    this.backgroundColor = Colors.blue,
    this.foregroundColor = Colors.white,
    this.width = double.infinity,
    this.textStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    this.borderRadius = 5.0,
    this.elevation = 2.0,
  });

  final String text;
  final double padding;
  final double height;
  final double width;
  final Color backgroundColor;
  final TextStyle textStyle;
  final Color foregroundColor;
  final double borderRadius;
  final double elevation;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      height: height,
      // BUG FIX: cap at screen width on narrow screens, but also honour explicit
      // width on wider screens rather than always defaulting to screen width.
      width: screenWidth <= 500 ? screenWidth : width,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: elevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          onPressed: onPressed,
          child: Text(text, style: textStyle),
        ),
      ),
    );
  }
}
