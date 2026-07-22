import 'package:flutter/foundation.dart';
import 'models/daily_reward.dart';
import 'models/daily_task.dart';
import 'models/recipe.dart';
import 'models/upgrade.dart';
import 'persistence/save_service.dart';
import 'services/daily_reward_service.dart';
import 'services/daily_tasks_service.dart';

/// App-wide reactive game state. Screens listen to this via [ChangeNotifier]
/// (wired through a simple InheritedNotifier in main.dart) so coins/tips/
/// upgrades/recipes stay in sync everywhere without a heavier state
/// management dependency.
class GameState extends ChangeNotifier {
  final SaveService _save = SaveService.instance;
  final DailyTasksService _dailies = DailyTasksService.instance;
  final DailyRewardService _dailyReward = DailyRewardService.instance;

  int get coins => _save.coins;
  int get tips => _save.tips;
  int get bestScore => _save.bestScore;
  int get ordersServed => _save.ordersServed;
  int get dishesCooked => _save.dishesCooked;
  int get highestLevelUnlocked => _save.highestLevelUnlocked;
  Set<String> get unlockedRecipeIds => _save.unlockedRecipeIds;
  Map<String, int> get upgradeLevels => _save.upgradeLevels;
  Map<int, int> get starsPerLevel => _save.starsPerLevel;
  List<ActiveDailyTask> get dailyTasks => _dailies.tasks;
  int get bestEndlessScore => _save.bestEndlessScore;

  int get dailyRewardStreakDay => _dailyReward.streakDay;
  bool get canClaimDailyReward => _dailyReward.canClaim;
  DailyRewardDef get todaysDailyReward => _dailyReward.todayReward;

  Future<void> init() async {
    await _save.init();
    await _dailies.init();
    await _dailyReward.init();
    for (final r in RecipeCatalog.all) {
      if (r.unlockLevel == 1) await _save.unlockRecipe(r.id);
    }
    notifyListeners();
  }

  Future<DailyRewardDef> claimDailyReward() async {
    final reward = await _dailyReward.claim();
    await _save.addCoins(reward.coins);
    if (reward.tips > 0) await _save.addTips(reward.tips);
    notifyListeners();
    return reward;
  }

  int upgradeLevelFor(String id) => upgradeLevels[id] ?? 0;

  bool canAffordUpgrade(String id) {
    final def = UpgradeCatalog.byId(id);
    final lvl = upgradeLevelFor(id);
    if (lvl >= def.maxLevel) return false;
    return coins >= def.costForLevel(lvl);
  }

  Future<bool> purchaseUpgrade(String id) async {
    final def = UpgradeCatalog.byId(id);
    final lvl = upgradeLevelFor(id);
    if (lvl >= def.maxLevel) return false;
    final cost = def.costForLevel(lvl);
    if (coins < cost) return false;
    await _save.spendCoins(cost);
    await _save.setUpgradeLevel(id, lvl + 1);
    notifyListeners();
    return true;
  }

  /// Called when a level finishes. Applies rewards, unlocks the next level
  /// and any recipes tied to it, updates stats & dailies, then notifies UI.
  Future<LevelResult> completeLevel({
    required int level,
    required bool won,
    required int score,
    required int coinsEarned,
    required int tipsEarned,
    required int ordersServedThisRun,
    required int dishesCookedThisRun,
    required int stars,
    required bool noMistakes,
  }) async {
    await _save.addCoins(coinsEarned);
    await _save.addTips(tipsEarned);
    await _save.addOrdersServed(ordersServedThisRun);
    await _save.addDishesCooked(dishesCookedThisRun);
    await _save.reportScore(score);
    // Stars reflect the score the player actually earned, so even a run cut
    // short by the clock (or a 5th missed customer) still shows fair credit
    // for how well it went instead of always flattening to zero.
    await _save.setStarsForLevel(level, stars);

    final newlyUnlocked = <Recipe>[];
    if (won) {
      await _save.unlockLevel(level + 1);
      for (final r in RecipeCatalog.newlyUnlockedAt(level + 1)) {
        if (!_save.unlockedRecipeIds.contains(r.id)) {
          await _save.unlockRecipe(r.id);
          newlyUnlocked.add(r);
        }
      }
    }

    await _dailies.reportProgress(DailyTaskMetric.ordersServed, ordersServedThisRun);
    await _dailies.reportProgress(DailyTaskMetric.dishesCooked, dishesCookedThisRun);
    await _dailies.reportProgress(DailyTaskMetric.coinsEarned, coinsEarned + tipsEarned);
    if (won) await _dailies.reportLevelCleanFinish(noMistakes);

    notifyListeners();
    return LevelResult(newlyUnlockedRecipes: newlyUnlocked);
  }

  /// Called when an Endless run ends (3 mistakes made). There's no level to
  /// unlock or recipes to award - just rewards banked, stats/dailies updated,
  /// and the persisted high score bumped if this run beat it.
  Future<EndlessResult> completeEndlessRun({
    required int score,
    required int coinsEarned,
    required int tipsEarned,
    required int ordersServedThisRun,
    required int dishesCookedThisRun,
  }) async {
    await _save.addCoins(coinsEarned);
    await _save.addTips(tipsEarned);
    await _save.addOrdersServed(ordersServedThisRun);
    await _save.addDishesCooked(dishesCookedThisRun);
    await _save.reportScore(score);
    final isNewBest = score > _save.bestEndlessScore;
    await _save.reportEndlessScore(score);

    await _dailies.reportProgress(DailyTaskMetric.ordersServed, ordersServedThisRun);
    await _dailies.reportProgress(DailyTaskMetric.dishesCooked, dishesCookedThisRun);
    await _dailies.reportProgress(DailyTaskMetric.coinsEarned, coinsEarned + tipsEarned);

    notifyListeners();
    return EndlessResult(isNewBest: isNewBest, bestScore: _save.bestEndlessScore);
  }

  Future<void> reportComboStreak(int streak) async {
    await _dailies.reportMaxProgress(DailyTaskMetric.comboStreak, streak);
  }

  Future<int?> claimDailyTask(String taskId) async {
    final reward = await _dailies.claim(taskId);
    if (reward != null) {
      await _save.addCoins(reward);
      notifyListeners();
    }
    return reward;
  }
}

class LevelResult {
  LevelResult({required this.newlyUnlockedRecipes});
  final List<Recipe> newlyUnlockedRecipes;
}

class EndlessResult {
  EndlessResult({required this.isNewBest, required this.bestScore});
  final bool isNewBest;
  final int bestScore;
}
