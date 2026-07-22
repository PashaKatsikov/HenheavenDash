import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/models/customer.dart';
import '../core/models/ingredient.dart';
import '../core/models/level_config.dart';
import '../core/models/recipe.dart';

enum StationState { idle, prepping, cooking, ready }

enum ChefPose { idle, prepping, cooking, serving, happy, shocked }

class ActiveCustomer {
  ActiveCustomer({required this.id, required this.type, required this.recipe, required this.patienceTotal})
      : patienceRemaining = patienceTotal;

  final int id;
  final CustomerType type;
  final Recipe recipe;
  final double patienceTotal;
  double patienceRemaining;
  int? assignedStationId;

  double get patienceFraction => (patienceRemaining / patienceTotal).clamp(0, 1);
}

class Station {
  Station({required this.id});

  final int id;
  StationState state = StationState.idle;
  ActiveCustomer? customer;
  final Set<String> preparedIngredients = {};
  List<String> shelfIngredientIds = [];
  double cookProgress = 0; // 0..1
  double cookDuration = 1;

  bool get isFree => state == StationState.idle;
}

/// Result of a discrete gameplay event, surfaced to the UI layer so it can
/// trigger sound effects / floating text / particles without the session
/// needing to know anything about Flame or Flutter.
class SessionEvent {
  const SessionEvent(this.type, {this.stationId, this.coinsEarned = 0, this.tipsEarned = 0});
  final SessionEventType type;
  final int? stationId;
  final int coinsEarned;
  final int tipsEarned;
}

enum SessionEventType {
  customerSpawned,
  ingredientCorrect,
  ingredientWrong,
  cookingStarted,
  cookingComplete,
  served,
  customerLeftAngry,
  comboMilestone,
  levelWon,
  levelLost,
}

/// Pure game-logic controller for a single level run. Knows nothing about
/// Flame or Flutter widgets - it is driven by [update] every tick and
/// exposes state + a stream of [SessionEvent]s for the presentation layer.
class LevelSession extends ChangeNotifier {
  LevelSession({
    required this.config,
    required int stationCount,
    required this.cookSpeedMultiplier,
    required this.patienceBonusSeconds,
    required this.tipMultiplierUpgrade,
    required List<Recipe> availableRecipes,
    this.endless = false,
  })  : availableRecipes = availableRecipes.isNotEmpty ? availableRecipes : [RecipeCatalog.all.first],
        stations = List.generate(stationCount, (i) => Station(id: i)),
        _rng = Random() {
    // The very first guest is already waiting the instant the level starts -
    // 0 means the first _updateSpawning tick spawns them immediately, so the
    // player isn't idly watching an empty counter burn precious level time
    // before anyone even walks in. Every subsequent spawn uses the normal
    // randomised interval.
    _timeUntilSpawn = 0;
  }

  final LevelConfig config;
  final double cookSpeedMultiplier; // <1 = faster cooking
  final double patienceBonusSeconds;
  final double tipMultiplierUpgrade;
  final List<Recipe> availableRecipes;
  final List<Station> stations;
  final Random _rng;

  /// Endless mode: no time limit and no target order count - the run just
  /// keeps going (with the hardest level's difficulty) until [mistakes]
  /// reaches [_maxMistakes], purely for a high score instead of a pass/fail.
  final bool endless;
  static const int _maxMistakes = 3;
  int mistakes = 0;

  final List<ActiveCustomer> queue = [];
  final List<SessionEvent> _pendingEvents = [];

  int _nextCustomerId = 0;
  double _timeUntilSpawn = 0;
  double _elapsed = 0;
  double _timeRemaining = 0;

  int ordersServed = 0;
  int dishesCooked = 0;
  int missedCustomers = 0;
  int combo = 0;
  int bestCombo = 0;
  int score = 0;
  int coinsEarned = 0;
  int tipsEarned = 0;

  bool finished = false;
  bool won = false;

  static const int _maxMisses = 5;

  ChefPose _pose = ChefPose.idle;
  ChefPose get chefPose => _pose;

  double get timeRemaining => _timeRemaining;
  double get elapsedSeconds => _elapsed;
  double get levelProgress => (ordersServed / config.targetOrders).clamp(0, 1);
  int get mistakesRemaining => (_maxMistakes - mistakes).clamp(0, _maxMistakes);

  void _scheduleNextSpawn() {
    _timeUntilSpawn = config.spawnIntervalSeconds * (0.75 + _rng.nextDouble() * 0.5);
  }

  bool get _initialized => _timeRemaining > 0 || _elapsed > 0;

  /// Call once from the owning widget after construction, once the level
  /// timer should actually start counting down.
  void start() {
    _timeRemaining = config.levelTimeSeconds;
  }

  List<SessionEvent> drainEvents() {
    final events = List<SessionEvent>.from(_pendingEvents);
    _pendingEvents.clear();
    return events;
  }

  void _emit(SessionEvent event) => _pendingEvents.add(event);

  void update(double dt) {
    if (finished) return;
    if (!_initialized) start();

    _elapsed += dt;
    _timeRemaining -= dt;

    _updateSpawning(dt);
    _updatePatience(dt);
    _updateCooking(dt);
    _updateChefPose();

    if (endless) {
      // No clock, no order target - the run only ends once too many
      // mistakes (wrong ingredients / customers lost) pile up.
      if (mistakes >= _maxMistakes) _finish(won: false);
    } else if (_timeRemaining <= 0 && ordersServed < config.targetOrders) {
      _finish(won: false);
    } else if (ordersServed >= config.targetOrders) {
      _finish(won: true);
    } else if (missedCustomers >= _maxMisses) {
      _finish(won: false);
    }

    notifyListeners();
  }

  void _updateSpawning(double dt) {
    if (queue.length >= config.maxQueueSize) return;
    _timeUntilSpawn -= dt;
    if (_timeUntilSpawn <= 0) {
      _spawnCustomer();
      _scheduleNextSpawn();
    }
  }

  void _spawnCustomer() {
    final type = CustomerCatalog.all[_rng.nextInt(CustomerCatalog.all.length)];
    final recipe = availableRecipes[_rng.nextInt(availableRecipes.length)];
    final patience = (config.basePatienceSeconds + patienceBonusSeconds) * type.patienceMultiplier;
    final customer = ActiveCustomer(
      id: _nextCustomerId++,
      type: type,
      recipe: recipe,
      patienceTotal: patience,
    );
    queue.add(customer);
    _emit(const SessionEvent(SessionEventType.customerSpawned));
  }

  void _updatePatience(double dt) {
    for (final c in List<ActiveCustomer>.from(queue)) {
      c.patienceRemaining -= dt;
      if (c.patienceRemaining <= 0) {
        _customerLeavesAngry(c);
      }
    }
  }

  void _customerLeavesAngry(ActiveCustomer c) {
    queue.remove(c);
    if (c.assignedStationId != null) {
      final station = stations[c.assignedStationId!];
      station.customer = null;
      station.state = StationState.idle;
      station.preparedIngredients.clear();
      station.shelfIngredientIds = [];
      station.cookProgress = 0;
    }
    missedCustomers++;
    combo = 0;
    if (endless) mistakes++;
    _emit(const SessionEvent(SessionEventType.customerLeftAngry));
  }

  void _updateCooking(double dt) {
    for (final station in stations) {
      if (station.state == StationState.cooking) {
        station.cookProgress += dt / max(0.4, station.cookDuration * cookSpeedMultiplier);
        if (station.cookProgress >= 1) {
          station.cookProgress = 1;
          station.state = StationState.ready;
          dishesCooked++;
          _emit(SessionEvent(SessionEventType.cookingComplete, stationId: station.id));
        }
      }
    }
  }

  void _updateChefPose() {
    if (stations.any((s) => s.state == StationState.cooking)) {
      _pose = ChefPose.cooking;
    } else if (stations.any((s) => s.state == StationState.prepping && s.preparedIngredients.isNotEmpty)) {
      _pose = ChefPose.prepping;
    } else {
      _pose = ChefPose.idle;
    }
  }

  // ---- Player actions ---------------------------------------------------

  bool assignCustomer(ActiveCustomer customer) {
    final station = stations.firstWhere((s) => s.isFree, orElse: () => stations.first);
    if (!station.isFree || customer.assignedStationId != null) return false;
    station.state = StationState.prepping;
    station.customer = customer;
    station.cookDuration = customer.recipe.cookSeconds;
    station.preparedIngredients.clear();
    station.shelfIngredientIds = _buildShelf(customer.recipe);
    customer.assignedStationId = station.id;
    notifyListeners();
    return true;
  }

  /// Required ingredients + a couple of random decoys, shuffled, so prepping
  /// is a small "spot the right ingredient" challenge rather than a trivial
  /// tap-everything action. Capped at [_maxShelfSlots] total so the station
  /// card's ingredient grid always has a fixed, known layout to fit - recipes
  /// with 4 required ingredients get fewer (or zero) decoys rather than
  /// overflowing the card.
  static const int _maxShelfSlots = 5;

  List<String> _buildShelf(Recipe recipe) {
    final required = List<String>.from(recipe.ingredientIds);
    final decoyPool = IngredientCatalog.all
        .map((e) => e.id)
        .where((id) => !required.contains(id))
        .toList()
      ..shuffle(_rng);
    final decoyCount = (_maxShelfSlots - required.length).clamp(0, min(2, decoyPool.length)).toInt();
    final shelf = [...required, ...decoyPool.take(decoyCount)];
    shelf.shuffle(_rng);
    return shelf;
  }

  void tapIngredient(int stationId, String ingredientId) {
    final station = stations[stationId];
    if (station.state != StationState.prepping || station.customer == null) return;
    final required = station.customer!.recipe.ingredientIds.toSet();
    if (!required.contains(ingredientId) || station.preparedIngredients.contains(ingredientId)) {
      // Only a genuinely *wrong* (decoy) tap counts as a mistake in endless
      // mode - re-tapping an ingredient already prepared is harmless noise,
      // not a mistake, so it shouldn't cost a life.
      if (endless && !station.preparedIngredients.contains(ingredientId)) mistakes++;
      _emit(SessionEvent(SessionEventType.ingredientWrong, stationId: stationId));
      notifyListeners();
      return;
    }
    station.preparedIngredients.add(ingredientId);
    _emit(SessionEvent(SessionEventType.ingredientCorrect, stationId: stationId));
    if (station.preparedIngredients.length == required.length) {
      station.state = StationState.cooking;
      station.cookProgress = 0;
      _emit(SessionEvent(SessionEventType.cookingStarted, stationId: stationId));
    }
    notifyListeners();
  }

  void serve(int stationId) {
    final station = stations[stationId];
    if (station.state != StationState.ready || station.customer == null) return;
    final customer = station.customer!;

    final speedFactor = customer.patienceFraction; // 1 = served instantly, ->0 = just in time
    final baseCoins = customer.recipe.coinReward;
    final comboBonus = 1 + (combo.clamp(0, 25) * 0.02);
    final coins = (baseCoins * comboBonus).round();
    final tip = (baseCoins * 0.4 * speedFactor * customer.type.tipMultiplier * tipMultiplierUpgrade).round();

    coinsEarned += coins;
    tipsEarned += tip;
    ordersServed++;
    combo++;
    if (combo > bestCombo) bestCombo = combo;
    score += 100 + (speedFactor * 50).round() + combo * 5;

    queue.remove(customer);
    station.customer = null;
    station.state = StationState.idle;
    station.preparedIngredients.clear();
    station.shelfIngredientIds = [];
    station.cookProgress = 0;

    _emit(SessionEvent(SessionEventType.served, stationId: stationId, coinsEarned: coins, tipsEarned: tip));
    if (combo > 0 && combo % 5 == 0) {
      _emit(const SessionEvent(SessionEventType.comboMilestone));
    }
    notifyListeners();
  }

  void _finish({required bool won}) {
    finished = true;
    this.won = won;
    _emit(SessionEvent(won ? SessionEventType.levelWon : SessionEventType.levelLost));
  }

  int starsEarned() {
    var stars = 0;
    for (final threshold in config.starThresholds) {
      if (score >= threshold) stars++;
    }
    return stars;
  }
}
