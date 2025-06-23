import 'package:isar/isar.dart';

part 'shop.g.dart';

@Collection()
class Einkaufsladen {
  Id id = Isar.autoIncrement;
  late String name;
  String? imagePath;
  String? excludedItems;


  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'excludedItems': excludedItems,
  };

  static Einkaufsladen fromJson(Map<String, dynamic> json) => Einkaufsladen(
    name: json['name'],
    imagePath: json['imagePath'],
    excludedItems: json['excludedItems']);


  Einkaufsladen({required this.name, this.imagePath, this.excludedItems});
}
