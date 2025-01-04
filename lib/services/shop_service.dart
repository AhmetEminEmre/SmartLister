import 'package:isar/isar.dart';
import '../objects/shop.dart';

class ShopService {
  final Isar isar;

  ShopService(this.isar);

  Future<List<Einkaufsladen>> fetchShops() async {
    return await isar.einkaufsladens.where().findAll();
  }

  Future<Einkaufsladen> addShop(Einkaufsladen shop) async {
    await isar.writeTxn(() async {
      final id = await isar.einkaufsladens.put(shop);
      shop.id = id;
    });
    return shop;
  }

  Future<void> deleteShop(int shopId) async {
    await isar.writeTxn(() async {
      await isar.einkaufsladens.delete(shopId);
    });
  }

  Future<Einkaufsladen?> fetchShopById(int shopId) async {
    return await isar.einkaufsladens.get(shopId);
  }
}
