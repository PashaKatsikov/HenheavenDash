import 'package:flutter/material.dart';
import '../../core/game_state_scope.dart';
import '../../core/models/kitchen.dart';
import '../../core/models/level_config.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/responsive_content.dart';
import '../game/game_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameStateScope.of(context);
    // Levels unlock one at a time: clearing a level raises highestLevelUnlocked
    // by one, which is the only thing that opens the next tile.
    final unlocked = state.highestLevelUnlocked;
    final stars = state.starsPerLevel;
    final endlessUnlocked = unlocked > LevelCatalog.totalLevels;

    final byKitchen = <KitchenTheme, List<int>>{};
    for (var lvl = 1; lvl <= LevelCatalog.totalLevels; lvl++) {
      final kitchen = LevelCatalog.getLevel(lvl).kitchen;
      byKitchen.putIfAbsent(kitchen, () => []).add(lvl);
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/backgrounds/kitchen_rustic.webp', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.35)),
          SafeArea(
            child: Column(
              children: [
                _Header(title: 'Select Level'),
                Expanded(
                  // ResponsiveContent keeps this list from stretching edge-to-edge
                  // on iPad's much wider landscape canvas (a bit roomier than the
                  // other menu screens since each entry is a grid of level tiles).
                  child: ResponsiveContent(maxWidth: 900, child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    children: [
                      for (final entry in byKitchen.entries)
                        _KitchenSection(
                          kitchen: entry.key,
                          levels: entry.value,
                          highestUnlocked: unlocked,
                          stars: stars,
                        ),
                      _EndlessSection(unlocked: endlessUnlocked, bestScore: state.bestEndlessScore),
                    ],
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const GlassPanel(
              padding: EdgeInsets.all(10),
              borderRadius: 30,
              child: Icon(Icons.arrow_back, color: AppColors.accent),
            ),
          ),
          const SizedBox(width: 14),
          Text(title, style: AppTextStyles.h2),
        ],
      ),
    );
  }
}

class _KitchenSection extends StatelessWidget {
  const _KitchenSection({
    required this.kitchen,
    required this.levels,
    required this.highestUnlocked,
    required this.stars,
  });

  final KitchenTheme kitchen;
  final List<int> levels;
  final int highestUnlocked;
  final Map<int, int> stars;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GlassPanel(
        borderRadius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    kitchen.backgroundPath,
                    width: 54,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(kitchen.name, style: AppTextStyles.h3.copyWith(color: AppColors.textOnDark)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final lvl in levels)
                  _LevelTile(
                    level: lvl,
                    locked: lvl > highestUnlocked,
                    stars: stars[lvl] ?? 0,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.level, required this.locked, required this.stars});

  final int level;
  final bool locked;
  final int stars;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => GameScreen(level: level)),
              ),
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            gradient: locked ? null : AppColors.primaryButtonGradient,
            color: locked ? AppColors.surfaceDarkAlt : null,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.6), width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (locked)
                const Icon(Icons.lock, color: Colors.white70, size: 22)
              else
                Text('$level', style: AppTextStyles.h3.copyWith(color: Colors.white)),
              if (!locked)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final earned = i < stars;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Opacity(
                          opacity: earned ? 1 : 0.28,
                          child: Image.asset(
                            'assets/images/rewards/rw_star_a.png',
                            width: 14,
                            height: 14,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Unlocks once every kitchen level has been cleared - a score-attack run on
/// the hardest kitchen's difficulty that just keeps going until 3 mistakes
/// end it, instead of a fixed level with a target order count.
class _EndlessSection extends StatelessWidget {
  const _EndlessSection({required this.unlocked, required this.bestScore});

  final bool unlocked;
  final int bestScore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: unlocked
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GameScreen.endless()),
                )
            : null,
        child: Opacity(
          opacity: unlocked ? 1 : 0.6,
          child: GlassPanel(
            borderRadius: 22,
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: unlocked ? AppColors.primaryButtonGradient : null,
                    color: unlocked ? null : AppColors.surfaceDarkAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.6), width: 1.4),
                  ),
                  child: Icon(
                    unlocked ? Icons.all_inclusive_rounded : Icons.lock,
                    color: unlocked ? Colors.white : Colors.white70,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Endless Mode', style: AppTextStyles.h3.copyWith(color: AppColors.textOnDark)),
                      const SizedBox(height: 2),
                      Text(
                        unlocked
                            ? 'Best score: $bestScore  \u00b7  3 mistakes and it\'s over'
                            : 'Clear every level to unlock',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textOnDark.withValues(alpha: 0.75),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unlocked) const Icon(Icons.chevron_right, color: AppColors.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
