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

  @ignore
  List<Map<String, dynamic>> _items = [];

  late String itemsJson;

  Itemlist({
    required this.name,
    required this.shopId,
    this.imagePath,
    List<Map<String, dynamic>>? items,
    required DateTime creationDate,
  }) {
    setItems(items ?? []);
    this.creationDate = creationDate;
    }

  List<Map<String, dynamic>> getItems() {
    if (itemsJson.isEmpty) {
      return [];
    }
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(itemsJson));
    } catch (e) {
      print('Fehler beim Decodieren von itemsJson: $e. Inhalt: $itemsJson');
      return [];
    }
  }

void setItems(List<Map<String, dynamic>> items) {
    _items = items;
    itemsJson = jsonEncode(items);
    print('Items JSON: $itemsJson');
}

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'groupId': shopId,
        'imagePath': imagePath,
        'itemsJson': itemsJson,
        'creationDate': creationDate.toIso8601String(),
      };

  static Itemlist fromJson(Map<String, dynamic> json) => Itemlist(
        name: json['name'],
        shopId: json['groupId'],
        imagePath: json['imagePath'],
        creationDate: DateTime.parse(json['creationDate']),
      )..itemsJson = json['itemsJson'];

  @override
String toString() {
  return 'Itemlist{name: $name, shopId: $shopId, creationDate: $creationDate, items: ${getItems()}}';
}

}



