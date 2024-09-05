import 'package:isar/isar.dart';
part 'shop.g.dart';

@Collection()
class Einkaufsladen {
  Id id = Isar.autoIncrement; 
  late String name;
  late String userId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'userId': userId  
  };

  static Einkaufsladen fromJson(Map<String, dynamic> json) => Einkaufsladen(
    name: json['name'],
    userId: json['userId']  
  );
     Einkaufsladen({
    required this.name,
    required this.userId,
  });

}
