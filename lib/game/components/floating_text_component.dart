import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// A short-lived "+10", "+Tip!", "Missed!" label that floats upward and
/// fades out - used for score/coin/mistake feedback above stations.
///
/// Note: [TextComponent] is not an `OpacityProvider`, so an [OpacityEffect]
/// cannot be applied to it directly (that throws "Can only apply this effect
/// to OpacityProvider"). Instead we fade manually by re-tinting the text color
/// over the component's short lifetime, and keep the upward motion as a proper
/// [MoveByEffect] (position effects work on any [PositionComponent]).
class FloatingTextComponent extends TextComponent {
  FloatingTextComponent({
    required String text,
    required Vector2 position,
    Color color = Colors.white,
  })  : _baseColor = color,
        super(
          text: text,
          position: position,
          anchor: Anchor.center,
          textRenderer: _buildRenderer(color, 1),
        );

  final Color _baseColor;

  static const double _life = 1.05;
  static const double _fadeStart = 0.15;
  double _elapsed = 0;

  static TextPaint _buildRenderer(Color color, double opacity) {
    return TextPaint(
      style: TextStyle(
        fontFamily: 'Baloo2',
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: color.withValues(alpha: color.a * opacity),
        shadows: [
          Shadow(
            color: Colors.black54.withValues(alpha: 0.5 * opacity),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    add(
      MoveByEffect(
        Vector2(0, -46),
        EffectController(duration: 0.9, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    final fade = ((_elapsed - _fadeStart) / (_life - _fadeStart)).clamp(0.0, 1.0);
    textRenderer = _buildRenderer(_baseColor, 1 - fade);

    if (_elapsed >= _life) {
      removeFromParent();
    }
  }
}
