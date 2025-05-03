import 'package:isar/isar.dart';
import '../objects/userinfo.dart';
import 'package:smart/fakeDBs/userinfo_fake.dart';


class NicknameService {
  final Isar? isar;
  final FakeNicknameDB? fakeDb;

  NicknameService(this.isar) : fakeDb = null;
  NicknameService.fake(this.fakeDb) : isar = null;

  Future<String?> getNickname() async {
    if (fakeDb != null) return fakeDb!.getNickname();

    final userinfo = await isar!.userinfos.where().findFirst();
    return userinfo?.nickname;
  }

  Future<void> setNickname(String nickname) async {
    if (fakeDb != null) {
      await fakeDb!.setNickname(nickname);
      return;
    }

    await isar!.writeTxn(() async {
      await isar!.userinfos.clear();
      await isar!.userinfos.put(Userinfo(nickname: nickname));
    });
  }

  Future<String> fetchNickname() async {
  final name = await getNickname();
  return name ?? '';
}

}
