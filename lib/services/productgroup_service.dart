import 'package:isar/isar.dart';
import '../objects/productgroup.dart';
import 'package:smart/fakeDBs/productgroup_fake.dart';

class ProductGroupService {
  final Isar? _isar;
  final FakeProductgroupDB? _fakeDb;

// coverage:ignore-start
  ProductGroupService(Isar isar)
      : _isar = isar,
        _fakeDb = null;
// coverage:ignore-end
  ProductGroupService.fake(FakeProductgroupDB fakeDb)
      : _fakeDb = fakeDb,
        _isar = null;

  Future<List<Productgroup>> fetchProductGroupsByStoreIdSorted(
      String storeId) async {
    if (_fakeDb != null) {
      return await _fakeDb.getFilteredSorted(storeId);
    }
    // coverage:ignore-start
    return await _isar!.productgroups
        .filter()
        .storeIdEqualTo(storeId)
        .sortByOrder()
        .findAll();
    // coverage:ignore-end
  }

  // coverage:ignore-start
  Future<List<Productgroup>> fetchAllProductGroupsSorted() async {
  if (_fakeDb != null) {
    return await _fakeDb.getAll();
  }
  return await _isar!.productgroups.where().sortByOrder().findAll();
  // coverage:ignore-end
}

  Future<Productgroup?> fetchLastGroupByStoreId(String storeId) async {
    if (_fakeDb != null) {
      final all = await _fakeDb.getFilteredSorted(storeId);
      return all.isNotEmpty ? all.last : null;
    }

    // coverage:ignore-start
    return await _isar!.productgroups
        .filter()
        .storeIdEqualTo(storeId)
        .sortByOrderDesc()
        .findFirst();
    // coverage:ignore-end
  }

  Future<Productgroup?> fetchGroupById(int groupId) async {
    if (_fakeDb != null) return await _fakeDb.get(groupId);
    // coverage:ignore-start
    return await _isar!.productgroups.filter().idEqualTo(groupId).findFirst();
    // coverage:ignore-end
  }

  Future<int> addProductGroup(Productgroup group) async {
    if (_fakeDb != null) {
      await _fakeDb.add(group);
      return group.id;
    }
    // coverage:ignore-start
    final id = await _isar!.writeTxn(() async {
      return await _isar.productgroups.put(group);
    });
    // coverage:ignore-end
    return id;
  }

  Future<void> deleteProductGroup(int groupId) async {
    if (_fakeDb != null) return await _fakeDb.delete(groupId);

    // coverage:ignore-start
    await _isar!.writeTxn(() async {
      await _isar.productgroups.delete(groupId);
    });
    // coverage:ignore-end
  }

  Future<void> updateProductGroupOrder(List<Productgroup> productGroups) async {
    if (_fakeDb != null) {
      for (int i = 0; i < productGroups.length; i++) {
        productGroups[i].order = i;
        await _fakeDb.add(productGroups[i]);
      }
      return;
    }

    // coverage:ignore-start
    await _isar!.writeTxn(() async {
      for (int i = 0; i < productGroups.length; i++) {
        productGroups[i].order = i;
        await _isar.productgroups.put(productGroups[i]);
      } //coverage:ignore-end
    });
  }

  Future<Productgroup?> fetchByNameAndShop(String name, String storeId) async {
    if (_fakeDb != null) return await _fakeDb.getByNameAndShop(name, storeId);
    // coverage:ignore-start
    return await _isar!.productgroups
        .filter()
        .nameEqualTo(name)
        .storeIdEqualTo(storeId)
        .findFirst();
    // coverage:ignore-end
  }
}
