import 'package:isar/isar.dart';
import '../objects/template.dart';

class TemplateService {
  final Isar _isar;

  TemplateService(this._isar);

  Future<List<Template>> fetchAllTemplates() async {
    return await _isar.templates.where().findAll();
  }

  Future<Template?> fetchTemplateById(int id) async {
    return await _isar.templates.get(id);
  }

  Future<void> addTemplate(Template template) async {
    await _isar.writeTxn(() async {
      await _isar.templates.put(template);
    });
  }

  Future<void> deleteTemplate(int id) async {
    await _isar.writeTxn(() async {
      await _isar.templates.delete(id);
    });
  }
}
