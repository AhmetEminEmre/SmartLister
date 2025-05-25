import 'package:flutter_test/flutter_test.dart';
import 'package:smart/objects/userinfo.dart';

void main() {
  test('Userinfo speichert Nickname korrekt', () {
    final user = Userinfo(nickname: 'Armin');
    expect(user.nickname, 'Armin');
  });

  test('Userinfo speichert manuell gesetzte ID', () {
    final user = Userinfo(nickname: 'Armin')..id = 42;
    expect(user.id, 42);
  });
}
