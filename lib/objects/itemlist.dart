import 'dart:convert';
import 'package:isar/isar.dart';

part 'itemlist.g.dart';

@Collection()
class Itemlist {
  Id id = Isar.autoIncrement;
  late String name;
  late String shopId;
  String? imagePath;
  DateTime creationDate = DateTime.now();

  late String itemsJson;

  Itemlist({
    required this.name,
    required this.shopId,
    this.imagePath,
    List<Map<String, dynamic>>? items,
    required this.creationDate,
  }) {
    setItems(items ?? []);
  }

  List<Map<String, dynamic>> getItems() {
    if (itemsJson.isEmpty) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(itemsJson));
    } catch (e) {
      return [];
    }
  }

  void setItems(List<Map<String, dynamic>> items) {
    itemsJson = jsonEncode(items);
  }
}
