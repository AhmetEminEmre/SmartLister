
import 'package:isar/isar.dart';
import '../objects/shop.dart';
import 'package:smart/fakeDBs/shop_fake.dart';

class ShopService {
  final Isar? _isar;
  final FakeShopDB? _fakeDb;

  ShopService(Isar isar)
      : _isar = isar,
        _fakeDb = null;

  ShopService.fake(FakeShopDB fakeDb)
      : _fakeDb = fakeDb,
        _isar = null;

  Future<List<Einkaufsladen>> fetchShops() async {
    if (_fakeDb != null) return await _fakeDb.getAll();
    return await _isar!.einkaufsladens.where().findAll();
  }

  Future<int> addShop(Einkaufsladen shop) async {
    if (_fakeDb != null) {
      await _fakeDb.add(shop);
      return shop.id;
    }

    final id = await _isar!.writeTxn(() async {
      return await _isar!.einkaufsladens.put(shop);
    });
    return id;
  }

  Future<void> deleteShop(int shopId) async {
    if (_fakeDb != null) {
      await _fakeDb.delete(shopId);
      return;
    }

    await _isar!.writeTxn(() async {
      await _isar!.einkaufsladens.delete(shopId);
    });
  }

  Future<Einkaufsladen?> fetchShopById(int shopId) async {
    if (_fakeDb != null) return await _fakeDb.getById(shopId);
    return await _isar!.einkaufsladens.get(shopId);
  }

  Future<Einkaufsladen?> fetchShopByName(String name) async {
    if (_fakeDb != null) return await _fakeDb.getByName(name);
    return await _isar!.einkaufsladens.filter().nameEqualTo(name).findFirst();
  }

  Stream<void> watchShops() {
    return _isar!.einkaufsladens.watchLazy().asBroadcastStream();
  }

  Future<String> createUniqueShop(String shopName) async {
    String uniqueName = shopName;
    int counter = 1;

    while (true) {
      final existingShop = await fetchShopByName(uniqueName);

      if (existingShop == null) {
        return uniqueName;
      } else {
        uniqueName = "$shopName($counter)";
        counter++;
      }
    }
  }
}