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

  test('fetchProductGroups gibt gefilterte & sortierte Produktgruppen zurück', () async {
    await service.addProductGroup(Productgroup(name: 'Obst', storeId: '1', order: 1));
    await service.addProductGroup(Productgroup(name: 'Getränke', storeId: '1', order: 0));
    await service.addProductGroup(Productgroup(name: 'Fremd', storeId: '2', order: 0));

    final result = await service.fetchProductGroups('1');

    expect(result.length, 2);
    expect(result[0].name, 'Getränke');
    expect(result[1].name, 'Obst');
  });

  test('addProductGroup fügt neue Produktgruppe hinzu', () async {
    final group = Productgroup(name: 'Milch', storeId: '1', order: 0);
    await service.addProductGroup(group);

    final all = await service.fetchProductGroups('1');
    expect(all.length, 1);
    expect(all[0].name, 'Milch');
  });

  test('deleteProductGroup entfernt Produktgruppe', () async {
    final group = Productgroup(name: 'Käse', storeId: '1', order: 0)..id = 42;
    await service.addProductGroup(group);

    await service.deleteProductGroup(42);

    final remaining = await service.fetchProductGroups('1');
    expect(remaining.isEmpty, true);
  });

  test('fetchProductGroupById liefert korrekte Produktgruppe', () async {
    final group = Productgroup(name: 'Joghurt', storeId: '1', order: 0)..id = 99;
    await service.addProductGroup(group);

    final result = await service.fetchProductGroupById(99);

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

    final unsorted = await service.fetchProductGroups('1');
    unsorted.sort((a, b) => a.name.compareTo(b.name));

    await service.updateProductGroupOrder(unsorted);

    final result = await service.fetchProductGroups('1');
    expect(result[0].order, 0);
    expect(result[1].order, 1);
    expect(result[2].order, 2);
  });
}
