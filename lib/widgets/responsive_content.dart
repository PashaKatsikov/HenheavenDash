import 'package:flutter/material.dart';

/// Caps how wide a scrollable list/grid of cards is allowed to grow and
/// centers it horizontally.
///
/// Every menu screen in this game was originally laid out edge-to-edge,
/// which reads fine on a phone's narrow landscape canvas but turns into
/// oddly long, half-empty rows once the very same widget tree is stretched
/// across an iPad's much wider landscape screen (a settings row's icon and
/// label end up pinned to the left edge with a switch stranded far away on
/// the right, etc.). Wrapping the scrollable body in this widget keeps the
/// content at a comfortable, phone-like reading width and centers it in the
/// extra space on bigger screens - the background art still stretches
/// full-bleed behind it (nothing here touches that), so small phones render
/// pixel-identical to before while iPad simply gets tasteful margins instead
/// of stretched-out UI.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 760,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
