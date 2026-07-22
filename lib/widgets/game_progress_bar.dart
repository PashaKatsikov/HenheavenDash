import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Horizontal gradient progress bar with a glow around the filled portion
/// and smooth (never jumpy) animated fill, used by the splash screen,
/// level timer, and XP/upgrade bars.
class GameProgressBar extends StatelessWidget {
  const GameProgressBar({
    super.key,
    required this.value,
    this.height = 12,
    this.gradient,
    this.backgroundColor,
    this.duration = const Duration(milliseconds: 260),
  });

  final double value; // 0..1
  final double height;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
          ),
          child: Stack(
            children: [
              AnimatedFractionallySizedBox(
                duration: duration,
                curve: Curves.easeOut,
                widthFactor: clamped,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient ?? AppColors.goldProgressGradient,
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.75),
                        blurRadius: height * 1.2,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// FractionallySizedBox that animates [widthFactor]/[heightFactor] changes.
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  const AnimatedFractionallySizedBox({
    super.key,
    required this.widthFactor,
    required this.heightFactor,
    required this.child,
    super.duration = const Duration(milliseconds: 260),
    super.curve = Curves.easeOut,
  });

  final double widthFactor;
  final double heightFactor;
  final Widget child;

  @override
  ImplicitlyAnimatedWidgetState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;
  Tween<double>? _heightFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor,
      (value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
    _heightFactor = visitor(
      _heightFactor,
      widget.heightFactor,
      (value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: _widthFactor?.evaluate(animation) ?? widget.widthFactor,
      heightFactor: _heightFactor?.evaluate(animation) ?? widget.heightFactor,
      child: widget.child,
    );
  }
}
