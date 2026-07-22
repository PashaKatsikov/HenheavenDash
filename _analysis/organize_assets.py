import os
import shutil

ROOT = r'D:\flutter_proj\Henhaven_Dash'
SRC_ASSETS = os.path.join(ROOT, 'asstets')
SRC_SOUNDS = os.path.join(ROOT, 'sounds')
SLICED = os.path.join(ROOT, '_analysis', 'sliced')
DST = os.path.join(ROOT, 'assets')

def copy(src, dst):
    shutil.copyfile(src, dst)

# 1. Backgrounds (kept as webp, Flutter decodes natively) -----------------
bg_map = {
    'bg1_asset.webp': 'kitchen_rustic.webp',
    'bg2_asset.webp': 'kitchen_marble.webp',
    'bg3_asset.webp': 'farmyard_exterior.webp',
    'bg4_asset.webp': 'kitchen_cottage.webp',
    'bg5_asset.webp': 'kitchen_manor.webp',
    'bg6_asset.webp': 'kitchen_festival.webp',
    'bg7_asset.webp': 'kitchen_stonehall.webp',
}
for src, dst in bg_map.items():
    copy(os.path.join(SRC_ASSETS, src), os.path.join(DST, 'images', 'backgrounds', dst))

# 2. UI / loading screens ---------------------------------------------------
ui_map = {
    'Horizontal_Loading_Screen.webp': 'loading_landscape.webp',
    'Vertical_Loading_Screen.webp': 'loading_portrait.webp',
}
for src, dst in ui_map.items():
    copy(os.path.join(SRC_ASSETS, src), os.path.join(DST, 'images', 'ui', dst))

# 3. Chef poses --------------------------------------------------------------
chef_names = [
    'idle', 'holding_pan', 'serving_plate', 'holding_spoon', 'holding_egg',
    'thinking', 'shocked', 'holding_burger', 'idle_alt', 'celebrating',
]
for i, name in enumerate(chef_names):
    copy(os.path.join(SLICED, 'chicken_asset', f'{i:02d}.png'),
         os.path.join(DST, 'images', 'chef', f'chef_{name}.png'))

# 4. Client portraits ---------------------------------------------------------
client_names = ['cow', 'rabbit', 'sheep', 'pig', 'duck', 'rooster', 'goat', 'cat', 'dog', 'hedgehog']
for i, name in enumerate(client_names):
    copy(os.path.join(SLICED, 'clients_asset', f'{i:02d}.png'),
         os.path.join(DST, 'images', 'clients', f'client_{name}.png'))

# 5. Food / dish icons ---------------------------------------------------------
food_names = [
    'fried_egg', 'fried_egg_teal', 'scrambled_eggs', 'omelet_plain', 'omelet_veggie',
    'boiled_eggs', 'egg_sandwich', 'egg_toast', 'pancake_egg_stack', 'full_breakfast',
    'egg_muffins', 'eggs_benedict', 'shakshuka', 'avocado_egg_toast', 'scrambled_veggie_plate',
]
for i, name in enumerate(food_names):
    copy(os.path.join(SLICED, 'foods_asset', f'{i:02d}.png'),
         os.path.join(DST, 'images', 'food', f'food_{name}.png'))

# 6. Ingredients ----------------------------------------------------------------
ingredient_names = [
    'egg_white_raw', 'egg_brown_raw', 'egg_golden_raw', 'eggshell_left', 'eggshell_right',
    'egg_yolk', 'egg_white_liquid', 'tomato', 'basil', 'parsley',
    'mushroom', 'bell_pepper', 'butter', 'cheese_wedge', 'onion',
    'flour_bowl', 'bread_slices', 'egg_bowl', 'cream_bowl', 'cheese_shredded_bowl',
    'tomato_diced_bowl',
]
for i, name in enumerate(ingredient_names):
    copy(os.path.join(SLICED, 'cooking_ingredients_asset', f'{i:02d}.png'),
         os.path.join(DST, 'images', 'ingredients', f'ing_{name}.png'))

# 7. Kitchen equipment / furniture -------------------------------------------------
kitchen_names = [
    'pan_black', 'pan_copper', 'board_square', 'board_round', 'pot_blue',
    'pot_red', 'pot_green', 'board_square_dark', 'bowl_blue', 'bowl_cream',
    'bowl_red_dots', 'spatula_metal', 'spoon_wood', 'spoon_slotted', 'spatula_wood',
    'tray_round', 'tray_rect', 'baking_dish', 'counter_sink_cream', 'oven_stone',
    'stove_cream', 'stove_blue', 'counter_sink_cream_alt', 'cabinet_green', 'basket_eggs_brown',
    'basket_eggs_white', 'shelf_spices_wood', 'shelf_spices_purple', 'jar_wheat', 'jar_cube',
    'sack_flour', 'oil_bottle', 'pepper_mill', 'salt_shaker', 'timer_red',
    'timer_blue', 'serving_bell', 'crate_eggs',
]
for i, name in enumerate(kitchen_names):
    copy(os.path.join(SLICED, 'rustic_farm_kitchen_asset', f'{i:02d}.png'),
         os.path.join(DST, 'images', 'kitchen', f'kit_{name}.png'))

# 8. Decorative elements -----------------------------------------------------------
decor_names = [
    'wheat_bundle', 'wheat_tied', 'hay_roll', 'barrel', 'feather_white',
    'flower_pot_pink', 'milk_can_tall', 'basket_rope', 'crate_wood', 'feather_brown',
    'lantern', 'signpost', 'sunflower', 'basket_tomato', 'fence',
    'bush_flower_white', 'bush_green', 'hay_bale', 'milk_can_short', 'sunflower_pot',
    'basket_easter_eggs', 'flower_crate', 'basket_eggs_blue_cloth', 'crate_leafy', 'bush_flower_yellow',
]
for i, name in enumerate(decor_names):
    copy(os.path.join(SLICED, 'decorative_elements_asset', f'{i:02d}.png'),
         os.path.join(DST, 'images', 'decor', f'decor_{name}.png'))

# 9. Effects (kept generically indexed - too many small VFX pieces) -----------------
eff_dir = os.path.join(SLICED, 'effects_asset')
for f in sorted(os.listdir(eff_dir), key=lambda x: int(x.split('.')[0])):
    idx = int(f.split('.')[0])
    copy(os.path.join(eff_dir, f), os.path.join(DST, 'images', 'effects', f'fx_{idx:02d}.png'))

# 10. Rewards / currency icons --------------------------------------------------------
reward_names = [
    'coin_stack_a', 'coin_sack_tan', 'coin_sack_brown', 'coin_single', 'coin_stack_b',
    'coin_pile_a', 'coin_pile_b', 'chest_closed', 'chest_open_a', 'chest_open_b',
    'chest_open_c', 'egg_gold_a', 'egg_gold_b', 'egg_gold_scaled', 'star_a',
    'star_b', 'star_cushion', 'medal_gold', 'medal_red_ribbon', 'medal_purple_ribbon',
    'medal_hex_purple', 'medal_wreath',
]
for i, name in enumerate(reward_names):
    copy(os.path.join(SLICED, 'rewards_collection_asset', f'{i:02d}.png'),
         os.path.join(DST, 'images', 'rewards', f'rw_{name}.png'))

# 11. App icon ------------------------------------------------------------------------
copy(os.path.join(SRC_ASSETS, 'Icon.png'), os.path.join(DST, 'icon', 'icon_source.png'))

# 12. Sounds ----------------------------------------------------------------------------
sound_map = {
    'click_button_asset.mp3': 'click.mp3',
    'collecting_gold_coins_asset.mp3': 'coin_collect.mp3',
    'completed_cooking_asset.mp3': 'cooking_complete.mp3',
    'cooking_sound_effect_asset.mp3': 'cooking_loop.mp3',
    'drag_item_sound_effect_asset.mp3': 'drag_item.mp3',
    'failure_lose_asset.mp3': 'lose.mp3',
    'happy_customer_asset.mp3': 'happy_customer.mp3',
    'incorrect_action_asset.mp3': 'incorrect.mp3',
    'lvl_complete_asset.mp3': 'level_complete.mp3',
    'receiving_generous_tips_asset.mp3': 'tips_received.mp3',
    'starting_to_cook_asset.mp3': 'cooking_start.mp3',
    'successfully_serving_asset.mp3': 'serve_success.mp3',
    'unlock_sound_effect_for_discovering_a_new_asset.mp3': 'unlock.mp3',
    'upgrade_sound_effect_asset.mp3': 'upgrade.mp3',
    'warning_sound_effect_asset.mp3': 'warning.mp3',
    'win_victory_asset.mp3': 'win.mp3',
}
for src, dst in sound_map.items():
    copy(os.path.join(SRC_SOUNDS, src), os.path.join(DST, 'sounds', dst))

print('Asset organization complete.')
for cat in ['backgrounds', 'ui', 'chef', 'clients', 'food', 'ingredients', 'kitchen', 'decor', 'effects', 'rewards']:
    p = os.path.join(DST, 'images', cat)
    print(cat, len(os.listdir(p)))
print('sounds', len(os.listdir(os.path.join(DST, 'sounds'))))
