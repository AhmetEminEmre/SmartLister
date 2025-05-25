import 'package:isar/isar.dart';
import '../objects/userinfo.dart';
import 'package:smart/fakeDBs/userinfo_fake.dart';


class NicknameService {
  final Isar? isar;
  final FakeNicknameDB? fakeDb;

  // coverage:ignore-start
  NicknameService(this.isar) : fakeDb = null;
  // coverage:ignore-end  
  NicknameService.fake(this.fakeDb) : isar = null;

  Future<String?> getNickname() async {
    if (fakeDb != null) return fakeDb!.getNickname();

    // coverage:ignore-start
    final userinfo = await isar!.userinfos.where().findFirst();
    return userinfo?.nickname;
    // coverage:ignore-end
  }

  Future<void> setNickname(String nickname) async {
    if (fakeDb != null) {
      await fakeDb!.setNickname(nickname);
      return;
    }
    // coverage:ignore-start
    await isar!.writeTxn(() async {
      await isar!.userinfos.clear();
      await isar!.userinfos.put(Userinfo(nickname: nickname));
    });
    // coverage:ignore-end
  }

  Future<String> fetchNickname() async {
  final name = await getNickname();
  return name ?? '';
}

}
