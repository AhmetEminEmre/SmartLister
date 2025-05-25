import 'package:flutter_test/flutter_test.dart';
import 'package:smart/services/shop_service.dart';
import 'package:smart/objects/shop.dart';
import 'package:smart/fakeDBs/shop_fake.dart';

void main() {
  late FakeShopDB fakeDb;
  late ShopService service;

  setUp(() {
    fakeDb = FakeShopDB();
    service = ShopService.fake(fakeDb);
  });

  test('addShop fügt Shop zur Liste hinzu', () async {
    final shop = Einkaufsladen(name: 'Billa');
    final id = await service.addShop(shop);

    final all = await fakeDb.getAll();
    expect(all.length, 1);
    expect(all.first.name, 'Billa');
    expect(id, 1);
  });

  test('fetchShops gibt alle Shops zurück', () async {
    await fakeDb.add(Einkaufsladen(name: 'Hofer'));
    await fakeDb.add(Einkaufsladen(name: 'Spar'));

    final result = await service.fetchShops();

    expect(result.length, 2);
    expect(result.map((s) => s.name), containsAll(['Hofer', 'Spar']));
  });

  test('deleteShop entfernt Shop korrekt', () async {
    final shop = Einkaufsladen(name: 'Lidl')..id = 10;
    await fakeDb.add(shop);

    await service.deleteShop(10);
    final remaining = await fakeDb.getAll();

    expect(remaining, isEmpty);
  });

  test('fetchShopById findet den richtigen Shop', () async {
    final shop = Einkaufsladen(name: 'Merkur')..id = 5;
    await fakeDb.add(shop);

    final result = await service.fetchShopById(5);
    expect(result?.name, 'Merkur');
    expect(result?.id, 5);
  });

  test('fetchShopByName findet den Shop anhand des Namens', () async {
    await fakeDb.add(Einkaufsladen(name: 'Etsan'));

    final result = await service.fetchShopByName('Etsan');
    expect(result?.name, 'Etsan');
  });

  test('createUniqueShop hängt Zähler an, wenn Name existiert', () async {
    await fakeDb.add(Einkaufsladen(name: 'Billa'));
    await fakeDb.add(Einkaufsladen(name: 'Billa(1)'));
    await fakeDb.add(Einkaufsladen(name: 'Billa(2)'));

    final uniqueName = await service.createUniqueShop('Billa');
    expect(uniqueName, 'Billa(3)');
  });

  test('createUniqueShop gibt Originalnamen zurück, wenn er noch frei ist', () async {
    final uniqueName = await service.createUniqueShop('Interspar');
    expect(uniqueName, 'Interspar');
  });
}
