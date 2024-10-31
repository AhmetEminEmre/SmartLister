import 'dart:convert';
import 'package:isar/isar.dart';

part 'template.g.dart';

@Collection()
class Template {
  Id id = Isar.autoIncrement;
  late String name;
  late String imagePath;
  late String storeId;
  
  @ignore
  List<Map<String, dynamic>> _items = [];

  late String itemsJson;

  // Constructor
  Template({
    required this.name,
    required this.imagePath,
    required this.storeId,
    List<Map<String, dynamic>>? items,
  }) {
    setItems(items ?? []);
  }

  List<Map<String, dynamic>> getItems() => List<Map<String, dynamic>>.from(jsonDecode(itemsJson));

  void setItems(List<Map<String, dynamic>> items) {
    _items = items;
    itemsJson = jsonEncode(items);
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
        'storeId': storeId,
        'itemsJson': itemsJson,
      };

  static Template fromJson(Map<String, dynamic> json) => Template(
        name: json['name'],
        imagePath: json['imagePath'],
        storeId: json['storeId'],
      )..itemsJson = json['itemsJson'];
}
