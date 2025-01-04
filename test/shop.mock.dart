import 'package:mockito/mockito.dart';
import 'package:isar/isar.dart';
import 'package:smart/services/shop_service.dart';
import 'package:smart/objects/shop.dart';

class MockIsar extends Mock implements Isar {}

class MockShopCollection extends Mock implements IsarCollection<Einkaufsladen> {}

class MockShopService extends Mock implements ShopService {
  MockShopService(MockIsar isar) : super();
}

class FakeShopDatabase {
  final List<Einkaufsladen> _storage = [];
  int _nextId = 1;

  void add(Einkaufsladen shop) {
    shop.id = _nextId;
    _nextId++;
    _storage.add(shop);
  }

  void delete(int id) {
    _storage.removeWhere((shop) => shop.id == id);
  }

  List<Einkaufsladen> getAll() {
    return List<Einkaufsladen>.from(_storage);
  }

  Einkaufsladen? getById(int id) {
    return _storage.firstWhere((shop) => shop.id == id);
  }
}
