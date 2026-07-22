import 'package:flutter/material.dart';
import '../../core/models/recipe.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/game_button.dart';
import '../../widgets/glass_panel.dart';

class LevelResultOverlay extends StatelessWidget {
  const LevelResultOverlay({
    super.key,
    required this.won,
    required this.score,
    required this.coinsEarned,
    required this.tipsEarned,
    required this.stars,
    required this.newlyUnlockedRecipes,
    required this.onRetry,
    required this.onNext,
    required this.onExit,
    this.endless = false,
    this.isNewBest = false,
    this.bestScore = 0,
  });

  final bool won;
  final int score;
  final int coinsEarned;
  final int tipsEarned;
  final int stars;
  final List<Recipe> newlyUnlockedRecipes;
  final VoidCallback onRetry;
  final VoidCallback? onNext;
  final VoidCallback onExit;

  /// Endless mode has no "win" state - a run always ends once 3 mistakes
  /// pile up, so the overlay swaps stars/next-level for a best-score banner.
  final bool endless;
  final bool isNewBest;
  final int bestScore;

  @override
  Widget build(BuildContext context) {
    final title = endless ? 'Game Over!' : (won ? 'Kitchen Cleared!' : "Time's Up!");
    final celebratory = !endless && won;
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: SingleChildScrollView(
          child: GlassPanel(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    celebratory ? 'assets/images/chef/chef_celebrating.png' : 'assets/images/chef/chef_shocked.png',
                    height: 110,
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: AppTextStyles.h1.copyWith(fontSize: 30)),
                  if (endless && isNewBest) ...[
                    const SizedBox(height: 10),
                    Text('🏆 New Best Score!', style: AppTextStyles.h3.copyWith(color: AppColors.accent)),
                  ] else if (!endless) ...[
                    // Stars now always reflect the score earned, even on a
                    // loss, so a near-miss run still shows fair credit
                    // instead of flattening straight to zero.
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final earned = i < stars;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: earned ? 420 : 260),
                            curve: Curves.easeOutBack,
                            builder: (context, t, child) => Transform.scale(
                              scale: earned ? (0.4 + 0.6 * t.clamp(0, 1)) : 1,
                              child: child,
                            ),
                            child: Opacity(
                              opacity: earned ? 1 : 0.22,
                              child: Image.asset(
                                'assets/images/rewards/rw_star_a.png',
                                width: 46,
                                height: 46,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _StatRow(label: 'Score', value: '$score'),
                  _StatRow(label: 'Coins earned', value: '+$coinsEarned'),
                  _StatRow(label: 'Tips earned', value: '+$tipsEarned'),
                  if (endless) _StatRow(label: 'Best score', value: '$bestScore'),
                  if (!endless && newlyUnlockedRecipes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text('New recipe unlocked!', style: AppTextStyles.h3.copyWith(color: AppColors.accent)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: [
                        for (final r in newlyUnlockedRecipes)
                          Column(
                            children: [
                              Image.asset(r.foodIconPath, width: 48, height: 48),
                              Text(r.name, style: AppTextStyles.caption.copyWith(color: Colors.white)),
                            ],
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GameButton(
                        label: celebratory ? 'Replay' : 'Retry',
                        style: GameButtonStyle.outline,
                        width: 130,
                        onPressed: onRetry,
                      ),
                      const SizedBox(width: 12),
                      if (!endless && won && onNext != null)
                        GameButton(label: 'Next Level', style: GameButtonStyle.success, width: 150, onPressed: onNext)
                      else
                        GameButton(label: 'Menu', style: GameButtonStyle.success, width: 130, onPressed: onExit),
                    ],
                  ),
                  if (!endless && won && onNext != null) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: onExit,
                      child: const Text('Back to Menu', style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
          Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.textOnDark)),
        ],
      ),
    );
  }
}
