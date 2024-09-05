import 'package:isar/isar.dart';

part 'userinfo.g.dart';

@Collection()
class Userinfo {
  Id id = Isar.autoIncrement; // Automatische ID-Vergabe
  late String email;
  late String nickname;
  late String userId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nickname': nickname,
    'userId': userId,
  };

  static Userinfo fromJson(Map<String, dynamic> json) => Userinfo(
    email: json['email'],
    nickname: json['nickname'],
    userId: json['userId'],
  );

  Userinfo({required this.email, required this.nickname, required this.userId});
}
