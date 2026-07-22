import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;
import '../level_session.dart';

/// The chef character rendered on the Flame canvas. Swaps between the ten
/// pre-rendered chicken-chef poses depending on what the kitchen is doing,
/// with a gentle idle "breathing" bob so it never looks static.
class ChefComponent extends SpriteComponent with HasGameReference {
  ChefComponent({required Vector2 position, required Vector2 size})
      : super(position: position, size: size, anchor: Anchor.bottomCenter);

  ChefPose? _lastPose;
  double _oneShotTimer = 0;

  static const Map<ChefPose, String> _poseAssets = {
    ChefPose.idle: 'chef/chef_idle.png',
    ChefPose.prepping: 'chef/chef_holding_spoon.png',
    ChefPose.cooking: 'chef/chef_holding_pan.png',
    ChefPose.serving: 'chef/chef_serving_plate.png',
    ChefPose.happy: 'chef/chef_celebrating.png',
    ChefPose.shocked: 'chef/chef_shocked.png',
  };

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(_poseAssets[ChefPose.idle]!);
    add(
      SequenceEffect(
        [
          MoveByEffect(Vector2(0, -6), EffectController(duration: 0.9, curve: Curves.easeInOut)),
          MoveByEffect(Vector2(0, 6), EffectController(duration: 0.9, curve: Curves.easeInOut)),
        ],
        infinite: true,
      ),
    );
  }

  Future<void> _setPose(ChefPose pose) async {
    if (_lastPose == pose) return;
    _lastPose = pose;
    sprite = await game.loadSprite(_poseAssets[pose] ?? _poseAssets[ChefPose.idle]!);
  }

  /// Briefly shows [pose] (e.g. a happy or shocked reaction) before falling
  /// back to whatever the session's steady-state pose is.
  void flashPose(ChefPose pose, {double seconds = 0.9}) {
    _oneShotTimer = seconds;
    _setPose(pose);
  }

  void syncWithSession(ChefPose sessionPose) {
    if (_oneShotTimer > 0) return;
    _setPose(sessionPose);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_oneShotTimer > 0) {
      _oneShotTimer -= dt;
      if (_oneShotTimer <= 0) {
        _lastPose = null; // force resync on next syncWithSession call
      }
    }
  }
}
