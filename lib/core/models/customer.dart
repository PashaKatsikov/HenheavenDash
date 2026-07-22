class CustomerType {
  const CustomerType({
    required this.id,
    required this.name,
    required this.portraitPath,
    required this.patienceMultiplier,
    required this.tipMultiplier,
  });

  final String id;
  final String name;
  final String portraitPath;

  /// >1 = more patient than average, <1 = impatient (needs faster service).
  final double patienceMultiplier;

  /// >1 = tips more generously on a great serve.
  final double tipMultiplier;
}

class CustomerCatalog {
  CustomerCatalog._();

  static const String _base = 'assets/images/clients/';

  static const List<CustomerType> all = [
    CustomerType(id: 'sheep', name: 'Woolly', portraitPath: '${_base}client_sheep.png', patienceMultiplier: 1.25, tipMultiplier: 1.0),
    CustomerType(id: 'cow', name: 'Bessie', portraitPath: '${_base}client_cow.png', patienceMultiplier: 1.15, tipMultiplier: 1.0),
    CustomerType(id: 'duck', name: 'Quackers', portraitPath: '${_base}client_duck.png', patienceMultiplier: 1.0, tipMultiplier: 1.1),
    CustomerType(id: 'pig', name: 'Truffles', portraitPath: '${_base}client_pig.png', patienceMultiplier: 0.95, tipMultiplier: 1.15),
    CustomerType(id: 'rabbit', name: 'Clover', portraitPath: '${_base}client_rabbit.png', patienceMultiplier: 0.85, tipMultiplier: 1.2),
    CustomerType(id: 'goat', name: 'Pepper', portraitPath: '${_base}client_goat.png', patienceMultiplier: 0.9, tipMultiplier: 1.1),
    CustomerType(id: 'rooster', name: 'Cluck', portraitPath: '${_base}client_rooster.png', patienceMultiplier: 0.8, tipMultiplier: 1.25),
    CustomerType(id: 'cat', name: 'Whiskers', portraitPath: '${_base}client_cat.png', patienceMultiplier: 0.75, tipMultiplier: 1.3),
    CustomerType(id: 'dog', name: 'Buddy', portraitPath: '${_base}client_dog.png', patienceMultiplier: 1.05, tipMultiplier: 1.1),
    CustomerType(id: 'hedgehog', name: 'Spike', portraitPath: '${_base}client_hedgehog.png', patienceMultiplier: 0.7, tipMultiplier: 1.35),
  ];
}
