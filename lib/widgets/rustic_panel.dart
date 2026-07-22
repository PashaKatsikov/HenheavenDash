import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A solid, hand-crafted "carved wood" card - the opaque counterpart to
/// [GlassPanel]. Used anywhere a blurred glass rectangle would read as
/// generic/AI-glossy (station cards, customer counter cards, menu tiles):
/// a wood-grain gradient fill, a bright top bevel like a routed edge, small
/// corner "peg" rivets, and a slightly thicker painted border instead of a
/// glassmorphism blur. Reads as a physical object sitting on the counter.
class RusticPanel extends StatelessWidget {
  const RusticPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 16,
    this.borderColor,
    this.gradient,
    this.pegs = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;
  final Gradient? gradient;
  final bool pegs;

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? AppColors.accent.withValues(alpha: 0.55);
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.woodPanelGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Routed top-edge highlight, like a carved wood bevel catching light.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withValues(alpha: 0.02), Colors.white.withValues(alpha: 0.22)],
                  ),
                ),
              ),
            ),
            if (pegs) ..._corners(borderRadius),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }

  List<Widget> _corners(double r) {
    Widget peg(Alignment alignment, double dx, double dy) => Align(
          alignment: alignment,
          child: Padding(
            padding: EdgeInsets.only(left: dx, right: dx, top: dy, bottom: dy),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.3),
                boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.12), offset: const Offset(0.5, 0.5))],
              ),
            ),
          ),
        );
    return [
      peg(Alignment.topLeft, 5, 5),
      peg(Alignment.topRight, 5, 5),
      peg(Alignment.bottomLeft, 5, 5),
      peg(Alignment.bottomRight, 5, 5),
    ];
  }
}
