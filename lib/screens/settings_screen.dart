import 'package:flutter/material.dart';
import 'package:smart/services/userinfo_service.dart';
import 'package:provider/provider.dart';
import 'package:smart/font_scaling.dart';
import 'package:smart/screens/templatemanager_screen.dart';
import 'package:smart/services/template_service.dart';



class SettingsScreen extends StatefulWidget {
  final NicknameService nicknameService;
  final TemplateService templateService;

  const SettingsScreen({super.key, required this.nicknameService, required this.templateService,});

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
                    controller:
                        controller, // Hier wird der Controller verwendet
                    decoration: InputDecoration(
                      labelText: 'Neuer Nickname',
                      labelStyle: TextStyle(
                        // nicht-fokussierter Zustand
                        color: Colors.black
                            .withOpacity(0.5), // wirkt heller als reines Grau
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      floatingLabelStyle: const TextStyle(
                        // fokussierter Zustand
                        color: Color.fromARGB(255, 125, 146, 5),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 125, 146, 5)),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Abbrechen',
                          style:
                              TextStyle(color: Color(0xFF5F5F5F), fontSize: 14),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEF8D25),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
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
                          print(
                              "Eingegebener Nickname: $newName"); // Debug-Ausgabe
                          if (newName.isNotEmpty) {
                            await widget.nicknameService.setNickname(newName);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nickname gespeichert!'),
                                  backgroundColor:
                                      Color(0xFF79C267), // Helles Grün
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
    final scaling = context.watch<FontScaling>().factor;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Text(
          'Einstellungen',
          style: TextStyle(fontSize: 22 * scaling), // z.B. 22 als Basisgröße
        ),
        backgroundColor: const Color(0xFFEDF2D0),
        foregroundColor: const Color(0xFF222222),
      ),
   body: ListView(
  padding: const EdgeInsets.all(16.0),
  children: [
    ListTile(
      leading: const Icon(Icons.person),
      title: Text(
        'Nickname ändern',
        style: TextStyle(fontSize: 18 * scaling),
      ),
      subtitle: Text(
        'Setze deinen Anzeigennamen neu',
        style: TextStyle(fontSize: 14 * scaling),
      ),
      onTap: () => _showNicknameDialog(context),
    ),
    Consumer<FontScaling>(builder: (context, fontScaling, _) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.format_size),
            title: Text(
              'Schriftgröße',
              style: TextStyle(fontSize: 18 * scaling),
            ),
            subtitle: Text(
              'Passe die Textgröße in der App an',
              style: TextStyle(fontSize: 14 * scaling),
            ),
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
    ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(
        'Vorlagen verwalten',
        style: TextStyle(fontSize: 18 * scaling),
      ),
      subtitle: Text(
        'Lösche deine erstellten Vorlagen',
        style: TextStyle(fontSize: 14 * scaling),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TemplateManagerScreen(
              templateService: widget.templateService,
            ),
          ),
        );
      },
    ),
    ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text(
        'Über die App',
        style: TextStyle(fontSize: 18 * scaling),
      ),
      subtitle: Text(
        'Version, Entwickler, Impressum',
        style: TextStyle(fontSize: 14 * scaling),
      ),
    ),
  ],
),

    );
  }
}
