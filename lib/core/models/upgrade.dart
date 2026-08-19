/// Which wallet an upgrade is bought from. Coins come from every served
/// order, tips only from *fast* serves - so tip-priced perks are the reward
/// for playing well rather than for playing long.
enum UpgradeCurrency { coins, tips }

class UpgradeDef {
  const UpgradeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.maxLevel,
    required this.baseCost,
    required this.costGrowth,
    this.currency = UpgradeCurrency.coins,
  });

  final String id;
  final String name;
  final String description;
  final String iconPath;
  final int maxLevel;
  final int baseCost;
  final double costGrowth;
  final UpgradeCurrency currency;

  int costForLevel(int currentLevel) => (baseCost * (1 + currentLevel * costGrowth)).round();
}

class UpgradeCatalog {
  UpgradeCatalog._();

  static const String _kitchenBase = 'assets/images/kitchen/';
  static const String _rewardBase = 'assets/images/rewards/';

  static const List<UpgradeDef> all = [
    UpgradeDef(
      id: 'cook_speed',
      name: 'Cooking Speed',
      description: 'Every station cooks food faster.',
      iconPath: '${_kitchenBase}kit_stove_cream.png',
      maxLevel: 8,
      baseCost: 60,
      costGrowth: 0.35,
    ),
    UpgradeDef(
      id: 'extra_station',
      name: 'Extra Station',
      description: 'Unlocks another cooking station so more dishes can cook at once.',
      iconPath: '${_kitchenBase}kit_pan_copper.png',
      maxLevel: 3,
      baseCost: 250,
      costGrowth: 0.9,
    ),
    UpgradeDef(
      id: 'tip_boost',
      name: 'Charming Service',
      description: 'Customers leave bigger tips for a job well done.',
      iconPath: '${_rewardBase}rw_coin_pile_a.png',
      maxLevel: 6,
      baseCost: 100,
      costGrowth: 0.4,
    ),
    UpgradeDef(
      id: 'patience_boost',
      name: 'Cosy Waiting Area',
      description: 'Customers stay patient for longer before leaving unhappy.',
      iconPath: '${_kitchenBase}kit_timer_red.png',
      maxLevel: 6,
      baseCost: 90,
      costGrowth: 0.4,
    ),

    // ── Chef's perks, bought with tips ──────────────────────────────────
    UpgradeDef(
      id: 'golden_hourglass',
      name: 'Golden Hourglass',
      description: 'Every level starts with 6 more seconds on the clock.',
      iconPath: '${_kitchenBase}kit_timer_blue.png',
      maxLevel: 5,
      baseCost: 40,
      costGrowth: 0.5,
      currency: UpgradeCurrency.tips,
    ),
    UpgradeDef(
      id: 'tidy_pantry',
      name: 'Tidy Pantry',
      description: 'One less look-alike ingredient clutters the prep shelf.',
      iconPath: '${_kitchenBase}kit_shelf_spices_wood.png',
      maxLevel: 2,
      baseCost: 60,
      costGrowth: 0.8,
      currency: UpgradeCurrency.tips,
    ),
    UpgradeDef(
      id: 'steady_hands',
      name: 'Steady Hands',
      description: 'Your combo survives one lost guest per level.',
      iconPath: '${_rewardBase}rw_medal_wreath.png',
      maxLevel: 2,
      baseCost: 75,
      costGrowth: 0.9,
      currency: UpgradeCurrency.tips,
    ),
  ];

  static UpgradeDef byId(String id) => all.firstWhere((e) => e.id == id);

  static List<UpgradeDef> byCurrency(UpgradeCurrency currency) =>
      all.where((e) => e.currency == currency).toList();
}
