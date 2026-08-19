import 'dart:async';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import '../persistence/save_service.dart';

/// Central sound manager for every SFX event in the game, plus the looping
/// background music.
///
/// Music and SFX are independent: each has its own persisted toggle in
/// Settings, and turning music back on resumes the track the app last asked
/// for rather than waiting for the next screen change.
class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  /// The single cozy loop that plays across the whole white part of the app.
  static const String menuTheme = 'bgm_cozy_farm.m4a';

  bool _initialized = false;
  bool sfxEnabled = true;
  bool musicEnabled = true;

  /// Track currently coming out of the speaker.
  String? _currentBgm;

  /// Track the app *wants* playing, even while music is switched off - this
  /// is what gets started again when the player flips the toggle back on.
  String? _requestedBgm;

  // Looping "sizzle" that plays while any station is actively cooking. Kept as
  // a single shared player so multiple cooking stations don't stack the sound.
  //
  // [_cookingLoopGeneration] guards against a race where startCookingLoop()'s
  // async FlameAudio.loop() call resolves *after* a stopCookingLoop() already
  // ran (e.g. the player paused right as cooking began): without this guard,
  // the just-created native looping player would never be referenced again
  // and would keep looping forever in the background, leaking a native audio
  // player every time the race is hit. Each stop bumps the generation so any
  // in-flight start recognizes it was superseded and disposes itself instead.
  AudioPlayer? _cookingLoopPlayer;
  bool _cookingLoopActive = false;
  int _cookingLoopGeneration = 0;

  static const _sfx = <String, String>{
    'click': 'click.mp3',
    'coinCollect': 'coin_collect.mp3',
    'cookingComplete': 'cooking_complete.mp3',
    'cookingLoop': 'cooking_loop.mp3',
    'dragItem': 'drag_item.mp3',
    'lose': 'lose.mp3',
    'happyCustomer': 'happy_customer.mp3',
    'incorrect': 'incorrect.mp3',
    'levelComplete': 'level_complete.mp3',
    'tipsReceived': 'tips_received.mp3',
    'cookingStart': 'cooking_start.mp3',
    'serveSuccess': 'serve_success.mp3',
    'unlock': 'unlock.mp3',
    'upgrade': 'upgrade.mp3',
    'warning': 'warning.mp3',
    'win': 'win.mp3',
  };

  Future<void> init() async {
    if (_initialized) return;
    sfxEnabled = SaveService.instance.sfxEnabled;
    musicEnabled = SaveService.instance.musicEnabled;
    try {
      FlameAudio.audioCache.prefix = 'assets/sounds/';
      await FlameAudio.audioCache.loadAll(_sfx.values.toList());
    } catch (e) {
      debugPrint('AudioManager: failed to preload SFX: $e');
    }
    try {
      // Registers the lifecycle observer that pauses/resumes the music when
      // the app leaves and returns to the foreground.
      await FlameAudio.bgm.initialize();
    } catch (e) {
      debugPrint('AudioManager: failed to initialize BGM: $e');
    }
    _initialized = true;
  }

  Future<void> _play(String key, {double volume = 1}) async {
    if (!sfxEnabled) return;
    final file = _sfx[key];
    if (file == null) return;
    try {
      await FlameAudio.play(file, volume: volume);
    } catch (e) {
      debugPrint('AudioManager: could not play $key: $e');
    }
  }

  void playClick() => _play('click', volume: 0.7);
  void playCoinCollect() => _play('coinCollect');
  void playCookingComplete() => _play('cookingComplete');
  void playCookingLoop() => _play('cookingLoop', volume: 0.6);
  void playDragItem() => _play('dragItem', volume: 0.5);
  void playLose() => _play('lose');
  void playHappyCustomer() => _play('happyCustomer');
  void playIncorrect() => _play('incorrect');
  void playLevelComplete() => _play('levelComplete');
  void playTipsReceived() => _play('tipsReceived');
  void playCookingStart() => _play('cookingStart', volume: 0.7);
  void playServeSuccess() => _play('serveSuccess');
  void playUnlock() => _play('unlock');
  void playUpgrade() => _play('upgrade');
  void playWarning() => _play('warning', volume: 0.8);
  void playWin() => _play('win');

  /// Starts the looping cooking sizzle if it isn't already running. Safe to
  /// call repeatedly - it no-ops while the loop is already active.
  Future<void> startCookingLoop() async {
    if (!sfxEnabled || _cookingLoopActive) return;
    _cookingLoopActive = true;
    final generation = ++_cookingLoopGeneration;
    try {
      final player = await FlameAudio.loop(_sfx['cookingLoop']!, volume: 0.4);
      if (generation != _cookingLoopGeneration) {
        // A stop (or a newer start) happened while this was in flight -
        // this player is stale, so shut it down immediately instead of
        // leaving it as an untracked, forever-looping native player.
        unawaited(player.stop());
        unawaited(player.dispose());
        return;
      }
      _cookingLoopPlayer = player;
    } catch (e) {
      debugPrint('AudioManager: could not start cooking loop: $e');
      _cookingLoopActive = false;
    }
  }

  /// Stops the cooking sizzle. Safe to call even if it was never started.
  Future<void> stopCookingLoop() async {
    _cookingLoopGeneration++; // invalidate any in-flight startCookingLoop()
    if (!_cookingLoopActive && _cookingLoopPlayer == null) return;
    _cookingLoopActive = false;
    final player = _cookingLoopPlayer;
    _cookingLoopPlayer = null;
    try {
      await player?.stop();
      await player?.dispose();
    } catch (_) {}
  }

  /// Starts (or keeps) the looping background track. Calling it repeatedly
  /// with the same file is a no-op, so screens can safely ask for music in
  /// `initState` without restarting the loop on every navigation.
  Future<void> playBgm([String assetFile = menuTheme]) async {
    _requestedBgm = assetFile;
    if (!musicEnabled || _currentBgm == assetFile) return;
    try {
      await FlameAudio.bgm.play(assetFile, volume: _bgmVolume);
      _currentBgm = assetFile;
    } catch (e) {
      debugPrint('AudioManager: could not play BGM ($assetFile): $e');
      _currentBgm = null;
    }
  }

  /// Sits well below the SFX so serving, coins and timers stay legible.
  static const double _bgmVolume = 0.32;

  void stopBgm() {
    _currentBgm = null;
    try {
      FlameAudio.bgm.stop();
    } catch (_) {}
  }

  void setSfxEnabled(bool value) {
    sfxEnabled = value;
    SaveService.instance.setSfxEnabled(value);
    if (!value) {
      stopCookingLoop();
    }
  }

  void setMusicEnabled(bool value) {
    musicEnabled = value;
    SaveService.instance.setMusicEnabled(value);
    if (value) {
      playBgm(_requestedBgm ?? menuTheme);
    } else {
      stopBgm();
    }
  }
}
