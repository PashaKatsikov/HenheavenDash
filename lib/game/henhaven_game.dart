import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'components/particle_bursts.dart';
import 'components/floating_text_component.dart';
import 'level_session.dart';

/// The Flame game world for a level. It deliberately keeps a narrow scope:
/// the animated kitchen backdrop and celebratory particle/floating-text
/// effects. All interactive UI (customer queue, station cards, HUD) is
/// implemented as Flutter widgets layered on top in [GameScreen] - Flutter's
/// gesture system is simply the right tool for tap-heavy management UI, while
/// Flame drives the particle systems and the core game loop tick that
/// advances [LevelSession].
///
/// NOTE: there used to be an animated chef character standing at the counter
/// here, but there was no spot on screen where it read well (it kept getting
/// clipped by the counter/overlay), so it was removed on every platform. The
/// chef art still lives in assets/ - it's just intentionally no longer drawn.
class HenhavenGame extends FlameGame {
  HenhavenGame({required this.session, required this.backgroundAssetPath});

  final LevelSession session;
  final String backgroundAssetPath;

  /// Kept as a no-op so [GameScreen] can still report the counter height
  /// without needing to know the chef was removed - nothing consumes it now.
  void setKitchenAreaHeight(double height) {}

  @override
  Future<void> onLoad() async {
    final bgSprite = await loadSprite(backgroundAssetPath.replaceFirst('assets/images/', ''));
    final bg = SpriteComponent(sprite: bgSprite, size: size)
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();
    add(bg);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    for (final child in children.whereType<SpriteComponent>()) {
      child.size = size;
    }
  }

  bool _running = true;

  void pauseSession() => _running = false;
  void resumeSession() => _running = true;

  @override
  void update(double dt) {
    super.update(dt);
    if (_running) {
      session.update(dt);
    }
  }

  // Chef reaction hooks are now no-ops (the character was removed) but remain
  // so the GameScreen event handling doesn't need to special-case it.
  void celebrate() {}

  void reactSad() {}

  void burstCoinsAt(Vector2 screenPosition) => ParticleBursts.coinBurst(this, screenPosition);

  void burstStarsAt(Vector2 screenPosition) => ParticleBursts.starBurst(this, screenPosition);

  void floatText(String text, Vector2 screenPosition, {required int colorArgb}) {
    add(
      FloatingTextComponent(
        text: text,
        position: screenPosition,
        color: Color(colorArgb),
      ),
    );
  }
}
