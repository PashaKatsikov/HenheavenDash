import 'package:flutter/material.dart';
import '../../core/models/ingredient.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/game_progress_bar.dart';
import '../../widgets/rustic_panel.dart';
import '../level_session.dart';

class StationCardWidget extends StatefulWidget {
  const StationCardWidget({
    super.key,
    required this.station,
    required this.onTapIngredient,
    required this.onServe,
  });

  final Station station;
  final void Function(String ingredientId) onTapIngredient;
  final VoidCallback onServe;

  static const double size = 196;

  @override
  State<StationCardWidget> createState() => _StationCardWidgetState();
}

class _StationCardWidgetState extends State<StationCardWidget> {
  String? _shakeIngredient;

  void _handleTap(String id) {
    widget.onTapIngredient(id);
    if (!widget.station.preparedIngredients.contains(id)) {
      setState(() => _shakeIngredient = id);
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) setState(() => _shakeIngredient = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final station = widget.station;

    return RusticPanel(
      padding: const EdgeInsets.all(10),
      borderRadius: 18,
      borderColor: station.state == StationState.ready ? AppColors.success : null,
      child: SizedBox(
        width: StationCardWidget.size - 20,
        height: StationCardWidget.size - 20,
        child: _buildContent(station),
      ),
    );
  }

  Widget _buildContent(Station station) {
    switch (station.state) {
      case StationState.idle:
        // The stove sits dead-center of the square card (not grouped above
        // the label, which pushed it off-center), with the "Free station"
        // caption pinned to the bottom so the plate reads as centered in
        // its framed square on every level.
        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Opacity(
                opacity: 0.85,
                child: Image.asset('assets/images/kitchen/kit_stove_cream.png', width: 60, height: 60),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                'Free station',
                style: AppTextStyles.caption.copyWith(color: AppColors.textOnDark.withValues(alpha: 0.7)),
              ),
            ),
          ],
        );
      case StationState.prepping:
        final customer = station.customer!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Image.asset(customer.recipe.foodIconPath, width: 32, height: 32),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    customer.recipe.name,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final id in station.shelfIngredientIds)
                      _IngredientChip(
                        ingredient: IngredientCatalog.byId(id),
                        prepared: station.preparedIngredients.contains(id),
                        shaking: _shakeIngredient == id,
                        onTap: () => _handleTap(id),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      case StationState.cooking:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/effects/fx_00.png', width: 46, height: 46),
            const SizedBox(height: 8),
            Text('Cooking...', style: AppTextStyles.caption.copyWith(color: AppColors.textOnDark)),
            const SizedBox(height: 10),
            GameProgressBar(value: station.cookProgress, height: 10),
          ],
        );
      case StationState.ready:
        return GestureDetector(
          onTap: widget.onServe,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.successButtonGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: AppColors.success.withValues(alpha: 0.5), blurRadius: 14, spreadRadius: -2),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(station.customer!.recipe.foodIconPath, width: 54, height: 54),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/kitchen/kit_serving_bell.png', width: 20, height: 20),
                    const SizedBox(width: 6),
                    Text('TAP TO SERVE', style: AppTextStyles.button.copyWith(fontSize: 15)),
                  ],
                ),
              ],
            ),
          ),
        );
    }
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip({
    required this.ingredient,
    required this.prepared,
    required this.shaking,
    required this.onTap,
  });

  final Ingredient ingredient;
  final bool prepared;
  final bool shaking;
  final VoidCallback onTap;

  static const double _width = 48;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: prepared ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: shaking ? Matrix4.translationValues(4.0, 0.0, 0.0) : Matrix4.identity(),
        width: _width,
        decoration: BoxDecoration(
          color: prepared ? AppColors.success.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: shaking ? AppColors.cta : (prepared ? AppColors.success : AppColors.accent.withValues(alpha: 0.85)),
            width: 1.8,
          ),
          boxShadow: prepared
              ? const []
              : [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 6,
                    spreadRadius: -2,
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(1),
                    child: Opacity(
                      opacity: prepared ? 0.4 : 1,
                      child: Image.asset(ingredient.iconPath, fit: BoxFit.contain),
                    ),
                  ),
                  if (prepared)
                    const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              ingredient.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontSize: 8.5,
                height: 1.1,
                color: prepared ? Colors.white38 : AppColors.textOnDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
