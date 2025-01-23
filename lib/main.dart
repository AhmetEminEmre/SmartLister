import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Für Poppins-Schriftart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart/objects/itemlist.dart';
import 'package:smart/objects/shop.dart';
import 'package:smart/objects/productgroup.dart';
import 'package:smart/objects/template.dart';
import 'package:smart/screens/homepage_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [ItemlistSchema, EinkaufsladenSchema, ProductgroupSchema, TemplateSchema],
    directory: dir.path,
  );

  runApp(MyApp(isar: isar));
}

class MyApp extends StatelessWidget {
  final Isar isar;

  const MyApp({super.key, required this.isar});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme:
            GoogleFonts.poppinsTextTheme(), // Poppins als Standard-Schriftart
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return const Color(0xFFF2E8DC); // Farbe, wenn die Checkbox ausgewählt ist
              }
              return const Color.fromARGB(255, 255, 255, 255); // Standardfarbe
            },
          ),
          checkColor: MaterialStateProperty.all(Colors.deepOrange), // Farbe des Hakens
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0), // Runde Checkbox
          ),
          side: const BorderSide(
            width: 2.0,
            color: Color.fromARGB(255, 89, 89, 89), // Umrandungsfarbe
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Verkleinerung des Interaktionsbereichs
        ),
      ),
      home: HomePage(isar: isar),
    );
  }
}
