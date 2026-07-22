import '../models/daily_reward.dart';
import '../persistence/save_service.dart';

/// Tracks the 7-day login-streak "daily drop": which day of the cycle the
/// player is on, and whether today's reward has already been claimed.
class DailyRewardService {
  DailyRewardService._();
  static final DailyRewardService instance = DailyRewardService._();

  int _streakDay = 1;
  bool _claimedToday = false;

  int get streakDay => _streakDay;
  bool get claimedToday => _claimedToday;
  bool get canClaim => !_claimedToday;
  DailyRewardDef get todayReward => DailyRewardCatalog.forDay(_streakDay);

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> init() async {
    final save = SaveService.instance;
    final today = _todayKey;
    final lastClaim = save.dailyRewardLastClaimDate;
    final lastStreak = save.dailyRewardStreak;

    if (lastClaim == null) {
      _streakDay = 1;
      _claimedToday = false;
      return;
    }

    if (lastClaim == today) {
      _streakDay = lastStreak.clamp(1, DailyRewardCatalog.cycleLength);
      _claimedToday = true;
      return;
    }

    final lastDate = DateTime.tryParse(lastClaim);
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final daysSince = lastDate == null ? 2 : todayDate.difference(DateTime(lastDate.year, lastDate.month, lastDate.day)).inDays;

    if (daysSince == 1) {
      // Consecutive day - advance the streak (wrapping after the 7th day).
      _streakDay = lastStreak >= DailyRewardCatalog.cycleLength ? 1 : lastStreak + 1;
    } else {
      // Missed a day (or first-ever run) - restart the streak.
      _streakDay = 1;
    }
    _claimedToday = false;
  }

  Future<DailyRewardDef> claim() async {
    final reward = DailyRewardCatalog.forDay(_streakDay);
    _claimedToday = true;
    await SaveService.instance.setDailyRewardStreak(_streakDay, _todayKey);
    return reward;
  }
}
