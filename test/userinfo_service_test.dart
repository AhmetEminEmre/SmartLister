import 'package:flutter_test/flutter_test.dart';
import 'package:smart/services/userinfo_service.dart';
import 'package:smart/fakeDBs/userinfo_fake.dart';

void main() {
  late FakeNicknameDB fakeDb;
  late NicknameService service;

  setUp(() {
    fakeDb = FakeNicknameDB();
    service = NicknameService.fake(fakeDb);
  });

  test('setNickname speichert den Namen korrekt', () async {
    await service.setNickname('Max');
    final result = await fakeDb.getNickname();

    expect(result, 'Max');
  });

  test('getNickname gibt den gespeicherten Namen zurück', () async {
    await fakeDb.setNickname('Susi');
    final result = await service.getNickname();

    expect(result, 'Susi');
  });

  test('fetchNickname gibt leeren String zurück, wenn kein Name vorhanden', () async {
    final result = await service.fetchNickname();
    expect(result, '');
  });

  test('fetchNickname gibt gespeicherten Namen zurück', () async {
    await fakeDb.setNickname('Franz');
    final result = await service.fetchNickname();
    expect(result, 'Franz');
  });
}
