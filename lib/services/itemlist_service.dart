import 'package:isar/isar.dart';
import '../objects/itemlist.dart';

class ItemListService {
  final Isar _isar;

  ItemListService(this._isar);

  Future<void> addItemList(Itemlist list) async {
    await _isar.writeTxn(() async {
      await _isar.itemlists.put(list);
    });
  }

  Future<List<Itemlist>> fetchAllItemLists() async {
    return await _isar.itemlists.where().findAll();
  }

  Future<Itemlist?> fetchItemListById(int id) async {
    return await _isar.itemlists.get(id);
  }

  Future<List<Itemlist>> fetchItemListsByShopId(String shopId) async {
  return await _isar.itemlists
      .filter()
      .shopIdEqualTo(shopId)
      .findAll();
}

  Future<void> updateItemList(Itemlist list) async {
    await _isar.writeTxn(() async {
      await _isar.itemlists.put(list);
    });
  }

  Future<void> deleteItemList(int id) async {
    await _isar.writeTxn(() async {
      await _isar.itemlists.delete(id);
    });
  }

  Stream<void> watchItemLists() {
    return _isar.itemlists.watchLazy().asBroadcastStream();
  }


}
