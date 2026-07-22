import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin, typed wrapper around [SharedPreferences] used for every bit of
/// persisted state in the game: currencies, progress, unlocks, settings and
/// daily tasks. Kept centralized so the rest of the app never touches
/// SharedPreferences keys directly.
class SaveService {
  SaveService._();
  static final SaveService instance = SaveService._();

  late SharedPreferences _prefs;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
  }

  // ---- Keys ----------------------------------------------------------
  static const _kCoins = 'coins';
  static const _kTips = 'tips';
  static const _kBestScore = 'best_score';
  static const _kOrdersServed = 'orders_served';
  static const _kDishesCooked = 'dishes_cooked';
  static const _kHighestLevel = 'highest_level_unlocked';
  static const _kUnlockedRecipes = 'unlocked_recipes';
  static const _kUpgradeLevels = 'upgrade_levels';
  static const _kSfxEnabled = 'sfx_enabled';
  static const _kMusicEnabled = 'music_enabled';
  static const _kDailyTasksState = 'daily_tasks_state';
  static const _kDailyTasksDate = 'daily_tasks_date';
  static const _kStarsPerLevel = 'stars_per_level';
  static const _kOwnedDecor = 'owned_decor';
  static const _kDailyRewardStreak = 'daily_reward_streak';
  static const _kDailyRewardLastClaim = 'daily_reward_last_claim';

  // ---- Currencies ------------------------------------------------------
  int get coins => _prefs.getInt(_kCoins) ?? 0;
  int get tips => _prefs.getInt(_kTips) ?? 0;

  Future<void> addCoins(int amount) async => _prefs.setInt(_kCoins, coins + amount);
  Future<void> spendCoins(int amount) async => _prefs.setInt(_kCoins, (coins - amount).clamp(0, 1 << 31));
  Future<void> addTips(int amount) async => _prefs.setInt(_kTips, tips + amount);

  // ---- Stats -------------------------------------------------------------
  int get bestScore => _prefs.getInt(_kBestScore) ?? 0;
  Future<void> reportScore(int score) async {
    if (score > bestScore) await _prefs.setInt(_kBestScore, score);
  }

  int get ordersServed => _prefs.getInt(_kOrdersServed) ?? 0;
  Future<void> addOrdersServed(int amount) async =>
      _prefs.setInt(_kOrdersServed, ordersServed + amount);

  int get dishesCooked => _prefs.getInt(_kDishesCooked) ?? 0;
  Future<void> addDishesCooked(int amount) async =>
      _prefs.setInt(_kDishesCooked, dishesCooked + amount);

  // ---- Progression -----------------------------------------------------
  int get highestLevelUnlocked => _prefs.getInt(_kHighestLevel) ?? 1;
  Future<void> unlockLevel(int level) async {
    if (level > highestLevelUnlocked) await _prefs.setInt(_kHighestLevel, level);
  }

  Set<String> get unlockedRecipeIds =>
      (_prefs.getStringList(_kUnlockedRecipes) ?? const []).toSet();
  Future<void> unlockRecipe(String id) async {
    final set = unlockedRecipeIds..add(id);
    await _prefs.setStringList(_kUnlockedRecipes, set.toList());
  }

  Map<String, int> get upgradeLevels {
    final raw = _prefs.getString(_kUpgradeLevels);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
  }

  Future<void> setUpgradeLevel(String id, int level) async {
    final map = upgradeLevels;
    map[id] = level;
    await _prefs.setString(_kUpgradeLevels, jsonEncode(map));
  }

  Map<int, int> get starsPerLevel {
    final raw = _prefs.getString(_kStarsPerLevel);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> setStarsForLevel(int level, int stars) async {
    final map = starsPerLevel;
    if (stars > (map[level] ?? 0)) {
      map[level] = stars;
      await _prefs.setString(
        _kStarsPerLevel,
        jsonEncode(map.map((k, v) => MapEntry(k.toString(), v))),
      );
    }
  }

  // ---- Settings ----------------------------------------------------------
  bool get sfxEnabled => _prefs.getBool(_kSfxEnabled) ?? true;
  Future<void> setSfxEnabled(bool value) async => _prefs.setBool(_kSfxEnabled, value);

  bool get musicEnabled => _prefs.getBool(_kMusicEnabled) ?? true;
  Future<void> setMusicEnabled(bool value) async => _prefs.setBool(_kMusicEnabled, value);

  // ---- Daily tasks ---------------------------------------------------------
  String? get dailyTasksDate => _prefs.getString(_kDailyTasksDate);
  Future<void> setDailyTasksDate(String isoDate) async =>
      _prefs.setString(_kDailyTasksDate, isoDate);

  Map<String, int> get dailyTasksProgress {
    final raw = _prefs.getString(_kDailyTasksState);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
  }

  Future<void> setDailyTasksProgress(Map<String, int> progress) async =>
      _prefs.setString(_kDailyTasksState, jsonEncode(progress));

  Future<void> resetDailyTasks() async {
    await _prefs.remove(_kDailyTasksState);
  }

  // ---- Decor collection ---------------------------------------------------
  Set<String> get ownedDecorIds => (_prefs.getStringList(_kOwnedDecor) ?? const []).toSet();
  Future<void> unlockDecor(String id) async {
    final set = ownedDecorIds..add(id);
    await _prefs.setStringList(_kOwnedDecor, set.toList());
  }

  // ---- Daily login reward --------------------------------------------------
  int get dailyRewardStreak => _prefs.getInt(_kDailyRewardStreak) ?? 0;
  String? get dailyRewardLastClaimDate => _prefs.getString(_kDailyRewardLastClaim);

  Future<void> setDailyRewardStreak(int streak, String isoDate) async {
    await _prefs.setInt(_kDailyRewardStreak, streak);
    await _prefs.setString(_kDailyRewardLastClaim, isoDate);
  }
}
