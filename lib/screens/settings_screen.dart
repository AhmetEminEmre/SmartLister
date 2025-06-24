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
  final scaling = context.read<FontScaling>().factor;

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
                Text(
                  'Nickname ändern',
                  style: TextStyle(
                    fontSize: 20 * scaling,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 16 * scaling),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Neuer Nickname',
                    labelStyle: TextStyle(
                      color: Colors.black.withOpacity(0.5),
                      fontSize: 16 * scaling,
                      fontWeight: FontWeight.w400,
                    ),
                    floatingLabelStyle: TextStyle(
                      color: const Color.fromARGB(255, 125, 146, 5),
                      fontSize: 16 * scaling,
                      fontWeight: FontWeight.w500,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 125, 146, 5),
                      ),
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
                  style: TextStyle(
                    fontSize: 16 * scaling,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24 * scaling),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFE2E2E2),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16 * scaling,
                          vertical: 10 * scaling,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Abbrechen',
                        style: TextStyle(
                          color: const Color(0xFF5F5F5F),
                          fontSize: 14 * scaling,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 12 * scaling),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFEF8D25),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16 * scaling,
                          vertical: 10 * scaling,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Speichern',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14 * scaling,
                        ),
                      ),
                      onPressed: () async {
                        final newName = controller.text.trim();
                        print("Eingegebener Nickname: $newName");
                        if (newName.isNotEmpty) {
                          await widget.nicknameService.setNickname(newName);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Nickname gespeichert!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18 * scaling,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: const Color(0xFF79C267),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 4),
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
