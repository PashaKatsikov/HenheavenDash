import 'package:flutter/material.dart';
import '../../core/game_state_scope.dart';
import '../../core/models/ingredient.dart';
import '../../core/models/recipe.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/game_button.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/responsive_content.dart';

class RecipeBookScreen extends StatelessWidget {
  const RecipeBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameStateScope.of(context);
    final unlocked = state.unlockedRecipeIds;
    final total = RecipeCatalog.all.length;
    final pct = ((unlocked.length / total) * 100).round();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/backgrounds/kitchen_cottage.webp', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.38)),
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
                      Text('Recipe Book', style: AppTextStyles.h2),
                      const Spacer(),
                      GlassPanel(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        borderRadius: 30,
                        child: Text(
                          '$pct% Collected',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnDark),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  // ResponsiveContent caps how wide the grid can grow on iPad so
                  // cards stay a sensible size instead of thinning out edge-to-edge.
                  child: ResponsiveContent(maxWidth: 1100, child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 190,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: RecipeCatalog.all.length,
                    itemBuilder: (context, index) {
                      final recipe = RecipeCatalog.all[index];
                      final isUnlocked = unlocked.contains(recipe.id);
                      return _RecipeCard(
                        recipe: recipe,
                        unlocked: isUnlocked,
                        onTap: isUnlocked ? () => _showRecipeDetail(context, recipe) : null,
                      );
                    },
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

/// Shows exactly which ingredients need tapping to cook [recipe] - the grid
/// only tells you a recipe is unlocked, not how to actually make it, so this
/// closes that gap with a tap.
void _showRecipeDetail(BuildContext context, Recipe recipe) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      // NOTE: deliberately *not* wrapped in an extra Center here - Dialog
      // already centers its child itself. An additional Center around a
      // finite-but-large incoming constraint expands to fill that entire
      // space (it only shrink-wraps when the constraint is unbounded), and
      // since Dialog's child sits inside a Material (which hit-tests as
      // opaque over its whole box even fully transparent), that invisible
      // expanded area used to swallow taps meant for the barrier - taps
      // only reached the barrier in the odd leftover margin, which is
      // exactly the "closes in some unmarked areas but not others" bug.
      // Sizing this ConstrainedBox to just the actual content means the
      // Material - and therefore the tap-catching area - matches the
      // visible card exactly, so every tap genuinely outside it reaches
      // the (barrierDismissible) barrier and closes the dialog.
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: GlassPanel(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(recipe.foodIconPath, width: 92, height: 92, fit: BoxFit.contain),
              const SizedBox(height: 8),
              Text(recipe.name, style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                'Cooks in ${recipe.cookSeconds.round()}s  ·  +${recipe.coinReward} coins',
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              Text('Ingredients needed', style: AppTextStyles.h3.copyWith(color: AppColors.accent)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  for (final ingredient in recipe.ingredients) _IngredientBadge(ingredient: ingredient),
                ],
              ),
              const SizedBox(height: 20),
              GameButton(
                label: 'Close',
                width: 140,
                style: GameButtonStyle.outline,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _IngredientBadge extends StatelessWidget {
  const _IngredientBadge({required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
            ),
            child: Image.asset(ingredient.iconPath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 6),
          Text(
            ingredient.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTextStyles.caption.copyWith(color: AppColors.textOnDark),
          ),
        ],
      ),
    );
  }
}

// A plain luminance-based grayscale matrix instead of
// ColorFilter.mode(Colors.black, BlendMode.saturation): the HSL blend modes
// (saturation/hue/color/luminosity) are composited against a same-size
// backdrop, and when that layer is partially clipped at a scroll viewport's
// edge (only a sliver of the card visible), Skia can composite against the
// *clipped* bounds instead of the full image - producing a wrong, brighter
// colour cast that looks like the card briefly turned "unlocked". A matrix
// filter is a simple per-pixel linear transform with no such composited
// backdrop, so it renders identically regardless of how much of the widget
// is currently visible.
const List<double> _grayscaleMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
];

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, required this.unlocked, this.onTap});

  final Recipe recipe;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: unlocked
                  ? Image.asset(recipe.foodIconPath, fit: BoxFit.contain)
                  : Opacity(
                      opacity: 0.35,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
                        child: Image.asset(recipe.foodIconPath, fit: BoxFit.contain),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              unlocked ? recipe.name : 'Locked',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: unlocked ? AppColors.textOnDark : Colors.white38,
              ),
            ),
            if (!unlocked)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Reach level ${recipe.unlockLevel}',
                  style: AppTextStyles.caption.copyWith(color: Colors.white38),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Tap to view',
                  style: AppTextStyles.caption.copyWith(color: Colors.white54),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
