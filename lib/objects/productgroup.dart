import 'package:isar/isar.dart';

part 'productgroup.g.dart';

@Collection()
class Productgroup {
  Id id = Isar.autoIncrement;
  late String name;
  late int itemCount;
  late String storeId; // Add storeId field to reference the store
  late int order; // Add order field to manage the order of the product groups

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'itemCount': itemCount,
    'storeId': storeId,
    'order': order,
  };

  static Productgroup fromJson(Map<String, dynamic> json) => Productgroup(
    name: json['name'],
    itemCount: json['itemCount'],
    storeId: json['storeId'],
    order: json['order'],
  );

  Productgroup({
    required this.name,
    required this.itemCount,
    required this.storeId,
    required this.order,
  });
}
