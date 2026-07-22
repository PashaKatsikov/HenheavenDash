import 'package:flutter/material.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/game_state_scope.dart';
import '../../core/models/upgrade.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/currency_chip.dart';
import '../../widgets/game_button.dart';
import '../../widgets/glass_panel.dart';

class UpgradeShopScreen extends StatefulWidget {
  const UpgradeShopScreen({super.key});

  @override
  State<UpgradeShopScreen> createState() => _UpgradeShopScreenState();
}

class _UpgradeShopScreenState extends State<UpgradeShopScreen> {
  @override
  Widget build(BuildContext context) {
    final state = GameStateScope.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/backgrounds/kitchen_marble.webp', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.4)),
          SafeArea(
            child: Column(
              children: [
                Padding(
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
                      Text('Kitchen Upgrades', style: AppTextStyles.h2),
                      const Spacer(),
                      CurrencyChip(iconPath: 'assets/images/rewards/rw_coin_sack_tan.png', value: state.coins),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: UpgradeCatalog.all.length,
                    itemBuilder: (context, index) {
                      final def = UpgradeCatalog.all[index];
                      final level = state.upgradeLevelFor(def.id);
                      final maxed = level >= def.maxLevel;
                      final cost = maxed ? 0 : def.costForLevel(level);
                      final affordable = !maxed && state.coins >= cost;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: GlassPanel(
                          child: Row(
                            children: [
                              Image.asset(def.iconPath, width: 56, height: 56),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(def.name, style: AppTextStyles.h3.copyWith(color: AppColors.textOnDark)),
                                    const SizedBox(height: 4),
                                    Text(
                                      def.description,
                                      style: AppTextStyles.caption.copyWith(color: Colors.white70),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: List.generate(def.maxLevel, (i) {
                                        return Container(
                                          margin: const EdgeInsets.only(right: 4),
                                          width: 14,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: i < level ? AppColors.accent : Colors.white24,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              GameButton(
                                label: maxed ? 'MAX' : '$cost',
                                icon: maxed ? null : Icons.arrow_upward_rounded,
                                width: 108,
                                height: 46,
                                fontSize: 16,
                                style: GameButtonStyle.success,
                                onPressed: maxed || !affordable
                                    ? null
                                    : () async {
                                        final ok = await state.purchaseUpgrade(def.id);
                                        if (ok) {
                                          AudioManager.instance.playUpgrade();
                                          setState(() {});
                                        }
                                      },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
