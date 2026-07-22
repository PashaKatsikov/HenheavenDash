import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'components/chef_component.dart';
import 'components/particle_bursts.dart';
import 'components/floating_text_component.dart';
import 'level_session.dart';

/// The Flame game world for a level. It deliberately keeps a narrow scope:
/// the animated kitchen backdrop, the chef character (reacting to whatever
/// [LevelSession] is doing), and celebratory particle/floating-text effects.
/// All interactive UI (customer queue, station cards, HUD) is implemented
/// as Flutter widgets layered on top in [GameScreen] - Flutter's gesture
/// system is simply the right tool for tap-heavy management UI, while Flame
/// drives the character animation, particle systems and the core game loop
/// tick that advances [LevelSession].
class HenhavenGame extends FlameGame {
  HenhavenGame({required this.session, required this.backgroundAssetPath});

  final LevelSession session;
  final String backgroundAssetPath;

  ChefComponent? chef;
  SpriteComponent? stove;

  // The Flutter overlay (HUD + customer row) sits on top of this Flame
  // canvas and eats into the top of the screen, so the chef can't simply be
  // anchored to the *canvas* bottom - that ignores how much room the
  // overlay's cooking-station counter actually takes up and makes the chef
  // sink behind it, leaving only his head poking out. [GameScreen] reports
  // the real measured height of the counter/stations area here so the chef
  // can stand just above it, fully visible, on every device/screen size.
  double _kitchenAreaHeight = 0;
  static const double _kitchenBottomInset = 8; // matches GameScreen's outer Padding bottom inset.

  void setKitchenAreaHeight(double height) {
    if ((height - _kitchenAreaHeight).abs() < 0.5) return;
    _kitchenAreaHeight = height;
    _repositionChef();
  }

  void _repositionChef() {
    final c = chef;
    if (c == null || _kitchenAreaHeight <= 0) return;
    // Mirrors CounterBackdrop's own height formula so the chef's feet line
    // up exactly with the counter's top edge instead of drifting apart.
    final counterHeight = (_kitchenAreaHeight * 0.68).clamp(70.0, 190.0);
    final counterTopY = size.y - _kitchenBottomInset - counterHeight;

    // The kitchen background art is only visible *above* the HUD/customer
    // queue overlay - that overlay is a Flutter widget stacked on top of
    // this Flame canvas, so anything drawn above this line gets hidden
    // behind it. The chef and stove used to have fixed pixel sizes tuned
    // for one specific screen size, so on any shorter/narrower window
    // (a different phone aspect ratio, or just resizing a desktop debug
    // window) they'd poke up above this line and get their tops sliced off
    // by the overlay - which is exactly the "stove isn't fully visible"
    // bug. Scaling both to fit the room actually available between the
    // overlay and the counter guarantees they're always shown in full.
    final kitchenAreaTop = size.y - _kitchenBottomInset - _kitchenAreaHeight;
    final standRoom = (counterTopY - kitchenAreaTop - 8).clamp(64.0, 400.0);

    const chefAspect = 140 / 175;
    final chefHeight = standRoom.clamp(0.0, 175.0);
    c.size = Vector2(chefHeight * chefAspect, chefHeight);
    c.position = Vector2(size.x / 2, counterTopY);

    // The stove stands beside the chef on the same counter line, scaled
    // down together with the chef so it always stays fully on-screen -
    // never sliced by the right edge, and never sliced by the HUD above -
    // on every device.
    final s = stove;
    if (s != null) {
      const stoveAspect = 124 / 111;
      var stoveHeight = standRoom.clamp(0.0, 111.0);
      var stoveWidth = stoveHeight * stoveAspect;
      // On very narrow canvases the stove's natural width alone could
      // exceed the room next to the chef - shrink it further so the
      // horizontal clamp below always has a valid (low <= high) range and
      // the stove never gets pushed off (or squeezed past) either edge.
      final maxWidth = (size.x - 24).clamp(24.0, stoveWidth);
      if (stoveWidth > maxWidth) {
        stoveWidth = maxWidth;
        stoveHeight = stoveWidth / stoveAspect;
      }
      s.size = Vector2(stoveWidth, stoveHeight);
      final halfWidth = stoveWidth / 2;
      final lowX = halfWidth + 12;
      final highX = size.x - halfWidth - 12;
      // Guard against an invalid (low > high) clamp range on a canvas so
      // tiny the stove can't fit beside the chef at all - fall back to
      // dead-center rather than crashing.
      final stoveX = highX >= lowX ? (size.x / 2 + 132).clamp(lowX, highX) : size.x / 2;
      s.position = Vector2(stoveX, counterTopY + 4);
    }
  }

  @override
  Future<void> onLoad() async {
    final bgSprite = await loadSprite(backgroundAssetPath.replaceFirst('assets/images/', ''));
    final bg = SpriteComponent(sprite: bgSprite, size: size)
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();
    add(bg);

    chef = ChefComponent(
      position: Vector2(size.x / 2, size.y - 8),
      size: Vector2(140, 175),
    );
    add(chef!);

    // A freestanding stove prop next to the chef - the kitchen background
    // art only has an empty hearth alcove, so without this the chef reads
    // as cooking at nothing. Drawn as its own component (not baked into the
    // stretched background sprite) so it stays crisp and fully visible on
    // every screen size.
    final stoveSprite = await loadSprite('kitchen/kit_stove_cream.png');
    stove = SpriteComponent(sprite: stoveSprite, size: Vector2(124, 111))
      ..anchor = Anchor.bottomCenter;
    add(stove!);

    _repositionChef();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    for (final child in children.whereType<SpriteComponent>()) {
      if (child != chef && child != stove) {
        child.size = size;
      }
    }
    _repositionChef();
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
    if (chef != null) {
      chef!.syncWithSession(session.chefPose);
    }
  }

  void celebrate() => chef?.flashPose(ChefPose.happy, seconds: 1.4);

  void reactSad() => chef?.flashPose(ChefPose.shocked, seconds: 0.8);

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
