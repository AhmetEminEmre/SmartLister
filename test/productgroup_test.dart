import 'package:flutter_test/flutter_test.dart';
import 'package:smart/objects/productgroup.dart';
import 'package:smart/services/productgroup_service.dart';
import 'package:smart/fakeDBs/productgroup_fake.dart';

void main() {
  late FakeProductgroupDB fakeDb;
  late ProductGroupService service;

  setUp(() {
    fakeDb = FakeProductgroupDB();
    service = ProductGroupService.fake(fakeDb);
  });

  test('toJson gibt korrektes Mapping zurück', () {
    final group = Productgroup(name: 'Obst', storeId: '123', order: 2)..id = 99;

    final json = group.toJson();

    expect(json['id'], 99);
    expect(json['name'], 'Obst');
    expect(json['storeId'], '123');
    expect(json['order'], 2);
  });

  test('fromJson erstellt korrektes Objekt', () {
    final json = {
      'name': 'Getränke',
      'storeId': '123',
      'order': 1,
    };

    final group = Productgroup.fromJson(json);

    expect(group.name, 'Getränke');
    expect(group.storeId, '123');
    expect(group.order, 1);
  });


}
