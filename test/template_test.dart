import 'package:flutter_test/flutter_test.dart';
import 'package:smart/objects/template.dart';

void main() {
  test('setItems + getItems funktionieren korrekt', () {
    final template = Template(
      name: 'Test',
      imagePath: 'img.png',
      storeId: '1',
      items: [
        {'name': 'Apfel', 'isDone': false},
        {'name': 'Milch', 'isDone': true},
      ],
    );

    final items = template.getItems();
    expect(items.length, 2);
    expect(items[0]['name'], 'Apfel');
    expect(items[1]['isDone'], true);
  });

  test('toJson gibt korrektes Mapping zurück', () {
    final template = Template(
      name: 'Mein Template',
      imagePath: 'pfad.png',
      storeId: '10',
      items: [],
    )..id = 7;

    final json = template.toJson();
    expect(json['id'], 7);
    expect(json['name'], 'Mein Template');
    expect(json['imagePath'], 'pfad.png');
    expect(json['storeId'], '10');
    expect(json['itemsJson'], isNotNull);
  });

  test('fromJson erstellt korrektes Template', () {
    final json = {
      'name': 'From JSON',
      'imagePath': 'pfad.png',
      'storeId': '99',
      'itemsJson': '[{"name":"Brot"}]',
    };

    final template = Template.fromJson(json);
    expect(template.name, 'From JSON');
    expect(template.imagePath, 'pfad.png');
    expect(template.getItems()[0]['name'], 'Brot');
  });
}
