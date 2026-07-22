import 'ingredient.dart';

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.foodIconPath,
    required this.ingredientIds,
    required this.cookSeconds,
    required this.unlockLevel,
    required this.coinReward,
  });

  final String id;
  final String name;
  final String foodIconPath;
  final List<String> ingredientIds;
  final double cookSeconds;
  final int unlockLevel;
  final int coinReward;

  List<Ingredient> get ingredients => ingredientIds.map(IngredientCatalog.byId).toList();
}

class RecipeCatalog {
  RecipeCatalog._();

  static const String _base = 'assets/images/food/';

  static const List<Recipe> all = [
    Recipe(
      id: 'fried_egg',
      name: 'Fried Egg',
      foodIconPath: '${_base}food_fried_egg.png',
      ingredientIds: ['egg_brown_raw', 'butter'],
      cookSeconds: 6,
      unlockLevel: 1,
      coinReward: 10,
    ),
    Recipe(
      id: 'boiled_eggs',
      name: 'Boiled Eggs',
      foodIconPath: '${_base}food_boiled_eggs.png',
      ingredientIds: ['egg_white_raw', 'egg_brown_raw'],
      cookSeconds: 9,
      unlockLevel: 1,
      coinReward: 12,
    ),
    Recipe(
      id: 'scrambled_eggs',
      name: 'Scrambled Eggs',
      foodIconPath: '${_base}food_scrambled_eggs.png',
      ingredientIds: ['egg_bowl', 'butter', 'cheese_shredded_bowl'],
      cookSeconds: 8,
      unlockLevel: 2,
      coinReward: 16,
    ),
    Recipe(
      id: 'omelet_plain',
      name: 'Classic Omelet',
      foodIconPath: '${_base}food_omelet_plain.png',
      ingredientIds: ['egg_bowl', 'butter'],
      cookSeconds: 8,
      unlockLevel: 2,
      coinReward: 16,
    ),
    Recipe(
      id: 'fried_egg_teal',
      name: 'Golden Fried Egg',
      foodIconPath: '${_base}food_fried_egg_teal.png',
      ingredientIds: ['egg_golden_raw', 'butter', 'parsley'],
      cookSeconds: 7,
      unlockLevel: 3,
      coinReward: 18,
    ),
    Recipe(
      id: 'egg_sandwich',
      name: 'Egg Sandwich',
      foodIconPath: '${_base}food_egg_sandwich.png',
      ingredientIds: ['bread_slices', 'egg_bowl', 'butter'],
      cookSeconds: 9,
      unlockLevel: 3,
      coinReward: 20,
    ),
    Recipe(
      id: 'egg_toast',
      name: 'Cheesy Egg Toast',
      foodIconPath: '${_base}food_egg_toast.png',
      ingredientIds: ['bread_slices', 'egg_bowl', 'cheese_shredded_bowl'],
      cookSeconds: 9,
      unlockLevel: 3,
      coinReward: 20,
    ),
    Recipe(
      id: 'omelet_veggie',
      name: 'Veggie Omelet',
      foodIconPath: '${_base}food_omelet_veggie.png',
      ingredientIds: ['egg_bowl', 'bell_pepper', 'onion', 'cheese_wedge'],
      cookSeconds: 10,
      unlockLevel: 4,
      coinReward: 24,
    ),
    Recipe(
      id: 'avocado_egg_toast',
      name: 'Avocado Egg Toast',
      foodIconPath: '${_base}food_avocado_egg_toast.png',
      ingredientIds: ['bread_slices', 'egg_bowl', 'basil'],
      cookSeconds: 10,
      unlockLevel: 4,
      coinReward: 24,
    ),
    Recipe(
      id: 'pancake_egg_stack',
      name: 'Pancake & Egg Stack',
      foodIconPath: '${_base}food_pancake_egg_stack.png',
      ingredientIds: ['flour_bowl', 'egg_bowl', 'butter'],
      cookSeconds: 11,
      unlockLevel: 5,
      coinReward: 28,
    ),
    Recipe(
      id: 'egg_muffins',
      name: 'Egg Muffins',
      foodIconPath: '${_base}food_egg_muffins.png',
      ingredientIds: ['egg_bowl', 'tomato_diced_bowl', 'cheese_shredded_bowl'],
      cookSeconds: 11,
      unlockLevel: 5,
      coinReward: 28,
    ),
    Recipe(
      id: 'full_breakfast',
      name: 'Farmhouse Breakfast',
      foodIconPath: '${_base}food_full_breakfast.png',
      ingredientIds: ['egg_bowl', 'tomato', 'mushroom', 'bread_slices'],
      cookSeconds: 12,
      unlockLevel: 6,
      coinReward: 32,
    ),
    Recipe(
      id: 'shakshuka',
      name: 'Shakshuka',
      foodIconPath: '${_base}food_shakshuka.png',
      ingredientIds: ['tomato', 'bell_pepper', 'onion', 'egg_bowl'],
      cookSeconds: 12,
      unlockLevel: 6,
      coinReward: 32,
    ),
    Recipe(
      id: 'eggs_benedict',
      name: 'Eggs Benedict',
      foodIconPath: '${_base}food_eggs_benedict.png',
      ingredientIds: ['bread_slices', 'egg_yolk', 'egg_white_liquid', 'butter'],
      cookSeconds: 13,
      unlockLevel: 7,
      coinReward: 38,
    ),
    Recipe(
      id: 'scrambled_veggie_plate',
      name: 'Festive Farm Breakfast',
      foodIconPath: '${_base}food_scrambled_veggie_plate.png',
      ingredientIds: ['egg_bowl', 'tomato_diced_bowl', 'cheese_shredded_bowl', 'parsley'],
      cookSeconds: 12,
      unlockLevel: 7,
      coinReward: 38,
    ),
  ];

  static Recipe byId(String id) => all.firstWhere((e) => e.id == id);

  static List<Recipe> newlyUnlockedAt(int level) =>
      all.where((r) => r.unlockLevel == level).toList();
}
