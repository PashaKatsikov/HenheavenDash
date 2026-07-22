import 'package:flutter/material.dart';
import '../../core/game_state_scope.dart';
import '../../core/models/recipe.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/glass_panel.dart';

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
                  child: GridView.builder(
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
                      return _RecipeCard(recipe: recipe, unlocked: isUnlocked);
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

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, required this.unlocked});

  final Recipe recipe;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: unlocked
                ? Image.asset(recipe.foodIconPath, fit: BoxFit.contain)
                : ColorFiltered(
                    colorFilter: const ColorFilter.mode(Colors.black, BlendMode.saturation),
                    child: Opacity(
                      opacity: 0.35,
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
            ),
        ],
      ),
    );
  }
}
