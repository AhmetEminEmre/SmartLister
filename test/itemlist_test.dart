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
