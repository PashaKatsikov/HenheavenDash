class Ingredient {
  const Ingredient({required this.id, required this.name, required this.iconPath});

  final String id;
  final String name;
  final String iconPath;
}

class IngredientCatalog {
  IngredientCatalog._();

  static const String _base = 'assets/images/ingredients/';

  static const List<Ingredient> all = [
    Ingredient(id: 'egg_white_raw', name: 'White Egg', iconPath: '${_base}ing_egg_white_raw.png'),
    Ingredient(id: 'egg_brown_raw', name: 'Brown Egg', iconPath: '${_base}ing_egg_brown_raw.png'),
    Ingredient(id: 'egg_golden_raw', name: 'Golden Egg', iconPath: '${_base}ing_egg_golden_raw.png'),
    Ingredient(id: 'egg_yolk', name: 'Egg Yolk', iconPath: '${_base}ing_egg_yolk.png'),
    Ingredient(id: 'egg_white_liquid', name: 'Egg White', iconPath: '${_base}ing_egg_white_liquid.png'),
    Ingredient(id: 'egg_bowl', name: 'Cracked Eggs', iconPath: '${_base}ing_egg_bowl.png'),
    Ingredient(id: 'tomato', name: 'Tomato', iconPath: '${_base}ing_tomato.png'),
    Ingredient(id: 'tomato_diced_bowl', name: 'Diced Tomato', iconPath: '${_base}ing_tomato_diced_bowl.png'),
    Ingredient(id: 'basil', name: 'Basil', iconPath: '${_base}ing_basil.png'),
    Ingredient(id: 'parsley', name: 'Parsley', iconPath: '${_base}ing_parsley.png'),
    Ingredient(id: 'mushroom', name: 'Mushroom', iconPath: '${_base}ing_mushroom.png'),
    Ingredient(id: 'bell_pepper', name: 'Bell Pepper', iconPath: '${_base}ing_bell_pepper.png'),
    Ingredient(id: 'butter', name: 'Butter', iconPath: '${_base}ing_butter.png'),
    Ingredient(id: 'cheese_wedge', name: 'Cheese', iconPath: '${_base}ing_cheese_wedge.png'),
    Ingredient(id: 'cheese_shredded_bowl', name: 'Shredded Cheese', iconPath: '${_base}ing_cheese_shredded_bowl.png'),
    Ingredient(id: 'onion', name: 'Onion', iconPath: '${_base}ing_onion.png'),
    Ingredient(id: 'flour_bowl', name: 'Flour', iconPath: '${_base}ing_flour_bowl.png'),
    Ingredient(id: 'bread_slices', name: 'Bread', iconPath: '${_base}ing_bread_slices.png'),
    Ingredient(id: 'cream_bowl', name: 'Cream', iconPath: '${_base}ing_cream_bowl.png'),
  ];

  static Ingredient byId(String id) => all.firstWhere((e) => e.id == id);
}
