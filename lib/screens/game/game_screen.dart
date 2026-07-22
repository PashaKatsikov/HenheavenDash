import 'package:flame/game.dart' show GameWidget, Vector2;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/game_state.dart';
import '../../core/game_state_scope.dart';
import '../../core/models/level_config.dart';
import '../../core/models/recipe.dart';
import '../../game/henhaven_game.dart';
import '../../game/level_session.dart';
import '../../game/overlays/counter_backdrop.dart';
import '../../game/overlays/customer_queue_widget.dart';
import '../../game/overlays/game_hud.dart';
import '../../game/overlays/level_result_overlay.dart';
import '../../game/overlays/pause_overlay.dart';
import '../../game/overlays/station_card_widget.dart';
import '../menu/main_menu_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final int level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late LevelSession _session;
  late HenhavenGame _flameGame;
  final AudioManager _audio = AudioManager.instance;

  bool _paused = false;
  bool _showResult = false;
  bool _resultProcessed = false;
  bool _sessionReady = false;
  bool _cookingLoopOn = false;
  LevelResult? _levelResult;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sessionReady) {
      _sessionReady = true;
      _buildSession();
      _session.addListener(_onSessionTick);
    }
  }

  void _buildSession() {
    final state = GameStateScope.of(context);
    final config = LevelCatalog.getLevel(widget.level);
    final upgrades = state.upgradeLevels;

    final cookSpeedLvl = upgrades['cook_speed'] ?? 0;
    final serviceSpeedLvl = upgrades['service_speed'] ?? 0;
    final extraStationLvl = upgrades['extra_station'] ?? 0;
    final patienceLvl = upgrades['patience_boost'] ?? 0;
    final tipLvl = upgrades['tip_boost'] ?? 0;

    _session = LevelSession(
      config: config,
      stationCount: 2 + extraStationLvl,
      cookSpeedMultiplier: (1 - cookSpeedLvl * 0.07).clamp(0.45, 1.0),
      serviceSpeedMultiplier: (1 - serviceSpeedLvl * 0.05).clamp(0.5, 1.0),
      patienceBonusSeconds: patienceLvl * 2.0,
      tipMultiplierUpgrade: 1 + tipLvl * 0.08,
      availableRecipes: RecipeCatalog.unlockedAt(widget.level),
    );
    _flameGame = HenhavenGame(session: _session, backgroundAssetPath: config.kitchen.backgroundPath);
  }

  void _onSessionTick() {
    final events = _session.drainEvents();
    for (final event in events) {
      switch (event.type) {
        case SessionEventType.ingredientCorrect:
          _audio.playDragItem();
          break;
        case SessionEventType.ingredientWrong:
          _audio.playIncorrect();
          break;
        case SessionEventType.cookingStarted:
          _audio.playCookingStart();
          break;
        case SessionEventType.cookingComplete:
          _audio.playCookingComplete();
          break;
        case SessionEventType.served:
          _audio.playServeSuccess();
          if (event.tipsEarned > 0) _audio.playTipsReceived();
          _flameGame.burstCoinsAt(Vector2(_flameGame.size.x / 2, _flameGame.size.y - 210));
          _flameGame.floatText(
            '+${event.coinsEarned}',
            Vector2(_flameGame.size.x / 2, _flameGame.size.y - 240),
            colorArgb: 0xFFFFC94A,
          );
          break;
        case SessionEventType.comboMilestone:
          _audio.playHappyCustomer();
          _flameGame.burstStarsAt(Vector2(_flameGame.size.x / 2, _flameGame.size.y - 260));
          break;
        case SessionEventType.customerLeftAngry:
          _audio.playWarning();
          _flameGame.reactSad();
          break;
        case SessionEventType.levelWon:
          _audio.playWin();
          _flameGame.celebrate();
          break;
        case SessionEventType.levelLost:
          _audio.playLose();
          break;
        case SessionEventType.customerSpawned:
          break;
      }
    }

    // Edge-triggered: only touch the native audio player when cooking
    // actually starts/stops, never on every single per-frame session tick.
    final anyCooking = !_session.finished && _session.stations.any((s) => s.state == StationState.cooking);
    if (anyCooking != _cookingLoopOn) {
      _cookingLoopOn = anyCooking;
      if (anyCooking) {
        _audio.startCookingLoop();
      } else {
        _audio.stopCookingLoop();
      }
    }

    final justFinished = _session.finished && !_showResult;
    if (justFinished) {
      _showResult = true;
    }

    // LevelSession.notifyListeners() fires from inside Flame's per-frame game
    // loop tick, which runs in the same pipeline phase Flutter uses to
    // build/layout/paint the current frame. Calling setState() synchronously
    // from here throws "setState() or markNeedsBuild() called during build" -
    // and since this listener fires on every single frame, an unguarded call
    // pins the CPU in an exception-throwing loop until the app hangs and gets
    // killed (this is what caused the freeze-then-crash on level start).
    // Deferring the rebuild to a post-frame callback keeps the UI in sync
    // while always running in a phase where rebuilding is safe.
    _scheduleRebuild();

    if (justFinished) {
      _finalizeLevel();
    }
  }

  void _scheduleRebuild() {
    if (!mounted) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _finalizeLevel() async {
    if (_resultProcessed) return;
    _resultProcessed = true;
    final state = GameStateScope.of(context);
    final stars = _session.won ? _session.starsEarned() : 0;
    final result = await state.completeLevel(
      level: widget.level,
      won: _session.won,
      score: _session.score,
      coinsEarned: _session.coinsEarned,
      tipsEarned: _session.tipsEarned,
      ordersServedThisRun: _session.ordersServed,
      dishesCookedThisRun: _session.dishesCooked,
      stars: stars,
      noMistakes: _session.missedCustomers == 0,
    );
    if (_session.won) {
      await state.reportComboStreak(_session.bestCombo);
      _audio.playCoinCollect();
      if (result.newlyUnlockedRecipes.isNotEmpty) {
        _audio.playLevelComplete();
      }
    }
    if (mounted) {
      _levelResult = result;
      _scheduleRebuild();
    }
  }

  void _restart() {
    _cookingLoopOn = false;
    _audio.stopCookingLoop();
    setState(() {
      _showResult = false;
      _resultProcessed = false;
      _levelResult = null;
      _session.removeListener(_onSessionTick);
      _buildSession();
      _session.addListener(_onSessionTick);
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _cookingLoopOn = false;
    _audio.stopCookingLoop();
    _session.removeListener(_onSessionTick);
    _session.dispose();
    super.dispose();
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _cookingLoopOn = false;
      _audio.stopCookingLoop();
      _flameGame.pauseSession();
    } else {
      _flameGame.resumeSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!_showResult) _togglePause();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GameWidget(game: _flameGame),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                child: Column(
                  children: [
                    GameHud(session: _session, onPause: _togglePause),
                    const SizedBox(height: 8),
                    // Guests line up in a horizontal row right at the counter
                    // (matching the reference game) instead of a side panel.
                    CustomerQueueWidget(
                      session: _session,
                      onTapCustomer: (customer) {
                        _session.assignCustomer(customer);
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Tell the Flame layer exactly how tall this
                          // counter/stations area is so the chef character
                          // (drawn on the canvas behind it) can stand right
                          // above the counter instead of guessing based on
                          // the full screen height and ending up hidden
                          // behind it with only his head showing.
                          _flameGame.setKitchenAreaHeight(constraints.maxHeight);
                          return Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              // Keeping the counter+stations anchored to the
                              // bottom (rather than centered) leaves the
                              // pretty kitchen background visible above
                              // instead of the stations covering the middle
                              // of the screen.
                              const Positioned.fill(child: CounterBackdrop()),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (final station in _session.stations)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
                                          child: StationCardWidget(
                                            station: station,
                                            onTapIngredient: (ingredientId) =>
                                                _session.tapIngredient(station.id, ingredientId),
                                            onServe: () => _session.serve(station.id),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_paused && !_showResult)
              PauseOverlay(
                onResume: _togglePause,
                onRestart: () {
                  _togglePause();
                  _restart();
                },
                onExit: () => Navigator.of(context).popUntil((r) => r.isFirst),
                sfxEnabled: _audio.sfxEnabled,
                musicEnabled: _audio.musicEnabled,
                onToggleSfx: (v) => setState(() => _audio.setSfxEnabled(v)),
                onToggleMusic: (v) => setState(() => _audio.setMusicEnabled(v)),
              ),
            if (_showResult)
              LevelResultOverlay(
                won: _session.won,
                score: _session.score,
                coinsEarned: _session.coinsEarned,
                tipsEarned: _session.tipsEarned,
                stars: _session.won ? _session.starsEarned() : 0,
                newlyUnlockedRecipes: _levelResult?.newlyUnlockedRecipes ?? const [],
                onRetry: _restart,
                onNext: (_session.won && widget.level < LevelCatalog.totalLevels)
                    ? () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => GameScreen(level: widget.level + 1)),
                        );
                      }
                    : null,
                onExit: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainMenuScreen()),
                  (route) => false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
