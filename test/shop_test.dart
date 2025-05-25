import 'package:flutter_test/flutter_test.dart';
import 'package:smart/services/shop_service.dart';
import 'package:smart/objects/shop.dart';
import 'package:smart/fakeDBs/shop_fake.dart';

void main() {
  late FakeShopDB fakeDb;
  late ShopService service;

  setUp(() {
    fakeDb = FakeShopDB();
    service = ShopService.fake(fakeDb);
  });

  test('Einkaufsladen speichert Name + Bild', () {
    final shop =
        Einkaufsladen(name: 'Spar', imagePath: 'lib/img/default_image.png');

    expect(shop.name, 'Spar');
    expect(shop.imagePath, 'lib/img/default_image.png');
  });

  test('toJson gibt korrektes Mapping zurück', () {
    final shop = Einkaufsladen(name: 'Billa', imagePath: 'assets/logo.png')
      ..id = 5;

    final json = shop.toJson();

    expect(json['id'], 5);
    expect(json['name'], 'Billa');
    expect(json['imagePath'], 'assets/logo.png');
  });

  test('fromJson erstellt korrektes Objekt', () {
    final json = {
      'name': 'mein Hofer',
      'imagePath': 'test_img/test.png',
    };

    final shop = Einkaufsladen.fromJson(json);

    expect(shop.name, 'mein Hofer');
    expect(shop.imagePath, 'test_img/test.png');
  });

}
