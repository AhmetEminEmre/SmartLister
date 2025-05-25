import 'package:smart/objects/itemlist.dart';
import 'package:isar/isar.dart';

class FakeItemListDB {
  final List<Itemlist> _lists = [];
  int _nextId = 1;

  Future<void> add(Itemlist list) async {
    if (list.id == Isar.autoIncrement || list.id == 0) {
      list.id = _nextId++;
    } else {
      _lists.removeWhere((e) => e.id == list.id);
    }
    _lists.add(list);
  }

  Future<List<Itemlist>> getAll() async => List.of(_lists);

  Future<Itemlist?> getById(int id) async {
    try {
      return _lists.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
  }
  }

  Future<List<Itemlist>> getByShopId(String shopId) async =>
      _lists.where((e) => e.shopId == shopId).toList();

  Future<void> update(Itemlist list) async => add(list);

  Future<void> delete(int id) async {
    _lists.removeWhere((e) => e.id == id);
  }
}
