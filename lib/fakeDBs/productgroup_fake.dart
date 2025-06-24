import 'package:smart/objects/productgroup.dart';
import 'package:isar/isar.dart';

class FakeProductgroupDB {
  final List<Productgroup> _items = [];
  int _nextId = 1;

  Future<List<Productgroup>> getFilteredSorted(String storeId) async {
    final result = _items.where((g) => g.storeId == storeId).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  Future<Productgroup?> get(int id) async {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
  
  Future<void> add(Productgroup g) async {
    if (g.id == Isar.autoIncrement || g.id == 0) {
      g.id = _nextId++;
    } else {
      _items.removeWhere((e) => e.id == g.id);
    }
    _items.add(g);
  }

  Future<void> delete(int id) async {
    _items.removeWhere((e) => e.id == id);
  }

  Future<Productgroup?> getByNameAndShop(String name, String storeId) async {
    return _items.firstWhere((e) => e.name == name && e.storeId == storeId);
  }
   // coverage:ignore-start
  Future<List<Productgroup>> getAll() async {
  return List<Productgroup>.from(_items);
  // coverage:ignore-end
}

}
