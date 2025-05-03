import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:smart/objects/shop.dart';
import 'shop_service_test.mocks.dart';

void main() {
  late MockIsar mockIsar;
  late MockShopService mockShopService;
  late MockIsarCollection<Einkaufsladen> mockShops;

  setUp(() {
    mockIsar = MockIsar();
    mockShops = MockIsarCollection<Einkaufsladen>();
    when(mockIsar.einkaufsladens).thenReturn(mockShops);
    mockShopService = MockShopService();
  });

  test('fetchShops - gibt eine Liste von Einkaufsladen zurück', () async {
    // Arrange
    final mockShops = [
      Einkaufsladen(name: 'Spar 1110'),
      Einkaufsladen(name: 'Hofer 1100'),
    ];

    when(mockShopService.fetchShops()).thenAnswer((_) async => mockShops);

    // Act
    final result = await mockShopService.fetchShops();

    // Assert
    expect(result, isA<List<Einkaufsladen>>());
    expect(result.length, equals(2));
    expect(result[0].name, 'Spar 1110');
    expect(result[1].name, 'Hofer 1100');
  });

  test('addShop - fügt einen neuen Einkaufsladen hinzu', () async {
    // Arrange
    final newShop = Einkaufsladen(name: 'Billa 1030');
    final mockShops = <Einkaufsladen>[];

    when(mockShopService.addShop(newShop)).thenAnswer((_) async {
      newShop.id = 1 +1;
      mockShops.add(newShop);
      return newShop;
    });

    // Act
    final result = await mockShopService.addShop(newShop);

    // Assert
    expect(result.name, 'Billa 1030');
    expect(result.id, 1);
  });

  test('deleteShop - entfernt einen Einkaufsladen', () async {
    // Arrange
    final mockShops = [
      Einkaufsladen(name: 'Spar 1080'),
      Einkaufsladen(name: 'Hofer 1110'),
    ];
    final groupToDelete = mockShops[0];

    when(mockShopService.deleteShop(groupToDelete.id)).thenAnswer((_) async {
      mockShops.removeWhere((group) => group.name == groupToDelete.name);
    });

    // Act
    await mockShopService.deleteShop(groupToDelete.id);

    // Assert
    expect(mockShops.any((group) => group.name == groupToDelete.name), false);
  });

  test('fetchShopById - gibt einen Einkaufsladen anhand der ID zurück', () async {
    // Arrange
    const shopId = 1;
    final mockShop = Einkaufsladen(name: 'Spar Mariahilferstraße');
    when(mockShopService.fetchShopById(shopId)).thenAnswer((_) async => mockShop);

    // Act
    final result = await mockShopService.fetchShopById(shopId);

    // Assert
    expect(result, isNotNull);
    expect(result?.name, 'Spar Mariahilferstraße');
  });
}
