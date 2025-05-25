import 'package:isar/isar.dart';
import '../objects/template.dart';

class FakeTemplateDB {
  final List<Template> _items = [];
  int _nextId = 1;

  Future<List<Template>> getAll() async {
    return List<Template>.from(_items);
  }

  Future<Template?> getById(int id) async {
    try {
      return _items.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(Template t) async {
    if (t.id == Isar.autoIncrement || t.id == 0) {
      t.id = _nextId++;
    } else {
      _items.removeWhere((e) => e.id == t.id);
    }
    _items.add(t);
  }

  Future<void> delete(int id) async {
    _items.removeWhere((t) => t.id == id);
  }
}
