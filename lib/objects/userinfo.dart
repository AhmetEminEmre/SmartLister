import 'package:isar/isar.dart';

part 'userinfo.g.dart';

@Collection()
class Userinfo {
  Id id = Isar.autoIncrement;
  late String nickname;

  Userinfo({required this.nickname});
}
