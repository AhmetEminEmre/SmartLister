import 'package:isar/isar.dart';

part 'shop.g.dart';

@Collection()
class Einkaufsladen {
  Id id = Isar.autoIncrement;
  late String name;
  String? imagePath;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
  };

  static Einkaufsladen fromJson(Map<String, dynamic> json) => Einkaufsladen(
    name: json['name'],
    imagePath: json['imagePath'],
  );

  Einkaufsladen({required this.name, this.imagePath});
}
