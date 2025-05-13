import 'package:flutter/material.dart';
import 'package:smart/services/userinfo_service.dart';
import 'package:provider/provider.dart';
import 'package:smart/font_scaling.dart';

class SettingsScreen extends StatefulWidget {
  final NicknameService nicknameService;

  const SettingsScreen({super.key, required this.nicknameService});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController controller = TextEditingController();

  void _showNicknameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, minWidth: 300),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nickname ändern',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller, // Hier wird der Controller verwendet
                    decoration: InputDecoration(
                      labelText: 'Neuer Nickname',
                      labelStyle: TextStyle(
                        // nicht-fokussierter Zustand
                        color: Colors.black.withOpacity(0.5), // wirkt heller als reines Grau
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      floatingLabelStyle: TextStyle(
                        // fokussierter Zustand
                        color: Color.fromARGB(255, 125, 146, 5),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color.fromARGB(255, 125, 146, 5)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFE2E2E2),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Abbrechen',
                          style: TextStyle(color: Color(0xFF5F5F5F), fontSize: 14),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEF8D25),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Speichern',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        onPressed: () async {
                          final newName = controller.text.trim();
                          print("Eingegebener Nickname: $newName"); // Debug-Ausgabe
                          if (newName.isNotEmpty) {
                            await widget.nicknameService.setNickname(newName);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nickname gespeichert!'),
                                  backgroundColor: Color(0xFF79C267), // Helles Grün
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
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
          Consumer<FontScaling>(builder: (context, fontScaling, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  leading: Icon(Icons.format_size),
                  title: Text('Schriftgröße'),
                  subtitle: Text('Passe die Textgröße in der App an'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Slider(
                    value: fontScaling.factor,
                    min: 0.8,
                    max: 1.4,
                    divisions: 6,
                    label: '${(fontScaling.factor * 100).round()}%',
                    onChanged: (newValue) {
                      fontScaling.setFactor(newValue);
                    },
                  ),
                ),
              ],
            );
          }),
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
