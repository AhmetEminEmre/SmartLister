
import 'package:isar/isar.dart';
import '../objects/productgroup.dart';
import 'package:smart/fakeDBs/productgroup_fake.dart';

class ProductGroupService {
  final Isar? _isar;
  final FakeProductgroupDB? _fakeDb;

  ProductGroupService(Isar isar)
      : _isar = isar,
        _fakeDb = null;

  ProductGroupService.fake(FakeProductgroupDB fakeDb)
      : _fakeDb = fakeDb,
        _isar = null;

  Future<List<Productgroup>> fetchProductGroups(String storeId) async {
    if (_fakeDb != null) return await _fakeDb.getFilteredSorted(storeId);
    return await _isar!.productgroups
        .filter()
        .storeIdEqualTo(storeId)
        .sortByOrder()
        .findAll();
  }

  Future<Productgroup?> fetchLastGroupByStoreId(String storeId) async {
  if (_fakeDb != null) {
    final all = await _fakeDb.getFilteredSorted(storeId);
    return all.isNotEmpty ? all.last : null;
  }

  return await _isar!.productgroups
      .filter()
      .storeIdEqualTo(storeId)
      .sortByOrderDesc()
      .findFirst();
}


  Future<Productgroup?> fetchGroupById(int groupId) async {
    if (_fakeDb != null) return await _fakeDb.get(groupId);
    return await _isar!.productgroups
        .filter()
        .idEqualTo(groupId)
        .findFirst();
  }

  Future<int> addProductGroup(Productgroup group) async {
    if (_fakeDb != null) {
      await _fakeDb.add(group);
      return group.id;
    }

    final id = await _isar!.writeTxn(() async {
      return await _isar!.productgroups.put(group);
    });
    return id;
  }

  Future<void> deleteProductGroup(int groupId) async {
    if (_fakeDb != null) return await _fakeDb.delete(groupId);

    await _isar!.writeTxn(() async {
      await _isar!.productgroups.delete(groupId);
    });
  }

  Future<void> updateProductGroupOrder(List<Productgroup> productGroups) async {
    if (_fakeDb != null) {
      for (int i = 0; i < productGroups.length; i++) {
        productGroups[i].order = i;
        await _fakeDb.add(productGroups[i]);
      }
      return;
    }

    await _isar!.writeTxn(() async {
      for (int i = 0; i < productGroups.length; i++) {
        productGroups[i].order = i;
        await _isar!.productgroups.put(productGroups[i]);
      }
    });
  }

  Future<List<Productgroup>> fetchProductGroupsByStoreIdSorted(String storeId) async {
    return await _isar!.productgroups
        .filter()
        .storeIdEqualTo(storeId)
        .sortByOrder()
        .findAll();
  }

  Future<Productgroup?> fetchByNameAndShop(String name, String storeId) async {
    if (_fakeDb != null) return await _fakeDb.getByNameAndShop(name, storeId);
    return await _isar!.productgroups
        .filter()
        .nameEqualTo(name)
        .storeIdEqualTo(storeId)
        .findFirst();
  }
}