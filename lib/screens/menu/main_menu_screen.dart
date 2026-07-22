import 'package:flutter/material.dart';
import '../../core/game_state.dart';
import '../../core/game_state_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/currency_chip.dart';
import '../../widgets/daily_reward_dialog.dart';
import '../../widgets/farm_gate_button.dart';
import '../../widgets/rustic_panel.dart';
import '../dailies/daily_tasks_screen.dart';
import '../howto/how_to_play_screen.dart';
import '../levels/level_select_screen.dart';
import '../recipes/recipe_book_screen.dart';
import '../settings/settings_screen.dart';
import '../shop/decor_shop_screen.dart';
import '../shop/upgrade_shop_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _offeredDailyReward = false;

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _maybeShowDailyReward(GameState state) {
    if (_offeredDailyReward) return;
    _offeredDailyReward = true;
    if (state.canClaimDailyReward) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) DailyRewardDialog.showIfAvailable(context, state);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GameStateScope.of(context);
    _maybeShowDailyReward(state);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/backgrounds/farmyard_exterior.webp', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.14)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              // Fixed, non-scrolling layout: the menu is meant to sit still
              // and fill the screen. Everything is sized to fit within the
              // available height and distributed with spaceBetween, so the
              // screen never drifts/scrolls under the user's finger.
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CurrencyChip(iconPath: 'assets/images/rewards/rw_coin_sack_tan.png', value: state.coins, compact: true),
                            const SizedBox(width: 12),
                            CurrencyChip(iconPath: 'assets/images/rewards/rw_coin_sack_brown.png', value: state.tips, compact: true),
                            const Spacer(),
                            _HelpGlassButton(
                              onTap: () => _push(context, const HowToPlayScreen()),
                            ),
                            const SizedBox(width: 10),
                            _IconGlassButton(
                              icon: Icons.settings,
                              onTap: () => _push(context, const SettingsScreen()),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/images/ui/logo_henhaven_dash.webp', width: 168),
                            Text(
                              'Best score: ${state.bestScore}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textOnDark,
                                fontSize: 13,
                                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                              ),
                            ),
                            const SizedBox(height: 6),
                            FarmGateButton(
                              width: 208,
                              height: 56,
                              onPressed: () => _push(context, const LevelSelectScreen()),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _MenuTile(
                              label: 'Recipes',
                              iconPath: 'assets/images/food/food_omelet_veggie.png',
                              tint: AppColors.primary,
                              angle: -0.045,
                              onTap: () => _push(context, const RecipeBookScreen()),
                            ),
                            const SizedBox(width: 10),
                            _MenuTile(
                              label: 'Upgrades',
                              iconPath: 'assets/images/kitchen/kit_pan_copper.png',
                              tint: AppColors.success,
                              angle: 0.03,
                              yOffset: -6,
                              onTap: () => _push(context, const UpgradeShopScreen()),
                            ),
                            const SizedBox(width: 10),
                            _MenuTile(
                              label: 'Farm Shop',
                              iconPath: 'assets/images/decor/decor_sunflower_pot.png',
                              tint: AppColors.accent,
                              angle: -0.02,
                              onTap: () => _push(context, const DecorShopScreen()),
                            ),
                            const SizedBox(width: 10),
                            _MenuTile(
                              label: 'Daily Tasks',
                              iconPath: 'assets/images/rewards/rw_chest_open_a.png',
                              tint: AppColors.surfaceDarkAlt,
                              angle: 0.045,
                              yOffset: -4,
                              onTap: () => _push(context, const DailyTasksScreen()),
                            ),
                            const SizedBox(width: 10),
                            _MenuTile(
                              label: 'Daily Gift',
                              iconPath: 'assets/images/rewards/rw_chest_closed.png',
                              tint: AppColors.cta,
                              angle: -0.03,
                              badge: state.canClaimDailyReward,
                              onTap: () => DailyRewardDialog.show(context, state),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Gradient _tintedWood(Color hue) => LinearGradient(
      colors: [
        Color.lerp(AppColors.surfaceDarkAlt, hue, 0.4)!,
        AppColors.surfaceDark,
        Color.lerp(AppColors.surfaceDark, hue, 0.12)!,
      ],
      stops: const [0, 0.55, 1],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

/// A menu shortcut, painted as its own small carved-wood plaque instead of a
/// generic rounded rectangle: each tile gets a distinct colour tint from the
/// palette and a slight hand-placed tilt/offset so the row doesn't read as a
/// perfectly aligned grid.
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.label,
    required this.iconPath,
    required this.tint,
    required this.onTap,
    this.angle = 0,
    this.yOffset = 0,
    this.badge = false,
  });

  final String label;
  final String iconPath;
  final Color tint;
  final VoidCallback onTap;
  final double angle;
  final double yOffset;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Transform.rotate(
        angle: angle,
        child: GestureDetector(
          onTap: onTap,
          child: RusticPanel(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            borderRadius: 14,
            gradient: _tintedWood(tint),
            borderColor: badge ? AppColors.accent : tint.withValues(alpha: 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(iconPath, width: 32, height: 32),
                    if (badge)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.cta,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnDark, fontSize: 10.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconGlassButton extends StatelessWidget {
  const _IconGlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RusticPanel(
        padding: const EdgeInsets.all(8),
        borderRadius: 26,
        pegs: false,
        child: Icon(icon, color: AppColors.accent, size: 20),
      ),
    );
  }
}

/// "How to play" button - a friendly hand-lettered "?" in the brand font so it
/// reads as part of the game art rather than a stock system glyph.
class _HelpGlassButton extends StatelessWidget {
  const _HelpGlassButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RusticPanel(
        padding: const EdgeInsets.all(8),
        borderRadius: 26,
        pegs: false,
        child: SizedBox(
          width: 20,
          height: 20,
          child: Center(
            child: Text(
              '?',
              style: TextStyle(
                fontFamily: AppTextStyles.heading,
                fontWeight: FontWeight.w800,
                fontSize: 19,
                height: 1,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
