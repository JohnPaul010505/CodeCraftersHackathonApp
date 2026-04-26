// lib/utils/responsive_layout.dart
// Centralises all responsive breakpoints so every screen behaves identically.

import 'package:flutter/material.dart';

/// Breakpoints
const double kMobileBreak = 600;
const double kTabletBreak = 900;

/// Max content widths — content never stretches beyond these.
const double kContentMaxWidth = 860;
const double kFormMaxWidth = 560;
const double kCardMaxWidth = 480;

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < kMobileBreak;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= kMobileBreak && w < kTabletBreak;
  }

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= kMobileBreak;

  static double sideMargin(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w > kTabletBreak) return 0; // centred via ConstrainedBox
    if (w > kMobileBreak) return 24;
    return 16;
  }
}

/// Wrap any scrollable body with this to prevent content stretch on wide screens.
class CentredBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const CentredBody({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}