class DecorItemDef {
  const DecorItemDef({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.cost,
    required this.category,
  });

  final String id;
  final String name;
  final String iconPath;
  final int cost;
  final String category;
}

/// Purely cosmetic collectibles for the kitchen, bought with coins earned in
/// levels. Gives players something worth spending their coin stash on beyond
/// the functional upgrades, and a "collect them all" goal.
class DecorCatalog {
  DecorCatalog._();

  static const String _base = 'assets/images/decor/';

  static const List<DecorItemDef> all = [
    DecorItemDef(id: 'decor_lantern', name: 'Cosy Lantern', iconPath: '${_base}decor_lantern.png', cost: 80, category: 'Lighting'),
    DecorItemDef(id: 'decor_fence', name: 'Picket Fence', iconPath: '${_base}decor_fence.png', cost: 60, category: 'Structure'),
    DecorItemDef(id: 'decor_signpost', name: 'Farm Signpost', iconPath: '${_base}decor_signpost.png', cost: 90, category: 'Structure'),
    DecorItemDef(id: 'decor_hay_bale', name: 'Hay Bale', iconPath: '${_base}decor_hay_bale.png', cost: 50, category: 'Farm'),
    DecorItemDef(id: 'decor_hay_roll', name: 'Hay Roll', iconPath: '${_base}decor_hay_roll.png', cost: 55, category: 'Farm'),
    DecorItemDef(id: 'decor_wheat_bundle', name: 'Wheat Bundle', iconPath: '${_base}decor_wheat_bundle.png', cost: 45, category: 'Farm'),
    DecorItemDef(id: 'decor_wheat_tied', name: 'Tied Wheat', iconPath: '${_base}decor_wheat_tied.png', cost: 45, category: 'Farm'),
    DecorItemDef(id: 'decor_barrel', name: 'Oak Barrel', iconPath: '${_base}decor_barrel.png', cost: 70, category: 'Structure'),
    DecorItemDef(id: 'decor_crate_wood', name: 'Wooden Crate', iconPath: '${_base}decor_crate_wood.png', cost: 40, category: 'Structure'),
    DecorItemDef(id: 'decor_crate_leafy', name: 'Veggie Crate', iconPath: '${_base}decor_crate_leafy.png', cost: 65, category: 'Farm'),
    DecorItemDef(id: 'decor_basket_tomato', name: 'Tomato Basket', iconPath: '${_base}decor_basket_tomato.png', cost: 55, category: 'Farm'),
    DecorItemDef(id: 'decor_basket_rope', name: 'Rope Basket', iconPath: '${_base}decor_basket_rope.png', cost: 50, category: 'Farm'),
    DecorItemDef(id: 'decor_basket_eggs_blue_cloth', name: 'Egg Basket', iconPath: '${_base}decor_basket_eggs_blue_cloth.png', cost: 60, category: 'Farm'),
    DecorItemDef(id: 'decor_basket_easter_eggs', name: 'Festive Eggs', iconPath: '${_base}decor_basket_easter_eggs.png', cost: 85, category: 'Farm'),
    DecorItemDef(id: 'decor_milk_can_tall', name: 'Tall Milk Can', iconPath: '${_base}decor_milk_can_tall.png', cost: 60, category: 'Farm'),
    DecorItemDef(id: 'decor_milk_can_short', name: 'Milk Can', iconPath: '${_base}decor_milk_can_short.png', cost: 55, category: 'Farm'),
    DecorItemDef(id: 'decor_flower_pot_pink', name: 'Pink Flower Pot', iconPath: '${_base}decor_flower_pot_pink.png', cost: 45, category: 'Garden'),
    DecorItemDef(id: 'decor_flower_crate', name: 'Flower Crate', iconPath: '${_base}decor_flower_crate.png', cost: 65, category: 'Garden'),
    DecorItemDef(id: 'decor_sunflower', name: 'Sunflower', iconPath: '${_base}decor_sunflower.png', cost: 50, category: 'Garden'),
    DecorItemDef(id: 'decor_sunflower_pot', name: 'Potted Sunflower', iconPath: '${_base}decor_sunflower_pot.png', cost: 55, category: 'Garden'),
    DecorItemDef(id: 'decor_bush_green', name: 'Green Bush', iconPath: '${_base}decor_bush_green.png', cost: 45, category: 'Garden'),
    DecorItemDef(id: 'decor_bush_flower_white', name: 'White Blossom Bush', iconPath: '${_base}decor_bush_flower_white.png', cost: 60, category: 'Garden'),
    DecorItemDef(id: 'decor_bush_flower_yellow', name: 'Yellow Blossom Bush', iconPath: '${_base}decor_bush_flower_yellow.png', cost: 60, category: 'Garden'),
    DecorItemDef(id: 'decor_feather_white', name: 'White Feather', iconPath: '${_base}decor_feather_white.png', cost: 30, category: 'Trinkets'),
    DecorItemDef(id: 'decor_feather_brown', name: 'Brown Feather', iconPath: '${_base}decor_feather_brown.png', cost: 30, category: 'Trinkets'),
  ];

  static DecorItemDef byId(String id) => all.firstWhere((e) => e.id == id);
}
