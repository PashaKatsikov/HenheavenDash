class DailyRewardDef {
  const DailyRewardDef({required this.day, required this.coins, required this.tips, required this.iconPath});

  final int day;
  final int coins;
  final int tips;
  final String iconPath;
}

/// A 7-day repeating login-streak calendar ("daily drop"). Playing on
/// consecutive days climbs the ladder to bigger rewards; missing a day
/// resets the streak back to day 1. Purely a coin/tip faucet - no gameplay
/// gating - so it never blocks anyone who skips a day.
class DailyRewardCatalog {
  DailyRewardCatalog._();

  static const String _base = 'assets/images/rewards/';

  static const List<DailyRewardDef> days = [
    DailyRewardDef(day: 1, coins: 50, tips: 0, iconPath: '${_base}rw_coin_single.png'),
    DailyRewardDef(day: 2, coins: 80, tips: 0, iconPath: '${_base}rw_coin_stack_a.png'),
    DailyRewardDef(day: 3, coins: 110, tips: 10, iconPath: '${_base}rw_coin_pile_a.png'),
    DailyRewardDef(day: 4, coins: 140, tips: 15, iconPath: '${_base}rw_coin_pile_b.png'),
    DailyRewardDef(day: 5, coins: 180, tips: 20, iconPath: '${_base}rw_coin_sack_tan.png'),
    DailyRewardDef(day: 6, coins: 220, tips: 30, iconPath: '${_base}rw_egg_gold_a.png'),
    DailyRewardDef(day: 7, coins: 350, tips: 50, iconPath: '${_base}rw_chest_closed.png'),
  ];

  static const int cycleLength = 7;

  static DailyRewardDef forDay(int day) => days[(day - 1).clamp(0, cycleLength - 1)];
}
