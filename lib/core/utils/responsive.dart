import 'package:flutter/material.dart';

enum ResponsiveBreakpoint { compact, medium, expanded }

abstract final class Responsive {
  static const double referenceWidth = 390;

  static double scale(BuildContext context) =>
      (MediaQuery.sizeOf(context).width / referenceWidth).clamp(0.85, 1.6);

  static double sp(BuildContext context, double value) =>
      value * scale(context);

  static double space(BuildContext context, double value) =>
      value * scale(context);

  static ResponsiveBreakpoint breakpoint(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return ResponsiveBreakpoint.compact;
    if (width <= 1024) return ResponsiveBreakpoint.medium;
    return ResponsiveBreakpoint.expanded;
  }

  static bool isExpanded(BuildContext context) =>
      breakpoint(context) == ResponsiveBreakpoint.expanded;
}

class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    required this.child,
    this.mediumMaxWidth = 720,
    this.expandedMaxWidth = 960,
    this.alignment = Alignment.center,
    super.key,
  });

  final Widget child;
  final double mediumMaxWidth;
  final double expandedMaxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final breakpoint = Responsive.breakpoint(context);
    final maxWidth = switch (breakpoint) {
      ResponsiveBreakpoint.compact => double.infinity,
      ResponsiveBreakpoint.medium => mediumMaxWidth,
      ResponsiveBreakpoint.expanded => expandedMaxWidth,
    };
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          width: double.infinity,
          child: IconTheme.merge(
            data: IconThemeData(size: Responsive.sp(context, 24)),
            child: child,
          ),
        ),
      ),
    );
  }
}
