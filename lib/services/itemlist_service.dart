import 'package:isar/isar.dart';
import '../objects/itemlist.dart';
import 'package:smart/fakeDBs/itemlist_fake.dart';

class ItemListService {
  final Isar? _isar;
  final FakeItemListDB? _fakeDb;

  // coverage:ignore-start
  ItemListService(this._isar) : _fakeDb = null;
  // coverage:ignore-end
  ItemListService.fake(FakeItemListDB fakeDb)
      : _fakeDb = fakeDb,
        _isar = null;

  Future<void> addItemList(Itemlist list) async {
    if (_fakeDb != null) {
      await _fakeDb.add(list);
      return;
    }
    // coverage:ignore-start
    await _isar!.writeTxn(() async {
      await _isar.itemlists.put(list);
    });
    // coverage:ignore-end
  }

  Future<List<Itemlist>> fetchAllItemLists() async {
    if (_fakeDb != null) {
      return _fakeDb.getAll();
    }
    // coverage:ignore-start
    return await _isar!.itemlists.where().findAll();
    // coverage:ignore-end
  }

  Future<Itemlist?> fetchItemListById(int id) async {
    if (_fakeDb != null) {
      return await _fakeDb!.getById(id);
    }
    // coverage:ignore-start
    return await _isar!.itemlists.get(id);
    // coverage:ignore-end
  }

  Future<List<Itemlist>> fetchItemListsByShopId(String shopId) async {
    if (_fakeDb != null) {
      return await _fakeDb.getByShopId(shopId);
    }

    // coverage:ignore-start
    return await _isar!.itemlists.filter().shopIdEqualTo(shopId).findAll();
    // coverage:ignore-end
  }

  Future<void> updateItemList(Itemlist list) async {
    if (_fakeDb != null) {
      await _fakeDb.update(list);
      return;
    }
    // coverage:ignore-start
    await _isar!.writeTxn(() async {
      await _isar.itemlists.put(list);
    });
    // coverage:ignore-end
  }

  Future<void> deleteItemList(int id) async {
    if (_fakeDb != null) {
      await _fakeDb.delete(id);
      return;
    }

    // coverage:ignore-start
    await _isar!.writeTxn(() async {
      await _isar.itemlists.delete(id);
    });
    // coverage:ignore-end
  }

  // coverage:ignore-start
  Stream<void> watchItemLists() {
    return _isar!.itemlists.watchLazy().asBroadcastStream();
  }
  // coverage:ignore-end
}
