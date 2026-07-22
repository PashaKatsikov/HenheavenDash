class KitchenTheme {
  const KitchenTheme({
    required this.id,
    required this.name,
    required this.backgroundPath,
    required this.unlockLevel,
  });

  final String id;
  final String name;
  final String backgroundPath;
  final int unlockLevel;
}

class KitchenCatalog {
  KitchenCatalog._();

  static const String _base = 'assets/images/backgrounds/';

  static const List<KitchenTheme> all = [
    KitchenTheme(id: 'rustic', name: 'Rustic Barn Kitchen', backgroundPath: '${_base}kitchen_rustic.webp', unlockLevel: 1),
    KitchenTheme(id: 'cottage', name: 'Cosy Cottage Kitchen', backgroundPath: '${_base}kitchen_cottage.webp', unlockLevel: 6),
    KitchenTheme(id: 'marble', name: 'Marble Farmhouse Kitchen', backgroundPath: '${_base}kitchen_marble.webp', unlockLevel: 11),
    KitchenTheme(id: 'manor', name: 'Sunlit Manor Kitchen', backgroundPath: '${_base}kitchen_manor.webp', unlockLevel: 16),
    KitchenTheme(id: 'stonehall', name: 'Grand Stone Hall Kitchen', backgroundPath: '${_base}kitchen_stonehall.webp', unlockLevel: 21),
    KitchenTheme(id: 'festival', name: 'Harvest Festival Kitchen', backgroundPath: '${_base}kitchen_festival.webp', unlockLevel: 26),
  ];

  static KitchenTheme forLevel(int level) {
    KitchenTheme result = all.first;
    for (final k in all) {
      if (level >= k.unlockLevel) result = k;
    }
    return result;
  }
}
