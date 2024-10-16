import 'dart:convert';
import 'package:isar/isar.dart';

part 'itemlist.g.dart';

@Collection()
class Itemlist {
  Id id = Isar.autoIncrement; // Automatisch generierte ID durch Isar
  late String name; // Name der Liste
  late String groupId; // Referenz zum Shop (oder Gruppe)
  String? imagePath; // Optionaler Bildpfad
  DateTime creationDate = DateTime.now(); // Datum der Erstellung

  @ignore
  List<Map<String, dynamic>> _items = [];

  late String itemsJson; // JSON, das die Artikel enthält

  Itemlist({
    required this.name,
    required this.groupId, // Muss aus dem ausgewählten Shop kommen
    this.imagePath,
    List<Map<String, dynamic>>? items,
    DateTime? creationDate,
  }) {
    setItems(items ?? []);
    if (creationDate != null) {
      this.creationDate = creationDate;
    }
  }

  // Getter, um das itemsJson zurück in eine Liste von Maps zu dekodieren
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

  // Setter, um eine Liste von Maps in itemsJson zu kodieren
  void setItems(List<Map<String, dynamic>> items) {
    _items = items;
    itemsJson = jsonEncode(items);
  }

  // JSON-Serialisierung
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'groupId': groupId,
        'imagePath': imagePath,
        'itemsJson': itemsJson,
        'creationDate': creationDate.toIso8601String(), // Datum im ISO-8601 Format serialisieren
      };

  static Itemlist fromJson(Map<String, dynamic> json) => Itemlist(
        name: json['name'],
        groupId: json['groupId'],
        imagePath: json['imagePath'],
        creationDate: DateTime.parse(json['creationDate']), // Datum aus dem String parsen
      )..itemsJson = json['itemsJson'];
}
