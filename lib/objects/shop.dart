import 'package:isar/isar.dart';

part 'shop.g.dart';

@Collection()
class Einkaufsladen {
  Id id = Isar.autoIncrement;
  late String name;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  static Einkaufsladen fromJson(Map<String, dynamic> json) => Einkaufsladen(
    name: json['name'],
  );

  Einkaufsladen({required this.name});
}
