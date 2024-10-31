import 'package:isar/isar.dart';

part 'productgroup.g.dart';

@Collection()
class Productgroup {
  Id id = Isar.autoIncrement;
  late String name;
  late String storeId;
  @Index()
  late int order;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'storeId': storeId,
    'order': order,
  };

  static Productgroup fromJson(Map<String, dynamic> json) => Productgroup(
    name: json['name'],
    storeId: json['storeId'],
    order: json['order'],
  );

  Productgroup({
    required this.name,
    required this.storeId,
    required this.order,
  });
}
