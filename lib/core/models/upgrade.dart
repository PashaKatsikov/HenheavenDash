class UpgradeDef {
  const UpgradeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.maxLevel,
    required this.baseCost,
    required this.costGrowth,
  });

  final String id;
  final String name;
  final String description;
  final String iconPath;
  final int maxLevel;
  final int baseCost;
  final double costGrowth;

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
      id: 'service_speed',
      name: 'Chef Speed',
      description: 'Your chef moves and plates food faster.',
      iconPath: '${_kitchenBase}kit_spatula_wood.png',
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
      id: 'ingredient_capacity',
      name: 'Pantry Capacity',
      description: 'Stations hold more prepped ingredients before refilling.',
      iconPath: '${_kitchenBase}kit_basket_eggs_brown.png',
      maxLevel: 6,
      baseCost: 80,
      costGrowth: 0.4,
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
  ];

  static UpgradeDef byId(String id) => all.firstWhere((e) => e.id == id);
}
