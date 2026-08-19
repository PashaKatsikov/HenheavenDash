import 'package:flutter/material.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/game_state_scope.dart';
import '../../core/haptics.dart';
import '../../core/models/upgrade.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/currency_chip.dart';
import '../../widgets/game_button.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/responsive_content.dart';

class UpgradeShopScreen extends StatefulWidget {
  const UpgradeShopScreen({super.key});

  @override
  State<UpgradeShopScreen> createState() => _UpgradeShopScreenState();
}

const String _coinIcon = 'assets/images/rewards/rw_coin_sack_tan.png';
const String _tipIcon = 'assets/images/rewards/rw_coin_sack_brown.png';

String _iconFor(UpgradeCurrency currency) =>
    currency == UpgradeCurrency.tips ? _tipIcon : _coinIcon;

class _UpgradeShopScreenState extends State<UpgradeShopScreen> {
  void _onPurchased() {
    AudioManager.instance.playUpgrade();
    Haptics.instance.success();
    setState(() {});
  }

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
                      Expanded(child: Text('Upgrades', style: AppTextStyles.h2)),
                      CurrencyChip(iconPath: _coinIcon, value: state.coins, compact: true),
                      const SizedBox(width: 12),
                      CurrencyChip(iconPath: _tipIcon, value: state.tips, compact: true),
                    ],
                  ),
                ),
                Expanded(
                  // ResponsiveContent keeps this list from stretching edge-to-edge
                  // on iPad's much wider landscape canvas.
                  child: ResponsiveContent(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      children: [
                        const _SectionHeader(
                          title: 'Kitchen Upgrades',
                          subtitle: 'Bought with coins from every order you serve.',
                        ),
                        for (final def in UpgradeCatalog.byCurrency(UpgradeCurrency.coins))
                          _UpgradeRow(def: def, onPurchased: _onPurchased),
                        const SizedBox(height: 10),
                        const _SectionHeader(
                          title: "Chef's Perks",
                          subtitle: 'Bought with tips - and tips only come from fast serves.',
                        ),
                        for (final def in UpgradeCatalog.byCurrency(UpgradeCurrency.tips))
                          _UpgradeRow(def: def, onPurchased: _onPurchased),
                      ],
                    ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.accent)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.caption.copyWith(color: Colors.white60)),
        ],
      ),
    );
  }
}

class _UpgradeRow extends StatelessWidget {
  const _UpgradeRow({required this.def, required this.onPurchased});

  final UpgradeDef def;
  final VoidCallback onPurchased;

  @override
  Widget build(BuildContext context) {
    final state = GameStateScope.of(context);
    final level = state.upgradeLevelFor(def.id);
    final maxed = level >= def.maxLevel;
    final cost = maxed ? 0 : def.costForLevel(level);
    final affordable = !maxed && state.canAffordUpgrade(def.id);

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
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!maxed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Image.asset(_iconFor(def.currency), width: 24, height: 24),
                  ),
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
                          if (await state.purchaseUpgrade(def.id)) onPurchased();
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
