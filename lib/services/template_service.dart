import 'package:isar/isar.dart';
import '../objects/template.dart';
import 'package:smart/fakeDBs/template_fake.dart';

class TemplateService {
  final Isar? _isar;
  final FakeTemplateDB? _fakeDb;

  // coverage:ignore-start
  TemplateService(this._isar) : _fakeDb = null;
  // coverage:ignore-end
  TemplateService.fake(this._fakeDb) : _isar = null;

  Future<List<Template>> fetchAllTemplates() async {
    if (_fakeDb != null) return await _fakeDb.getAll();
    // coverage:ignore-start
    return await _isar!.templates.where().findAll();
    // coverage:ignore-end
  }

  Future<Template?> fetchTemplateById(int id) async {
    if (_fakeDb != null) return await _fakeDb.getById(id);
    // coverage:ignore-start
    return await _isar!.templates.get(id);
    // coverage:ignore-end
  }

  Future<void> addTemplate(Template template) async {
    if (_fakeDb != null) return await _fakeDb.add(template);
    // coverage:ignore-start
    await _isar!.writeTxn(() async {
      await _isar.templates.put(template);
    });
    // coverage:ignore-end
  }

  Future<void> deleteTemplate(int id) async {
    if (_fakeDb != null) return await _fakeDb.delete(id);
    // coverage:ignore-start
    await _isar!.writeTxn(() async {
      await _isar.templates.delete(id);
    });
    // coverage:ignore-end
  }
}
