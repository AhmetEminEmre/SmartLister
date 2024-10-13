import 'package:isar/isar.dart';

part 'userinfo.g.dart';

@Collection()
class Userinfo {
  Id id = Isar.autoIncrement;
  late String email;
  late String nickname;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nickname': nickname,
  };

  static Userinfo fromJson(Map<String, dynamic> json) => Userinfo(
    email: json['email'],
    nickname: json['nickname'],
  );

  Userinfo({required this.email, required this.nickname});
}
