import 'package:flame/game.dart' show GameWidget, Vector2;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/game_state.dart';
import '../../core/game_state_scope.dart';
import '../../core/haptics.dart';
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
  const GameScreen({super.key, required this.level}) : endless = false;

  /// Score-attack run on the hardest kitchen's difficulty, unlocked once
  /// every level has been cleared: no target orders or clock, it just ends
  /// after 3 mistakes.
  const GameScreen.endless({super.key})
      : level = 0,
        endless = true;

  final int level;
  final bool endless;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late LevelSession _session;
  late HenhavenGame _flameGame;
  final AudioManager _audio = AudioManager.instance;
  final Haptics _haptics = Haptics.instance;

  bool _paused = false;
  bool _showResult = false;
  bool _resultProcessed = false;
  bool _sessionReady = false;
  bool _cookingLoopOn = false;
  LevelResult? _levelResult;
  EndlessResult? _endlessResult;

  /// Captured when the run starts, because clearing the level moves the
  /// progression forward and would make a first win look like a replay by the
  /// time the result overlay is built.
  bool _wasReplay = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _audio.playBgm();
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
    _wasReplay = !widget.endless && state.isReplay(widget.level);
    // Endless mode always runs on the hardest kitchen's difficulty (the last
    // level) since there's no single "level number" for it.
    final config = widget.endless ? LevelCatalog.getLevel(LevelCatalog.totalLevels) : LevelCatalog.getLevel(widget.level);
    final upgrades = state.upgradeLevels;

    final cookSpeedLvl = upgrades['cook_speed'] ?? 0;
    final extraStationLvl = upgrades['extra_station'] ?? 0;
    final patienceLvl = upgrades['patience_boost'] ?? 0;
    final tipLvl = upgrades['tip_boost'] ?? 0;
    // Tip-bought perks.
    final hourglassLvl = upgrades['golden_hourglass'] ?? 0;
    final pantryLvl = upgrades['tidy_pantry'] ?? 0;
    final steadyLvl = upgrades['steady_hands'] ?? 0;

    // Recipes used in a level are exactly the ones already unlocked in save
    // state - the single source of truth also shown as "unlocked" in the
    // Recipe Book, so the two can never drift out of sync.
    final unlockedIds = state.unlockedRecipeIds;
    final availableRecipes = RecipeCatalog.all.where((r) => unlockedIds.contains(r.id)).toList();

    _session = LevelSession(
      config: config,
      stationCount: 2 + extraStationLvl,
      cookSpeedMultiplier: (1 - cookSpeedLvl * 0.07).clamp(0.45, 1.0),
      patienceBonusSeconds: patienceLvl * 2.0,
      tipMultiplierUpgrade: 1 + tipLvl * 0.08,
      availableRecipes: availableRecipes,
      bonusTimeSeconds: hourglassLvl * 6.0,
      maxDecoys: (2 - pantryLvl).clamp(0, 2),
      comboShields: steadyLvl,
      endless: widget.endless,
    );
    _flameGame = HenhavenGame(session: _session, backgroundAssetPath: config.kitchen.backgroundPath);
  }

  void _onSessionTick() {
    final events = _session.drainEvents();
    for (final event in events) {
      switch (event.type) {
        case SessionEventType.ingredientCorrect:
          _audio.playDragItem();
          _haptics.tick();
          break;
        case SessionEventType.ingredientWrong:
          _audio.playIncorrect();
          _haptics.bump();
          break;
        case SessionEventType.cookingStarted:
          _audio.playCookingStart();
          break;
        case SessionEventType.cookingComplete:
          _audio.playCookingComplete();
          _haptics.tick();
          break;
        case SessionEventType.served:
          _audio.playServeSuccess();
          _haptics.success();
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
          _haptics.bump();
          _flameGame.burstStarsAt(Vector2(_flameGame.size.x / 2, _flameGame.size.y - 260));
          break;
        case SessionEventType.customerLeftAngry:
          _audio.playWarning();
          _haptics.thud();
          _flameGame.reactSad();
          break;
        case SessionEventType.levelWon:
          _audio.playWin();
          _haptics.success();
          _flameGame.celebrate();
          break;
        case SessionEventType.levelLost:
          _audio.playLose();
          _haptics.thud();
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

    if (widget.endless) {
      final result = await state.completeEndlessRun(
        score: _session.score,
        coinsEarned: _session.coinsEarned,
        tipsEarned: _session.tipsEarned,
        ordersServedThisRun: _session.ordersServed,
        dishesCookedThisRun: _session.dishesCooked,
      );
      // The combo streak (a daily task metric) is about *skill during the
      // run*, not about clearing the level - it counts here too, regardless
      // of how the run ended.
      await state.reportComboStreak(_session.bestCombo);
      if (mounted) {
        _endlessResult = result;
        _scheduleRebuild();
      }
      return;
    }

    // Stars reflect the score actually earned this run, even if the player
    // didn't manage to serve every order before time ran out - a near-miss
    // no longer flattens straight to zero stars.
    final stars = _session.starsEarned();
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
    // Combo streak counts toward the daily task regardless of whether the
    // level itself was won - a player who strings together a great combo
    // but runs out of time still deserves credit for it.
    await state.reportComboStreak(_session.bestCombo);
    if (_session.won) {
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
      _endlessResult = null;
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

  /// Mirrors what [GameState.completeLevel] actually banks, so the result
  /// overlay never flashes the full amount before the reduced replay payout
  /// lands.
  double get _payoutRate => _wasReplay ? GameState.replayPayoutRate : 1.0;

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

  /// Builds the counter backdrop with the cooking-station cards sitting on
  /// it, sizing each square card to the room actually available so the
  /// ingredient grid can never be clipped, and centering the row when it
  /// fits (falling back to horizontal scroll only once enough stations are
  /// unlocked that they genuinely overflow the width).
  Widget _buildStations(BoxConstraints c) {
    final n = _session.stations.length;
    const hPad = 12.0; // 6 left + 6 right per card (the Padding below)
    // Card HEIGHT is capped by the (scarce) vertical room, minus the small
    // per-card padding so the body can never be taller than the area and get
    // its top clipped. Card WIDTH then spreads into the (plentiful) spare
    // horizontal room - a wide ~1.9:1 landscape rectangle - so the ingredient
    // buttons on the right get a big, readable canvas.
    final cardHeight = (c.maxHeight - 14).clamp(96.0, 230.0);
    // The widest a card (incl. its own padding) may be so that n of them can
    // never exceed the available width - the -2 is a rounding safety margin
    // that guarantees (cardWidth + hPad) * n is strictly < maxWidth, killing
    // the "RIGHT OVERFLOWED" stripe.
    final maxCardWidth = (c.maxWidth - 2) / n - hPad;
    var cardWidth = cardHeight * 1.9;
    if (cardWidth > maxCardWidth) cardWidth = maxCardWidth;
    if (cardWidth < 96) cardWidth = 96;

    final stationsRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final station in _session.stations)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: StationCardWidget(
              station: station,
              width: cardWidth,
              height: cardHeight,
              onTapIngredient: (ingredientId) => _session.tapIngredient(station.id, ingredientId),
              onServe: () => _session.serve(station.id),
            ),
          ),
      ],
    );

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Anchoring the counter+stations to the bottom (rather than centered)
        // leaves the pretty kitchen background visible above them.
        const Positioned.fill(child: CounterBackdrop()),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: (cardWidth + hPad) * n <= c.maxWidth
              // FittedBox(scaleDown) is a hard guarantee against the overflow
              // stripe: even if sub-pixel rounding (made likely by the global
              // tablet scale factor) nudges the row a hair past the available
              // width, it silently scales down a fraction instead of painting
              // the yellow "RIGHT OVERFLOWED" bar. When it fits (the norm) no
              // scaling happens and it just centers.
              ? Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: stationsRow,
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: stationsRow,
                ),
        ),
      ],
    );
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
                    GameHud(session: _session, onPause: _togglePause, endless: widget.endless),
                    const SizedBox(height: 8),
                    // The whole play area below the HUD is split by available
                    // height (not fixed pixels): the guest counter on top and
                    // the cooking stations below each take a share of whatever
                    // room the device actually has. This is what keeps guests
                    // big and the station cards fully un-clipped on a short
                    // phone-in-landscape, while everything scales up nicely to
                    // fill a tall iPad canvas.
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final total = constraints.maxHeight;
                          // Guests get ~half the room (clamped so they're never
                          // cramped nor absurdly huge); stations take the rest.
                          final queueHeight = (total * 0.5).clamp(150.0, 320.0);
                          return Column(
                            children: [
                              // Guests line up in a horizontal row right at the
                              // counter (matching the reference game).
                              CustomerQueueWidget(
                                session: _session,
                                height: queueHeight,
                                onTapCustomer: (customer) {
                                  _session.assignCustomer(customer);
                                },
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, stationConstraints) {
                                    // Tell the Flame layer exactly how tall this
                                    // counter/stations area is so the chef
                                    // character (drawn on the canvas behind it)
                                    // can stand right above the counter instead
                                    // of guessing from the full screen height and
                                    // ending up hidden behind it.
                                    _flameGame.setKitchenAreaHeight(stationConstraints.maxHeight);
                                    return _buildStations(stationConstraints);
                                  },
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
                onToggleSfx: (v) => setState(() => _audio.setSfxEnabled(v)),
              ),
            if (_showResult)
              LevelResultOverlay(
                won: _session.won,
                score: _session.score,
                coinsEarned: (_session.coinsEarned * _payoutRate).round(),
                tipsEarned: (_session.tipsEarned * _payoutRate).round(),
                replayPayout: _wasReplay,
                stars: widget.endless ? 0 : _session.starsEarned(),
                newlyUnlockedRecipes: _levelResult?.newlyUnlockedRecipes ?? const [],
                endless: widget.endless,
                isNewBest: _endlessResult?.isNewBest ?? false,
                bestScore: _endlessResult?.bestScore ?? 0,
                onRetry: _restart,
                onNext: (!widget.endless && _session.won && widget.level < LevelCatalog.totalLevels)
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
