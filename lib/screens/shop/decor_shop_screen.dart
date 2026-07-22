import 'package:flutter/material.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/game_state_scope.dart';
import '../../core/models/decor_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/currency_chip.dart';
import '../../widgets/game_button.dart';
import '../../widgets/glass_panel.dart';

/// A purely cosmetic collection shop: spend coins earned in levels on farm
/// trinkets for the "collect them all" satisfaction. Gives players something
/// worthwhile to save up for beyond the functional upgrades.
class DecorShopScreen extends StatefulWidget {
  const DecorShopScreen({super.key});

  @override
  State<DecorShopScreen> createState() => _DecorShopScreenState();
}

class _DecorShopScreenState extends State<DecorShopScreen> {
  @override
  Widget build(BuildContext context) {
    final state = GameStateScope.of(context);
    final owned = state.ownedDecorIds;
    final total = DecorCatalog.all.length;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/backgrounds/farmyard_exterior.webp', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.42)),
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
                      Text('Farm Shop', style: AppTextStyles.h2),
                      const SizedBox(width: 10),
                      GlassPanel(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        borderRadius: 30,
                        child: Text(
                          '${owned.length}/$total',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textOnDark),
                        ),
                      ),
                      const Spacer(),
                      CurrencyChip(iconPath: 'assets/images/rewards/rw_coin_sack_tan.png', value: state.coins),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 170,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: DecorCatalog.all.length,
                    itemBuilder: (context, index) {
                      final item = DecorCatalog.all[index];
                      final isOwned = owned.contains(item.id);
                      final affordable = state.canAffordDecor(item.id);
                      return _DecorCard(
                        item: item,
                        owned: isOwned,
                        affordable: affordable,
                        onBuy: () async {
                          final ok = await state.purchaseDecor(item.id);
                          if (ok) {
                            AudioManager.instance.playUpgrade();
                            setState(() {});
                          }
                        },
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

class _DecorCard extends StatelessWidget {
  const _DecorCard({
    required this.item,
    required this.owned,
    required this.affordable,
    required this.onBuy,
  });

  final DecorItemDef item;
  final bool owned;
  final bool affordable;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(10),
      borderColor: owned ? AppColors.success.withValues(alpha: 0.7) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: owned ? 1 : 0.75,
                  child: Image.asset(item.iconPath, fit: BoxFit.contain),
                ),
                if (owned)
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(Icons.check_circle, size: 18, color: AppColors.success),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: AppColors.textOnDark),
          ),
          const SizedBox(height: 6),
          if (owned)
            Text('Owned', style: AppTextStyles.caption.copyWith(color: AppColors.success))
          else
            GameButton(
              label: '${item.cost}',
              icon: Icons.monetization_on,
              width: double.infinity,
              height: 36,
              fontSize: 13,
              style: GameButtonStyle.primary,
              onPressed: affordable ? onBuy : null,
            ),
        ],
      ),
    );
  }
}
