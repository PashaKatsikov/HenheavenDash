import 'package:flutter/material.dart';
import '../../core/audio/audio_manager.dart';
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
import '../shop/upgrade_shop_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _offeredDailyReward = false;

  @override
  void initState() {
    super.initState();
    AudioManager.instance.playBgm();
  }

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

    // Tablet enlargement is handled globally at the app root (_TabletScaler),
    // which scales the whole UI uniformly - so this screen keeps its natural
    // phone-tuned sizes and simply gets scaled up along with everything else.
    const ui = 1.0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/backgrounds/farmyard_exterior.webp', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.14)),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * ui, vertical: 6 * ui),
              // Fixed, non-scrolling layout: the menu is meant to sit still
              // and fill the screen. The top bar and bottom shortcut row
              // (which now includes the Play button itself) keep their
              // natural size, and the logo/best-score group in between
              // claims whatever vertical space is actually left over and is
              // wrapped in a FittedBox(BoxFit.contain) - unlike scaleDown
              // (which only ever shrinks, so on a roomy iPad or a tall
              // window it just sits at its native size surrounded by empty
              // space), contain also scales *up* to fill whatever room is
              // actually available while still guaranteeing it can never
              // overflow onto the top bar or the shortcut row below.
              child: Column(
                children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CurrencyChip(iconPath: 'assets/images/rewards/rw_coin_sack_tan.png', value: state.coins, compact: true, scale: ui),
                            SizedBox(width: 12 * ui),
                            CurrencyChip(iconPath: 'assets/images/rewards/rw_coin_sack_brown.png', value: state.tips, compact: true, scale: ui),
                            const Spacer(),
                            _HelpGlassButton(
                              scale: ui,
                              onTap: () => _push(context, const HowToPlayScreen()),
                            ),
                            SizedBox(width: 10 * ui),
                            _IconGlassButton(
                              icon: Icons.settings,
                              scale: ui,
                              onTap: () => _push(context, const SettingsScreen()),
                            ),
                          ],
                        ),
                        Expanded(
                          // With the Play button moved down into the shortcut
                          // row below, this block is *just* the logo + best
                          // score - so BoxFit.contain now has the whole
                          // leftover height to itself and scales the logo up
                          // dramatically further than before.
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset('assets/images/ui/logo_henhaven_dash.webp', width: 380),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Best score: ${state.bestScore}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textOnDark,
                                      fontSize: 17,
                                      shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _MenuTile(
                                label: 'Recipes',
                                iconPath: 'assets/images/food/food_omelet_veggie.png',
                                tint: AppColors.primary,
                                angle: -0.045,
                                scale: ui,
                                onTap: () => _push(context, const RecipeBookScreen()),
                              ),
                              SizedBox(width: 12 * ui),
                              _MenuTile(
                                label: 'Upgrades',
                                iconPath: 'assets/images/kitchen/kit_pan_copper.png',
                                tint: AppColors.success,
                                angle: 0.03,
                                yOffset: -6 * ui,
                                scale: ui,
                                onTap: () => _push(context, const UpgradeShopScreen()),
                              ),
                              SizedBox(width: 14 * ui),
                              // The primary action: noticeably taller than the
                              // plain shortcut tiles either side of it, and
                              // since the row aligns everything to a shared
                              // bottom edge (crossAxisAlignment.end), that
                              // extra height alone makes it rise above them
                              // like a raised centre FAB - no manual offset
                              // needed, and no risk of it looking detached.
                              FarmGateButton(
                                width: 190 * ui,
                                height: 98 * ui,
                                onPressed: () => _push(context, const LevelSelectScreen()),
                              ),
                              SizedBox(width: 14 * ui),
                              _MenuTile(
                                label: 'Daily Tasks',
                                iconPath: 'assets/images/rewards/rw_chest_open_a.png',
                                tint: AppColors.surfaceDarkAlt,
                                angle: 0.045,
                                yOffset: -4 * ui,
                                scale: ui,
                                onTap: () => _push(context, const DailyTasksScreen()),
                              ),
                              SizedBox(width: 12 * ui),
                              _MenuTile(
                                label: 'Daily Gift',
                                iconPath: 'assets/images/rewards/rw_chest_closed.png',
                                tint: AppColors.cta,
                                angle: -0.03,
                                scale: ui,
                                badge: state.canClaimDailyReward,
                                onTap: () => DailyRewardDialog.show(context, state),
                              ),
                            ],
                          ),
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
    this.scale = 1.0,
  });

  final String label;
  final String iconPath;
  final Color tint;
  final VoidCallback onTap;
  final double angle;
  final double yOffset;
  final bool badge;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Transform.rotate(
        angle: angle,
        child: GestureDetector(
          onTap: onTap,
          child: RusticPanel(
            padding: EdgeInsets.symmetric(horizontal: 9 * scale, vertical: 7 * scale),
            borderRadius: 14 * scale,
            gradient: _tintedWood(tint),
            borderColor: badge ? AppColors.accent : tint.withValues(alpha: 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(iconPath, width: 32 * scale, height: 32 * scale),
                    if (badge)
                      Positioned(
                        top: -4 * scale,
                        right: -4 * scale,
                        child: Container(
                          width: 12 * scale,
                          height: 12 * scale,
                          decoration: BoxDecoration(
                            color: AppColors.cta,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5 * scale),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 3 * scale),
                Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnDark, fontSize: 10.5 * scale)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconGlassButton extends StatelessWidget {
  const _IconGlassButton({required this.icon, required this.onTap, this.scale = 1.0});

  final IconData icon;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RusticPanel(
        padding: EdgeInsets.all(8 * scale),
        borderRadius: 26 * scale,
        pegs: false,
        child: Icon(icon, color: AppColors.accent, size: 20 * scale),
      ),
    );
  }
}

/// "How to play" button - a friendly hand-lettered "?" in the brand font so it
/// reads as part of the game art rather than a stock system glyph.
class _HelpGlassButton extends StatelessWidget {
  const _HelpGlassButton({required this.onTap, this.scale = 1.0});

  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RusticPanel(
        padding: EdgeInsets.all(8 * scale),
        borderRadius: 26 * scale,
        pegs: false,
        child: SizedBox(
          width: 20 * scale,
          height: 20 * scale,
          child: Center(
            child: Text(
              '?',
              style: TextStyle(
                fontFamily: AppTextStyles.heading,
                fontWeight: FontWeight.w800,
                fontSize: 19 * scale,
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
