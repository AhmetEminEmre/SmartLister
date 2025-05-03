import 'package:flutter/material.dart';
import 'package:smart/services/userinfo_service.dart';

class SettingsScreen extends StatelessWidget {
  final NicknameService nicknameService;

  const SettingsScreen({super.key, required this.nicknameService});

  void _showNicknameDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nickname ändern'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Neuer Nickname'),
        ),
        actions: [
          TextButton(
            child: const Text('Abbrechen'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Speichern'),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await nicknameService.setNickname(newName);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nickname gespeichert!')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: const Color(0xFFEDF2D0),
        foregroundColor: const Color(0xFF222222),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Nickname ändern'),
            subtitle: const Text('Setze deinen Anzeigennamen neu'),
            onTap: () => _showNicknameDialog(context),
          ),
          const ListTile(
            leading: Icon(Icons.color_lens),
            title: Text('Design & Farben & Fonts'),
            subtitle: Text('Wähle deinen bevorzugten Look'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Über die App'),
            subtitle: Text('Version, Entwickler, Impressum'),
          ),
        ],
      ),
    );
  }
}
