import 'package:isar/isar.dart';
import 'package:smart/objects/shop.dart';

class FakeShopDB {
  final List<Einkaufsladen> _shops = [];
  int _nextId = 1;

  Future<List<Einkaufsladen>> getAll() async {
    return List<Einkaufsladen>.from(_shops);
  }

  Future<Einkaufsladen?> getById(int id) async {
    return _shops.firstWhere((s) => s.id == id);
  }

  Future<void> add(Einkaufsladen shop) async {
    if (shop.id == Isar.autoIncrement || shop.id == 0) {
      shop.id = _nextId++;
    } else {
      _shops.removeWhere((s) => s.id == shop.id);
    }
    _shops.add(shop);
  }

  Future<void> delete(int id) async {
    _shops.removeWhere((s) => s.id == id);
  }

  Future<Einkaufsladen?> getByName(String name) async {
    try {
      return _shops.firstWhere((s) => s.name == name);
    } catch (e) {
      return null;
    }
  }

//coverage:ignore-start
  Future<void> updateExcludedItems(int shopId, String excludedItems) async {
  final index = _shops.indexWhere((s) => s.id == shopId);
  if (index != -1) {
    _shops[index].excludedItems = excludedItems;
  }
}
//coverage:ignore-end

  //coverage:ignore-start
  Future<void> updateShop(Einkaufsladen shop) async {
    final index = _shops.indexWhere((s) => s.id == shop.id);
    if (index != -1) {
      _shops[index] = shop;
    } 
  }
  // coverage:ignore-end


}