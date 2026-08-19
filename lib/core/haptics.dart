import 'package:flutter/services.dart';

import 'persistence/save_service.dart';

/// Tactile feedback for gameplay events, mirroring how [AudioManager] wraps
/// sound: one place that knows the intensity of every event and honours the
/// player's Settings toggle, so screens never call [HapticFeedback] directly.
///
/// Intensities are deliberately restrained - a serve happens several times a
/// minute, so it gets the lightest tick available, while the rare, dramatic
/// moments (a guest walking out, a level ending) are the only ones allowed to
/// thump.
class Haptics {
  Haptics._();
  static final Haptics instance = Haptics._();

  bool _enabled = true;
  bool get enabled => _enabled;

  void init() {
    _enabled = SaveService.instance.hapticsEnabled;
  }

  void setEnabled(bool value) {
    _enabled = value;
    SaveService.instance.setHapticsEnabled(value);
    if (value) HapticFeedback.selectionClick();
  }

  /// A correct ingredient tap - the most frequent event in the game.
  void tick() {
    if (_enabled) HapticFeedback.selectionClick();
  }

  /// Order served / dish ready.
  void success() {
    if (_enabled) HapticFeedback.lightImpact();
  }

  /// Wrong ingredient, or a combo milestone worth feeling.
  void bump() {
    if (_enabled) HapticFeedback.mediumImpact();
  }

  /// A guest storms off, or the run ends.
  void thud() {
    if (_enabled) HapticFeedback.heavyImpact();
  }
}
