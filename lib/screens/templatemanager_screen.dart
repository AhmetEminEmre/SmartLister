import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/services/template_service.dart';
import 'package:smart/objects/template.dart';
import 'package:smart/font_scaling.dart';

class TemplateManagerScreen extends StatefulWidget {
  final TemplateService templateService;

  const TemplateManagerScreen({Key? key, required this.templateService})
      : super(key: key);

  @override
  State<TemplateManagerScreen> createState() => _TemplateManagerScreenState();
}

class _TemplateManagerScreenState extends State<TemplateManagerScreen> {
  List<Template> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await widget.templateService.fetchAllTemplates();
    setState(() {
      _templates = templates;
    });
  }

  Future<void> _deleteTemplate(int id) async {
    await widget.templateService.deleteTemplate(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Vorlage gelöscht!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    _loadTemplates();
  }

  @override
  Widget build(BuildContext context) {
    final scaling = context.watch<FontScaling>().factor;

    return Scaffold(
      backgroundColor: Colors.white, // ✅ Weißer Hintergrund
      appBar: AppBar(
        title: Text(
          'Vorlagen verwalten',
          style: TextStyle(fontSize: 22 * scaling),
        ),
        backgroundColor: const Color(0xFFEDF2D0),
        foregroundColor: const Color(0xFF222222),
      ),
      body: ListView.builder(
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final template = _templates[index];
          return ListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(
              template.name,
              style: TextStyle(
                fontSize: 18 * scaling,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await _deleteTemplate(template.id!);
              },
            ),
          );
        },
      ),
    );
  }
}
