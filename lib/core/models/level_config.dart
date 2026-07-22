import 'kitchen.dart';

class LevelConfig {
  const LevelConfig({
    required this.level,
    required this.kitchen,
    required this.targetOrders,
    required this.maxQueueSize,
    required this.spawnIntervalSeconds,
    required this.basePatienceSeconds,
    required this.levelTimeSeconds,
    required this.starThresholds,
  });

  final int level;
  final KitchenTheme kitchen;
  final int targetOrders;
  final int maxQueueSize;
  final double spawnIntervalSeconds;
  final double basePatienceSeconds;
  final double levelTimeSeconds;

  /// Score needed for 1/2/3 stars respectively.
  final List<int> starThresholds;
}

/// Levels are generated from a smooth difficulty curve rather than hand
/// authored one-by-one, so the game supports a long 30-level progression
/// (5 levels x 6 kitchens) that scales consistently. Each kitchen tier
/// unlocks a fresh background from the art set.
class LevelCatalog {
  LevelCatalog._();

  static const int totalLevels = 30;

  static LevelConfig getLevel(int level) {
    final clamped = level.clamp(1, totalLevels);
    final t = (clamped - 1) / (totalLevels - 1); // 0..1 difficulty progress

    final targetOrders = (8 + clamped * 1.4).round();
    final spawnInterval = (6.5 - t * 3.2).clamp(2.6, 6.5);
    final patience = (34 - t * 12).clamp(18.0, 34.0);
    final levelTime = (75 + clamped * 3.5).clamp(75.0, 180.0);
    final maxQueue = (3 + (clamped / 6).floor()).clamp(3, 6);

    final baseScore = targetOrders * 40;
    return LevelConfig(
      level: clamped,
      kitchen: KitchenCatalog.forLevel(clamped),
      targetOrders: targetOrders,
      maxQueueSize: maxQueue,
      spawnIntervalSeconds: spawnInterval.toDouble(),
      basePatienceSeconds: patience.toDouble(),
      levelTimeSeconds: levelTime.toDouble(),
      starThresholds: [
        (baseScore * 0.6).round(),
        (baseScore * 0.9).round(),
        (baseScore * 1.25).round(),
      ],
    );
  }
}
