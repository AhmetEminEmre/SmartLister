import 'package:flutter_test/flutter_test.dart';
import 'package:smart/objects/template.dart';
import 'package:smart/services/template_service.dart';
import 'package:smart/fakeDBs/template_fake.dart';

void main() {
  late FakeTemplateDB fakeDb;
  late TemplateService service;

  setUp(() {
    fakeDb = FakeTemplateDB();
    service = TemplateService.fake(fakeDb);
  });

  test('addTemplate + fetchTemplateById', () async {
    final template = Template(
      name: 'Wocheneinkauf',
      imagePath: 'img/1.png',
      storeId: 's1',
    )..id = 1;

    await service.addTemplate(template);

    final result = await service.fetchTemplateById(1);
    expect(result?.name, 'Wocheneinkauf');
  });

  test('deleteTemplate entfernt Template', () async {
    final template = Template(
      name: 'Lidl',
      imagePath: 'img/2.png',
      storeId: 's1',
    )..id = 42;

    await service.addTemplate(template);
    await service.deleteTemplate(42);

    final result = await service.fetchTemplateById(42);
    expect(result, isNull);
  });

  test('fetchAllTemplates gibt alle Templates zurück', () async {
    await service.addTemplate(Template(
      name: 'Aldi',
      imagePath: 'img/3.png',
      storeId: 's2',
    ));

    await service.addTemplate(Template(
      name: 'Billa',
      imagePath: 'img/4.png',
      storeId: 's2',
    ));

    final result = await service.fetchAllTemplates();
    expect(result.length, 2);
    expect(result.map((e) => e.name), containsAll(['Aldi', 'Billa']));
  });
}
