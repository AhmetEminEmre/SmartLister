import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:smart/objects/productgroup.dart';
import 'productgroup_service_test.mocks.dart';

void main() {
  late MockIsar mockIsar;
  late MockProductGroupService mockProductGroupService;
  late MockIsarCollection<Productgroup> mockProductGroups;

  setUp(() {
    mockIsar = MockIsar();
    mockProductGroups = MockIsarCollection<Productgroup>();
    when(mockIsar.productgroups).thenReturn(mockProductGroups);
    mockProductGroupService = MockProductGroupService();
  });

  test('fetchProductGroups - gibt eine Liste von Productgroup zurück', () async {
    // Arrange
    final mockGroups = [
      Productgroup(name: 'Obst', storeId: '1', order: 0),
      Productgroup(name: 'Gemüse', storeId: '1', order: 1),
    ];

    when(mockProductGroupService.fetchProductGroups('1'))
        .thenAnswer((_) async => mockGroups);

    // Act
    final result = await mockProductGroupService.fetchProductGroups('1');

    // Assert
    expect(result, isA<List<Productgroup>>());
    expect(result.length, equals(2));
    expect(result[0].name, 'Obst');
    expect(result[1].name, 'Gemüse');
  });

  test('addProductGroup - fügt eine neue Produktgruppe hinzu', () async {
    // Arrange
    final newGroup = Productgroup(name: 'Getränke', storeId: '1', order: 2);
    final mockGroups = <Productgroup>[];

    when(mockProductGroupService.addProductGroup(newGroup)).thenAnswer((_) async {
      mockGroups.add(newGroup);
    });

    // Act
    await mockProductGroupService.addProductGroup(newGroup);

    // Assert
    expect(mockGroups.length, 1);
    expect(mockGroups.first.name, 'Getränke');
    expect(mockGroups.first.storeId, '1');
    expect(mockGroups.first.order, 2);
  });

  test('deleteProductGroup - entfernt die Produktgruppe', () async {
    // Arrange
    final mockGroups = [
      Productgroup(name: 'Getränke', storeId: '1', order: 2),
      Productgroup(name: 'Obst', storeId: '1', order: 1),
    ];
    final groupToDelete = mockGroups[0];

    when(mockProductGroups.delete(any)).thenAnswer((_) async {
      mockGroups.removeWhere((group) => group.name == groupToDelete.name);
      return true;
    });

    when(mockProductGroupService.deleteProductGroup(any)).thenAnswer((_) async {
      await mockProductGroups.delete(groupToDelete.id);
    });

    // Act
    await mockProductGroupService.deleteProductGroup(groupToDelete.id);

    // Assert
    expect(mockGroups.any((group) => group.name == groupToDelete.name), false);
  });

  test('addDefaultProductGroups - fügt Standard-Produktgruppen hinzu', () async {
    // Arrange
    const storeId = '1';
    final mockGroups = [
      Productgroup(name: 'Getränke', storeId: '1', order: 2),
      Productgroup(name: 'Obst', storeId: '1', order: 1),
    ];

    when(mockProductGroupService.addDefaultProductGroups(storeId))
        .thenAnswer((_) async {
      mockGroups
          .add(Productgroup(name: 'Obst & Gemüse', storeId: storeId, order: 0));
      mockGroups.add(Productgroup(name: 'Säfte', storeId: storeId, order: 1));
      mockGroups.add(Productgroup(name: 'Fleisch', storeId: storeId, order: 2));
      mockGroups.add(Productgroup(name: 'Fisch', storeId: storeId, order: 3));
    });

    // Act
    await mockProductGroupService.addDefaultProductGroups(storeId);

    // Assert
    expect(mockGroups.length, 6);
    expect(
      mockGroups.map((group) => group.name).toSet(),
      containsAll(
          ['Getränke', 'Obst', 'Obst & Gemüse', 'Säfte', 'Fleisch', 'Fisch']),
    );
    expect(mockGroups.map((group) => group.name).toList(),
    equals(['Getränke', 'Obst', 'Obst & Gemüse', 'Säfte', 'Fleisch', 'Fisch']));
  });
}
