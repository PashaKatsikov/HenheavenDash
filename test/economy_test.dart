import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:henhaven_dash/core/game_state.dart';
import 'package:henhaven_dash/core/models/level_config.dart';
import 'package:henhaven_dash/core/models/recipe.dart';
import 'package:henhaven_dash/game/level_session.dart';

/// Drives the session forward in small steps, like the Flame game loop does.
void advance(LevelSession session, double seconds) {
  for (var t = 0.0; t < seconds; t += 0.05) {
    session.update(0.05);
  }
}

LevelSession buildSession({
  double bonusTimeSeconds = 0,
  int maxDecoys = 2,
  int comboShields = 0,
  Recipe? recipe,
}) {
  final only = recipe ?? RecipeCatalog.all.first;
  return LevelSession(
    config: LevelCatalog.getLevel(1),
    stationCount: 2,
    cookSpeedMultiplier: 1,
    patienceBonusSeconds: 0,
    tipMultiplierUpgrade: 1,
    availableRecipes: [only],
    bonusTimeSeconds: bonusTimeSeconds,
    maxDecoys: maxDecoys,
    comboShields: comboShields,
  );
}

/// Runs the clock until somebody is waiting at the counter, then walks them
/// out by draining their patience.
void loseAGuest(LevelSession session) {
  for (var i = 0; session.queue.isEmpty && i < 400; i++) {
    session.update(0.05);
  }
  expect(session.queue, isNotEmpty, reason: 'no guest ever arrived');
  session.queue.first.patienceRemaining = 0.01;
  advance(session, 0.2);
}

/// Takes the first waiting guest all the way through to a served order.
void serveOneOrder(LevelSession session) {
  advance(session, 0.1);
  final customer = session.queue.first;
  expect(session.assignCustomer(customer), isTrue);
  final station = session.stations[customer.assignedStationId!];
  for (final id in customer.recipe.ingredientIds) {
    session.tapIngredient(station.id, id);
  }
  advance(session, customer.recipe.cookSeconds + 1);
  expect(station.state, StationState.ready);
  session.serve(station.id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('level perks', () {
    test('Golden Hourglass adds its seconds to the level clock', () {
      final plain = buildSession()..start();
      final perked = buildSession(bonusTimeSeconds: 18)..start();

      expect(perked.timeRemaining, plain.timeRemaining + 18);
    });

    test('Tidy Pantry clears the decoys off the prep shelf', () {
      final recipe = RecipeCatalog.all.first;

      final cluttered = buildSession(recipe: recipe);
      advance(cluttered, 0.1);
      cluttered.assignCustomer(cluttered.queue.first);
      expect(
        cluttered.stations[0].shelfIngredientIds.length,
        greaterThan(recipe.ingredientIds.length),
      );

      final tidy = buildSession(maxDecoys: 0, recipe: recipe);
      advance(tidy, 0.1);
      tidy.assignCustomer(tidy.queue.first);
      expect(tidy.stations[0].shelfIngredientIds.length, recipe.ingredientIds.length);
    });

    test('Steady Hands lets the combo survive exactly one lost guest', () {
      final session = buildSession(comboShields: 1);
      serveOneOrder(session);
      expect(session.combo, 1);

      // First walk-out is absorbed by the shield.
      loseAGuest(session);
      expect(session.combo, 1);
      expect(session.comboShieldsLeft, 0);

      // The next one breaks the streak as usual.
      loseAGuest(session);
      expect(session.combo, 0);
    });

    test('a lost guest still breaks the combo without the perk', () {
      final session = buildSession();
      serveOneOrder(session);
      expect(session.combo, 1);

      loseAGuest(session);
      expect(session.combo, 0);
    });
  });

  // One scenario rather than separate tests: the wallet and the level
  // progression are persisted in a process-wide singleton, so these
  // assertions only mean anything in order.
  test('wallet: replays pay less, and perks are bought with tips', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = GameState();
    await state.init();

    Future<LevelResult> finishLevelOne() => state.completeLevel(
          level: 1,
          won: true,
          score: 900,
          coinsEarned: 100,
          tipsEarned: 40,
          ordersServedThisRun: 9,
          dishesCookedThisRun: 9,
          stars: 3,
          noMistakes: true,
        );

    final firstClear = await finishLevelOne();
    expect(firstClear.wasReplay, isFalse);
    expect(firstClear.coinsAwarded, 100);
    expect(state.coins, 100);
    expect(state.tips, 40);

    final replay = await finishLevelOne();
    expect(replay.wasReplay, isTrue);
    expect(replay.coinsAwarded, 30);
    expect(replay.tipsAwarded, 12);
    expect(state.coins, 130);
    expect(state.tips, 52);

    // A tip-priced perk must come out of the tip jar only.
    expect(await state.purchaseUpgrade('golden_hourglass'), isTrue);
    expect(state.upgradeLevelFor('golden_hourglass'), 1);
    expect(state.tips, 12);
    expect(state.coins, 130);

    // 12 tips is not enough for the second level of the perk.
    expect(state.canAffordUpgrade('golden_hourglass'), isFalse);
    expect(await state.purchaseUpgrade('golden_hourglass'), isFalse);
    expect(state.upgradeLevelFor('golden_hourglass'), 1);

    // Coin-priced upgrades keep working off the coin purse.
    expect(await state.purchaseUpgrade('cook_speed'), isTrue);
    expect(state.coins, 70);
    expect(state.tips, 12);
  });
}
