import 'package:flutter_test/flutter_test.dart';
import 'package:smart/objects/itemlist.dart';
import 'package:smart/services/itemlist_service.dart';
import 'package:smart/fakeDBs/itemlist_fake.dart';

void main() {
  late FakeItemListDB fakeDb;
  late ItemListService service;

 setUp(() {
    fakeDb = FakeItemListDB();
    service = ItemListService.fake(fakeDb);
  });

  test('addItemList speichert Liste', () async {
    final list = Itemlist(
      name: 'TestList',
      shopId: 'shop1',
      items: [],
      creationDate: DateTime.now(),
    )..id = 1;

    await service.addItemList(list);
    final all = await service.fetchAllItemLists();
    expect(all.any((l) => l.name == 'TestList'), true);
  });

  test('fetchAllItemLists gibt alle Listen zurück', () async {
    await service.addItemList(Itemlist(
      name: 'A',
      shopId: '1',
      imagePath: 'img/a.png',
      items: [],
      creationDate: DateTime.now(),
    ));
    await service.addItemList(Itemlist(
      name: 'B',
      shopId: '1',
      imagePath: 'img/b.png',
      items: [],
      creationDate: DateTime.now(),
    ));

    final result = await service.fetchAllItemLists();
    expect(result.length, 2);
  });

  test('fetchItemListsByShopId filtert korrekt', () async {
    await service.addItemList(Itemlist(
      name: 'X',
      shopId: '2',
      imagePath: 'lib/img/default_image.png',
      items: [],
      creationDate: DateTime.now(),
    ));
    await service.addItemList(Itemlist(
      name: 'Y',
      shopId: '3',
      imagePath: 'lib/img/default_image.png',
      items: [],
      creationDate: DateTime.now(),
    ));

    final result = await service.fetchItemListsByShopId('2');
    expect(result.length, 1);
    expect(result.first.name, 'X');
  });

  test('updateItemList ersetzt vorhandene Liste', () async {
    final list = Itemlist(
      name: 'Alt',
      shopId: '1',
      imagePath: 'lib/img/default_image.png',
      items: [],
      creationDate: DateTime.now(),
    )..id = 5;

    await service.addItemList(list);

    final updated = Itemlist(
      name: 'Neu',
      shopId: '1',
      imagePath: 'lib/img/default_image.png',
      items: [],
      creationDate: DateTime.now(),
    )..id = 5;

    await service.updateItemList(updated);

    final result = await service.fetchItemListById(5);
    expect(result?.name, 'Neu');
  });

  test('deleteItemList entfernt Liste', () async {
    final list = Itemlist(
      name: 'Weg',
      shopId: '1',
      imagePath: 'lib/img/default_image.png',
      items: [],
      creationDate: DateTime.now(),
    )..id = 9;

    await service.addItemList(list);

    await service.deleteItemList(9);
    final result = await service.fetchItemListById(9);
    expect(result, isNull);
  });
}
