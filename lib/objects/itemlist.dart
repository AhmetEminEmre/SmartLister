import 'package:isar/isar.dart';

part 'itemlist.g.dart';

@Collection()
class Itemlist {
  Id id = Isar.autoIncrement;
  late String name;
  late bool isDone;
  late String groupId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isDone': isDone,
    'groupId': groupId,
  };

  static Itemlist fromJson(Map<String, dynamic> json) => Itemlist(
    name: json['name'],
    isDone: json['isDone'],
    groupId: json['groupId'],
  );

  Itemlist({required this.name, required this.isDone, required this.groupId});
}
