import '../objects/userinfo.dart';

class FakeNicknameDB {
  String? _nickname;

  Future<String?> getNickname() async => _nickname;

  Future<void> setNickname(String nickname) async {
    _nickname = nickname;
  }
}

