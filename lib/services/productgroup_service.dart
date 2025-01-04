import 'package:isar/isar.dart';
import '../objects/productgroup.dart';

class ProductGroupService {
  final Isar isar;

  ProductGroupService(this.isar);

  Future<List<Productgroup>> fetchProductGroups(String storeId) async {
    return await isar.productgroups
        .filter()
        .storeIdEqualTo(storeId)
        .sortByOrder()
        .findAll();
  }

  Future<void> addProductGroup(Productgroup group) async {
    await isar.writeTxn(() async {
      await isar.productgroups.put(group);
    });
  }

  Future<void> deleteProductGroup(int groupId) async {
    await isar.writeTxn(() async {
      await isar.productgroups.delete(groupId);
    });
  }

  Future<void> updateProductGroupOrder(
      List<Productgroup> productGroups) async {
    await isar.writeTxn(() async {
      for (int i = 0; i < productGroups.length; i++) {
        productGroups[i].order = i;
        await isar.productgroups.put(productGroups[i]);
      }
    });
  }

  Future<void> addDefaultProductGroups(String storeId) async {
    final defaultGroups = [
      'Obst & Gemüse',
      'Säfte',
      'Fleisch',
      'Fischprodukte',
    ];

    final existingGroups = await isar.productgroups
        .filter()
        .storeIdEqualTo(storeId)
        .findAll();
    Set<String> existingNames = existingGroups.map((g) => g.name).toSet();

    await isar.writeTxn(() async {
      for (var groupName in defaultGroups) {
        if (!existingNames.contains(groupName)) {
          final productGroup = Productgroup(
            name: groupName,
            storeId: storeId,
            order: defaultGroups.indexOf(groupName),
          );
          await isar.productgroups.put(productGroup);
        }
      }
    });
  }
}
