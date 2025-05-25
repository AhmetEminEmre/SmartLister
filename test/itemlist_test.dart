import 'package:flutter_test/flutter_test.dart';
import 'package:smart/objects/itemlist.dart';

void main() {
  late Itemlist list;

  setUp(() {
    list = Itemlist(
      name: 'Wocheneinkauf',
      shopId: 's1',
      imagePath: 'lib/img/default_image.png',
      items: [
        {'name': 'Milch', 'isDone': false, 'groupId': 1}
      ],
      creationDate: DateTime(2025, 1, 1),
    )..id = 10;
  });

  test('Itemlist speichert Name, Shop-ID, Items und Zeit korrekt', () {
    expect(list.id, 10);
    expect(list.name, 'Wocheneinkauf');
    expect(list.shopId, 's1');
    expect(list.imagePath, 'lib/img/default_image.png');
    expect(list.creationDate.year, 2025);
    expect(list.getItems().length, 1);
    expect(list.getItems()[0]['name'], 'Milch');
  });

  test('toJson gibt korrektes Mapping zurück', () {
    final json = list.toJson();
    expect(json['id'], 10);
    expect(json['name'], 'Wocheneinkauf');
    expect(json['groupId'], 's1');
    expect(json['imagePath'], 'lib/img/default_image.png');
    expect(json['creationDate'], '2025-01-01T00:00:00.000');
    expect(json['itemsJson'], isNotEmpty);
  });

  test('fromJson erstellt korrektes Objekt', () {
    final json = {
      'name': 'Getränkeplan',
      'groupId': 's2',
      'imagePath': 'pfad/bild1.png',
      'itemsJson': '[{"name":"Cola"}]',
      'creationDate': '2024-12-01T12:00:00.000'
    };

    final newList = Itemlist.fromJson(json);

    expect(newList.name, 'Getränkeplan');
    expect(newList.shopId, 's2');
    expect(newList.imagePath, 'pfad/bild1.png');
    expect(newList.getItems().length, 1);
    expect(newList.getItems()[0]['name'], 'Cola');
    expect(newList.creationDate.year, 2024);
  });

  test('toString gibt sinnvollen Text zurück', () {
    final string = list.toString();
    expect(string, contains('Itemlist{name: Wocheneinkauf'));
    expect(string, contains('shopId: s1'));
    expect(string, contains('creationDate: 2025'));
    expect(string, contains('Milch'));
  });

  test('getItems gibt leere Liste zurück bei leerem itemsJson', () {
    final emptyList = Itemlist(
      name: 'Leer',
      shopId: 'x',
      imagePath: null,
      items: [],
      creationDate: DateTime(2025, 1, 1),
    );
    emptyList.itemsJson = '';
    expect(emptyList.getItems(), []);
  });

  test('getItems gibt [] bei ungültigem JSON zurück', () {
  final broken = Itemlist(
    name: 'Fehlerliste',
    shopId: 'x',
    items: [],
    creationDate: DateTime(2025, 1, 1),
  );
  broken.itemsJson = '[{this is broken json]';

  final result = broken.getItems();
  expect(result, []);
});

}
