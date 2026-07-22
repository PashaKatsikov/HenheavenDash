import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/glass_panel.dart';

/// A friendly, illustrated "How to Play" screen. Each step reuses the game's
/// own sprite art (customer, ingredients, dish, coins) so the tutorial matches
/// exactly what the player sees in a level.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const List<_HowToStep> _steps = [
    _HowToStep(
      number: '1',
      title: 'Take the order',
      body: 'A guest walks up to the counter and shows the dish they want in a bubble. '
          'Tap the guest to send their order to a free cooking station.',
      iconPath: 'assets/images/clients/client_pig.png',
    ),
    _HowToStep(
      number: '2',
      title: 'Add the ingredients',
      body: 'On the station, tap the ingredients the recipe needs. '
          'Watch out - a couple of wrong ingredients are mixed in as decoys!',
      iconPath: 'assets/images/ingredients/ing_tomato.png',
    ),
    _HowToStep(
      number: '3',
      title: 'Cook & serve',
      body: 'Once every ingredient is in, the dish cooks automatically. '
          'When the bell shows, tap TAP TO SERVE before the guest loses patience.',
      iconPath: 'assets/images/kitchen/kit_serving_bell.png',
    ),
    _HowToStep(
      number: '4',
      title: 'Coins, tips & combos',
      body: 'Serve quickly for bigger tips, and serve guests back-to-back to build a '
          'combo for bonus coins. Hit the order target before time runs out to win!',
      iconPath: 'assets/images/rewards/rw_coin_single.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/backgrounds/kitchen_cottage.webp', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.45)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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
                      Text('How to Play', style: AppTextStyles.h2),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      for (final step in _steps)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _StepCard(step: step),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowToStep {
  const _HowToStep({
    required this.number,
    required this.title,
    required this.body,
    required this.iconPath,
  });

  final String number;
  final String title;
  final String body;
  final String iconPath;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});
  final _HowToStep step;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      borderRadius: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.topLeft,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.4),
                ),
                child: Image.asset(step.iconPath, fit: BoxFit.contain),
              ),
              Positioned(
                left: -6,
                top: -6,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppColors.ctaButtonGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    step.number,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.heading,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTextStyles.h3.copyWith(color: AppColors.textOnDark),
                ),
                const SizedBox(height: 4),
                Text(
                  step.body,
                  style: AppTextStyles.bodyRegular.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
