import 'package:flutter_test/flutter_test.dart';
import 'package:smart/objects/productgroup.dart';
import 'package:smart/services/productgroup_service.dart';
import 'package:smart/fakeDBs/productgroup_fake.dart';

void main() {
  late FakeProductgroupDB fakeDb;
  late ProductGroupService service;

  setUp(() {
    fakeDb = FakeProductgroupDB();
    service = ProductGroupService.fake(fakeDb);
  });

  test('addProductGroup + fetchGroupById', () async {
    final group = Productgroup(name: 'Obst', storeId: '1', order: 0);
    final id = await service.addProductGroup(group);

    final result = await service.fetchGroupById(id);
    expect(result?.name, 'Obst');
  });

  test('deleteProductGroup entfernt Gruppe', () async {
    final group = Productgroup(name: 'Milch', storeId: '1', order: 0)..id = 1;
    await service.addProductGroup(group);
    await service.deleteProductGroup(1);
    final result = await service.fetchGroupById(1);

    expect(result, isNull);
  });

  test('fetchLastGroupByStoreId gibt letzte sortierte Gruppe zurück', () async {
    await service.addProductGroup(Productgroup(name: 'A', storeId: '1', order: 0));
    await service.addProductGroup(Productgroup(name: 'B', storeId: '1', order: 1));

    final result = await service.fetchLastGroupByStoreId('1');
    expect(result?.name, 'B');
  });

  test('fetchProductGroupsByStoreIdSorted sortiert korrekt', () async {
    await service.addProductGroup(Productgroup(name: 'X', storeId: 's1', order: 1));
    await service.addProductGroup(Productgroup(name: 'Y', storeId: 's1', order: 0));

    final result = await service.fetchProductGroupsByStoreIdSorted('s1');
    expect(result[0].name, 'Y');
    expect(result[1].name, 'X');
  });

  test('fetchByNameAndShop findet richtige Gruppe', () async {
    await service.addProductGroup(Productgroup(name: 'Getränke', storeId: '100', order: 0));

    final result = await service.fetchByNameAndShop('Getränke', '100');

    expect(result?.name, 'Getränke');
    expect(result?.storeId, '100');
  });

  test('updateProductGroupOrder aktualisiert Reihenfolge', () async {
    final g1 = Productgroup(name: 'Z', storeId: '2', order: 5);
    final g2 = Productgroup(name: 'A', storeId: '2', order: 2);
    await service.addProductGroup(g1);
    await service.addProductGroup(g2);

    final all = await service.fetchProductGroupsByStoreIdSorted('2');
    all.sort((a, b) => a.name.compareTo(b.name));
    await service.updateProductGroupOrder(all);

    final updated = await service.fetchProductGroupsByStoreIdSorted('2');
    expect(updated[0].order, 0);
    expect(updated[1].order, 1);
  });

    test('fetchProductGroups gibt gefilterte & sortierte Produktgruppen zurück',
      () async {
    await service
        .addProductGroup(Productgroup(name: 'Obst', storeId: '1', order: 1));
    await service.addProductGroup(
        Productgroup(name: 'Getränke', storeId: '1', order: 0));
    await service
        .addProductGroup(Productgroup(name: 'Fremd', storeId: '2', order: 0));

    final result = await service.fetchProductGroupsByStoreIdSorted('1');

    expect(result.length, 2);
    expect(result[0].name, 'Getränke');
    expect(result[1].name, 'Obst');
  });

  test('addProductGroup fügt neue Produktgruppe hinzu', () async {
    final group = Productgroup(name: 'Milch', storeId: '1', order: 0);
    await service.addProductGroup(group);

    final all = await service.fetchProductGroupsByStoreIdSorted('1');
    expect(all.length, 1);
    expect(all[0].name, 'Milch');
  });

  test('deleteProductGroup entfernt Produktgruppe', () async {
    final group = Productgroup(name: 'Käse', storeId: '1', order: 0)..id = 42;
    await service.addProductGroup(group);

    await service.deleteProductGroup(42);

    final remaining = await service.fetchProductGroupsByStoreIdSorted('1');
    expect(remaining.isEmpty, true);
  });

  test('fetchProductGroupById liefert korrekte Produktgruppe', () async {
    final group = Productgroup(name: 'Joghurt', storeId: '1', order: 0)
      ..id = 99;
    await service.addProductGroup(group);

    final result = await service.fetchGroupById(99);

    expect(result?.name, 'Joghurt');
    expect(result?.id, 99);
  });

  test('updateProductGroupOrder sortiert Produktgruppen korrekt', () async {
    final g1 = Productgroup(name: 'Z', storeId: '1', order: 2);
    final g2 = Productgroup(name: 'A', storeId: '1', order: 0);
    final g3 = Productgroup(name: 'M', storeId: '1', order: 1);

    await service.addProductGroup(g1);
    await service.addProductGroup(g2);
    await service.addProductGroup(g3);

    final unsorted = await service.fetchProductGroupsByStoreIdSorted('1');
    unsorted.sort((a, b) => a.name.compareTo(b.name));

    await service.updateProductGroupOrder(unsorted);

    final result = await service.fetchProductGroupsByStoreIdSorted('1');
    expect(result[0].order, 0);
    expect(result[1].order, 1);
    expect(result[2].order, 2);
  });

}
