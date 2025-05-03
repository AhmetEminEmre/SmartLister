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

  test('addShop fügt neuen Shop hinzu', () async {
    final shop = Einkaufsladen(name: 'Billa 1030');
    final added = await service.addShop(shop);

    final all = await fakeDb.getAll();
    expect(all.length, 1);
    expect(all.first.name, 'Billa 1030');
    expect(added.id, 1);
  });

  test('deleteShop entfernt einen Shop', () async {
    final shop = Einkaufsladen(name: 'Spar')..id = 10;
    fakeDb.add(shop);

    await service.deleteShop(10);
    final remaining = await fakeDb.getAll();

    expect(remaining.isEmpty, true);
  });

  test('fetchShopById gibt richtigen Shop zurück', () async {
    final shop = Einkaufsladen(name: 'Merkur')..id = 42;
    fakeDb.add(shop);

    final result = await service.fetchShopById(42);
    expect(result?.name, 'Merkur');
    expect(result?.id, 42);
  });

  test('fetchShops gibt alle Shops zurück', () async {
    fakeDb.add(Einkaufsladen(name: 'Spar 1110'));
    fakeDb.add(Einkaufsladen(name: 'Hofer 1100'));

    final shops = await service.fetchShops();

    expect(shops.length, 2);
    expect(shops[0].name, 'Spar 1110');
    expect(shops[1].name, 'Hofer 1100');
  });
}
