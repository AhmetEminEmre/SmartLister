import 'package:mockito/mockito.dart';
import 'package:isar/isar.dart';
import 'package:smart/services/productgroup_service.dart';
import 'package:smart/objects/productgroup.dart';

class MockIsar extends Mock implements Isar {}

class MockProductGroups extends Mock implements IsarCollection<Productgroup> {}

class MockProductGroupService extends Mock implements ProductGroupService {
  MockProductGroupService(MockIsar isar) : super();
}
class FakeProductGroupDatabase { // fake database for testing incrementation
  final List<Productgroup> _storage = [];
  int _nextId = 1;

  void add(Productgroup group) {
    group.id = _nextId;
    _nextId++;
    _storage.add(group);
  }

  void delete(int id) {
    _storage.removeWhere((group) => group.id == id);
  }

  List<Productgroup> getAll() {
    return List<Productgroup>.from(_storage);
  }
}

