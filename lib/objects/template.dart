import 'package:isar/isar.dart';

part 'template.g.dart';

@Collection()
class Template {
  Id id = Isar.autoIncrement;
  late String name;
  late String imagePath;
  late String userId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'userId': userId,
  };

  static Template fromJson(Map<String, dynamic> json) => Template(
    name: json['name'],
    imagePath: json['imagePath'],
    userId: json['userId'],
  );

  Template({required this.name, required this.imagePath, required this.userId});
}
