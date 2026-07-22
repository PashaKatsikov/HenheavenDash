enum DailyTaskMetric { ordersServed, dishesCooked, comboStreak, coinsEarned, levelNoMistakes }

class DailyTaskDef {
  const DailyTaskDef({
    required this.id,
    required this.metric,
    required this.target,
    required this.description,
    required this.coinReward,
  });

  final String id;
  final DailyTaskMetric metric;
  final int target;
  final String description;
  final int coinReward;
}

/// Pool of possible daily tasks. Three are picked (deterministically, seeded
/// by the date) each day in [DailyTasksService].
class DailyTaskCatalog {
  DailyTaskCatalog._();

  static const List<DailyTaskDef> pool = [
    DailyTaskDef(
      id: 'serve_30',
      metric: DailyTaskMetric.ordersServed,
      target: 30,
      description: 'Serve 30 customers',
      coinReward: 120,
    ),
    DailyTaskDef(
      id: 'cook_100',
      metric: DailyTaskMetric.dishesCooked,
      target: 100,
      description: 'Cook 100 dishes',
      coinReward: 150,
    ),
    DailyTaskDef(
      id: 'combo_20',
      metric: DailyTaskMetric.comboStreak,
      target: 20,
      description: 'Reach a 20-order combo streak',
      coinReward: 130,
    ),
    DailyTaskDef(
      id: 'earn_5000',
      metric: DailyTaskMetric.coinsEarned,
      target: 5000,
      description: 'Earn 5,000 coins',
      coinReward: 200,
    ),
    DailyTaskDef(
      id: 'serve_15',
      metric: DailyTaskMetric.ordersServed,
      target: 15,
      description: 'Serve 15 customers',
      coinReward: 70,
    ),
    DailyTaskDef(
      id: 'cook_40',
      metric: DailyTaskMetric.dishesCooked,
      target: 40,
      description: 'Cook 40 dishes',
      coinReward: 80,
    ),
    DailyTaskDef(
      id: 'no_mistakes',
      metric: DailyTaskMetric.levelNoMistakes,
      target: 1,
      description: 'Finish a level without losing a single customer',
      coinReward: 160,
    ),
  ];
}
