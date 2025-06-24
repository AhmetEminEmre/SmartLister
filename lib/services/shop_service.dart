import 'package:isar/isar.dart';
import '../objects/shop.dart';
import 'package:smart/fakeDBs/shop_fake.dart';

class ShopService {
  final Isar? _isar;
  final FakeShopDB? _fakeDb;

  // coverage:ignore-start
  ShopService(Isar isar)
      : _isar = isar,
        _fakeDb = null;
  // coverage:ignore-end

  ShopService.fake(FakeShopDB fakeDb)
      : _fakeDb = fakeDb,
        _isar = null;

  Future<List<Einkaufsladen>> fetchShops() async {
    if (_fakeDb != null) return await _fakeDb.getAll();
    // coverage:ignore-start
    return await _isar!.einkaufsladens.where().findAll();
    // coverage:ignore-end
  }

  Future<int> addShop(Einkaufsladen shop) async {
    if (_fakeDb != null) {
      await _fakeDb.add(shop);
      return shop.id;
    }
    // coverage:ignore-start
    final id = await _isar!.writeTxn(() async {
      return await _isar.einkaufsladens.put(shop);
    });
    return id;
    // coverage:ignore-end
  }

  Future<void> deleteShop(int shopId) async {
    if (_fakeDb != null) {
      await _fakeDb.delete(shopId);
      return;
    }
    // coverage:ignore-start
    await _isar!.writeTxn(() async {
      await _isar.einkaufsladens.delete(shopId);
    });
    // coverage:ignore-end
  }

  Future<Einkaufsladen?> fetchShopById(int shopId) async {
    if (_fakeDb != null) return await _fakeDb.getById(shopId);
    // coverage:ignore-start
    return await _isar!.einkaufsladens.get(shopId);
    // coverage:ignore-end
  }

  Future<Einkaufsladen?> fetchShopByName(String name) async {
    if (_fakeDb != null) return await _fakeDb.getByName(name);
    // coverage:ignore-start
    return await _isar!.einkaufsladens.filter().nameEqualTo(name).findFirst();
    // coverage:ignore-end
  }

  // coverage:ignore-start
  Future<void> updateExcludedItemsById(int shopId, String rawItems) async {
    final cleanItems = rawItems.contains(',')
        ? rawItems
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .join(',')
        : rawItems.trim();

    final shop = await fetchShopById(shopId);
    if (shop != null) {
      shop.excludedItems = cleanItems;
      await updateShop(shop);
    } else {
      print('not found');
    }
    // coverage:ignore-end
  }

   // coverage:ignore-start
  Future<String?> getExcludedItemsById(int shopId) async {
    if (_fakeDb != null) {
      final shop = await _fakeDb.getById(shopId);
      return shop?.excludedItems;
    }
    final shop = await fetchShopById(shopId);
    return shop?.excludedItems;
    // coverage:ignore-end
  }

  // coverage:ignore-start
  Future<void> updateShop(Einkaufsladen shop) async {
    if (_fakeDb != null) {
      await _fakeDb.updateShop(shop);
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar.einkaufsladens.put(shop);
    });
    // coverage:ignore-end
  }

  // coverage:ignore-start
  Stream<void> watchShops() {
    return _isar!.einkaufsladens.watchLazy().asBroadcastStream();
    // coverage:ignore-end
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
