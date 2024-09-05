import 'package:isar/isar.dart';

part 'productgroup.g.dart';

@Collection()
class Productgroup {
  Id id = Isar.autoIncrement;
  late String name;
  late int itemCount;
  late String userId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'itemCount': itemCount,
    'userId': userId,
  };

  static Productgroup fromJson(Map<String, dynamic> json) => Productgroup(
    name: json['name'],
    itemCount: json['itemCount'],
    userId: json['userId'],
  );

  Productgroup({required this.name, required this.itemCount, required this.userId});
}
