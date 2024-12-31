import 'package:flutter_test/flutter_test.dart';

class Einkaufsladen {
  final String name;
  final List<Productgroup> productGroups = [];

  Einkaufsladen({required this.name});

  void addProductGroup(Productgroup group) {
    if (productGroups.any((g) => g.name == group.name)) {
      throw ArgumentError('Produktgruppe mit diesem Namen existiert bereits.');
    }
    productGroups.add(group);
  }

  Productgroup? getProductGroup(String name) {
    try {
      return productGroups.firstWhere((group) => group.name == name);
    } catch (e) {
      return null;
    }
  }

  void addDefaultProductGroups() {
    final defaultGroups = [
      'Obst & Gemüse',
      'Säfte',
      'Fleisch',
      'Fischprodukte',
    ];

    for (var groupName in defaultGroups) {
      if (productGroups.every((group) => group.name != groupName)) {
        productGroups
            .add(Productgroup(name: groupName, order: productGroups.length));
      }
    }
  }

  bool removeProductGroup(String name) {
    final length = productGroups.length;
    productGroups.removeWhere((group) => group.name == name);
    return productGroups.length < length;
  }
}

class Productgroup {
  final String name;
  final int order;

  Productgroup({
    required this.name,
    required this.order,
  });
}

void main() {
  group('Einkaufsladen und Produktgruppen Tests', () {
    late Einkaufsladen shop;

    setUp(() {
      // Arrange
      shop = Einkaufsladen(name: 'Supermarkt A');
    });

    test('Füge eine gültige Produktgruppe hinzu', () {
      // Arrange
      final group = Productgroup(name: 'Obst & Gemüse', order: 0);

      // Act
      shop.addProductGroup(group);

      // Assert
      expect(shop.productGroups.length, 1);
      expect(shop.productGroups.first.name, 'Obst & Gemüse');
    });

    test('Verhindere das Hinzufügen einer doppelten Produktgruppe', () {
      // Arrange
      final group = Productgroup(name: 'Obst & Gemüse', order: 0);
      shop.addProductGroup(group);

      // Act & Assert
      expect(() => shop.addProductGroup(group), throwsArgumentError);
    });

    test('Hole eine vorhandene Produktgruppe nach Namen', () {
      // Arrange
      final group = Productgroup(name: 'Obst & Gemüse', order: 0);
      shop.addProductGroup(group);

      // Act
      final retrievedGroup = shop.getProductGroup('Obst & Gemüse');

      // Assert
      expect(retrievedGroup, isNotNull);
      expect(retrievedGroup?.name, 'Obst & Gemüse');
    });

    test('Gebe null zurück, wenn eine Produktgruppe nicht existiert', () {
      // Act
      final retrievedGroup = shop.getProductGroup('Fleisch');

      // Assert
      expect(retrievedGroup, isNull);
    });

    test('Füge Standard-Produktgruppen hinzu', () {
      // Act
      shop.addDefaultProductGroups();

      // Assert
      expect(shop.productGroups.length, 4);
      expect(
        shop.productGroups.map((g) => g.name).toList(),
        containsAll(['Obst & Gemüse', 'Säfte', 'Fleisch', 'Fischprodukte']),
      );
    });

    test('Füge keine doppelten Standard-Produktgruppen hinzu', () {
      // Arrange
      shop.addProductGroup(Productgroup(name: 'Obst & Gemüse', order: 0));

      // Act
      shop.addDefaultProductGroups();

      // Assert
      expect(shop.productGroups.length, 4);
      expect(
        shop.productGroups.map((g) => g.name).toList(),
        containsAll(['Obst & Gemüse', 'Säfte', 'Fleisch', 'Fischprodukte']),
      );
    });

    test('Entferne eine Produktgruppe', () {
      // Arrange
      shop.addProductGroup(Productgroup(name: 'Obst & Gemüse', order: 0));

      // Act
      final removed = shop.removeProductGroup('Obst & Gemüse');

      // Assert
      expect(removed, isTrue);
      expect(shop.productGroups.length, 0);
    });

    test('Regressionstest: Sortiere Produktgruppen nach der order', () {
      // Arrange
      shop.addDefaultProductGroups();
      shop.addProductGroup(Productgroup(name: 'Milchprodukte', order: 0));

      // Act
      shop.productGroups.sort((a, b) => a.order.compareTo(b.order));

      // Assert
      expect(
        shop.productGroups.map((g) => g.name).toList(),
        equals([
          'Obst & Gemüse',
          'Milchprodukte',
          'Säfte',
          'Fleisch',
          'Fischprodukte'
        ]),
      );
    });
  });
}
