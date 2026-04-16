import 'package:flutter/widgets.dart';

/// Material 3 breakpoints, simplified.
class Breakpoints {
  /// Small phones, bottom navigation, stacked forms.
  static const double compact = 600;

  /// Large phones / small tablets. Two-column start.
  static const double medium = 840;

  /// Tablets & desktops. Nav rail + multi-pane.
  static const double expanded = 1200;

  static bool isCompact(BuildContext c) =>
      MediaQuery.of(c).size.width < compact;

  static bool isMedium(BuildContext c) {
    final w = MediaQuery.of(c).size.width;
    return w >= compact && w < expanded;
  }

  static bool isExpanded(BuildContext c) =>
      MediaQuery.of(c).size.width >= expanded;

  /// True when a side-by-side (two-column) layout should be used.
  static bool useTwoColumn(BuildContext c) =>
      MediaQuery.of(c).size.width >= medium;
}

/// Consistent spacing scale used across the app.
class Gaps {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const SizedBox hXs = SizedBox(height: xs);
  static const SizedBox hSm = SizedBox(height: sm);
  static const SizedBox hMd = SizedBox(height: md);
  static const SizedBox hLg = SizedBox(height: lg);
  static const SizedBox hXl = SizedBox(height: xl);

  static const SizedBox wXs = SizedBox(width: xs);
  static const SizedBox wSm = SizedBox(width: sm);
  static const SizedBox wMd = SizedBox(width: md);
  static const SizedBox wLg = SizedBox(width: lg);
}

/// Caps page content at a readable width on ultra-wide screens.
class PageShell extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  const PageShell({
    super.key,
    required this.child,
    this.maxWidth = 1100,
    this.padding = const EdgeInsets.all(Gaps.md),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
