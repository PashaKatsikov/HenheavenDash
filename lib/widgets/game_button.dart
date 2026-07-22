import 'package:flutter/material.dart';
import '../core/audio/audio_manager.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum GameButtonStyle { primary, cta, success, outline }

/// The single primary button used across all screens.
///
/// Implements the interaction spec from the design brief: press = scale to
/// 0.95 with a deeper shadow, release = spring back to 1.0, gradient fill,
/// rounded corners, disabled = 50% opacity with interactions ignored.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = GameButtonStyle.primary,
    this.icon,
    this.width,
    this.height = 56,
    this.fontSize = 20,
  });

  final String label;
  final VoidCallback? onPressed;
  final GameButtonStyle style;
  final IconData? icon;
  final double? width;
  final double height;
  final double fontSize;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  Gradient get _gradient {
    switch (widget.style) {
      case GameButtonStyle.primary:
        return AppColors.primaryButtonGradient;
      case GameButtonStyle.cta:
        return AppColors.ctaButtonGradient;
      case GameButtonStyle.success:
        return AppColors.successButtonGradient;
      case GameButtonStyle.outline:
        return const LinearGradient(colors: [Colors.transparent, Colors.transparent]);
    }
  }

  Color get _borderColor {
    switch (widget.style) {
      case GameButtonStyle.primary:
        return AppColors.primaryDark;
      case GameButtonStyle.cta:
        return AppColors.ctaDark;
      case GameButtonStyle.success:
        return AppColors.successDark;
      case GameButtonStyle.outline:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOutline = widget.style == GameButtonStyle.outline;

    return Opacity(
      opacity: _enabled ? 1 : 0.5,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTap: _enabled
            ? () {
                AudioManager.instance.playClick();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              gradient: isOutline ? null : _gradient,
              color: isOutline ? Colors.white.withValues(alpha: 0.10) : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _borderColor,
                width: isOutline ? 2 : 1.4,
              ),
              boxShadow: _enabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: _pressed ? 0.15 : 0.30),
                        blurRadius: _pressed ? 4 : 10,
                        offset: Offset(0, _pressed ? 1 : 4),
                      ),
                      if (!isOutline)
                        BoxShadow(
                          color: _borderColor.withValues(alpha: 0.45),
                          blurRadius: 14,
                          spreadRadius: -4,
                        ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: isOutline ? AppColors.accent : Colors.white, size: widget.fontSize + 4),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    style: AppTextStyles.button.copyWith(
                      fontSize: widget.fontSize,
                      color: isOutline ? AppColors.accent : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
