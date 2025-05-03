import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Für Poppins-Schriftart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart/objects/itemlist.dart';
import 'package:smart/objects/shop.dart';
import 'package:smart/objects/productgroup.dart';
import 'package:smart/objects/template.dart';
import 'package:smart/objects/userinfo.dart';
import 'package:smart/screens/homepage_screen.dart';
import 'package:smart/screens/nickname_screen.dart';

import 'package:smart/services/itemlist_service.dart';
import 'package:smart/services/productgroup_service.dart';
import 'package:smart/services/shop_service.dart';
import 'package:smart/services/template_service.dart';
import 'package:smart/services/userinfo_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [ItemlistSchema, EinkaufsladenSchema, ProductgroupSchema, TemplateSchema, UserinfoSchema],
    directory: dir.path,
  );

    // ✅ Services initialisieren
  final itemListService = ItemListService(isar);
  final shopService = ShopService(isar);
  final userinfoService = NicknameService(isar);
  final productGroupService = ProductGroupService(isar);
  final templateService = TemplateService(isar);

  runApp(MyApp(
    itemListService: itemListService,
    shopService: shopService,
    userinfoService: userinfoService,
    productGroupService: productGroupService,
    templateService: templateService,
  ));
}


class MyApp extends StatelessWidget {
  final ItemListService itemListService;
  final ShopService shopService;
  final NicknameService userinfoService;
  final ProductGroupService productGroupService;
  final TemplateService templateService;

  const MyApp({
    super.key,
    required this.itemListService,
    required this.shopService,
    required this.userinfoService,
    required this.productGroupService,
    required this.templateService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme:
            GoogleFonts.poppinsTextTheme(), // Poppins als Standard-Schriftart
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFFF2E8DC); // Farbe, wenn die Checkbox ausgewählt ist
              }
              return const Color.fromARGB(255, 255, 255, 255); // Standardfarbe
            },
          ),
          checkColor: WidgetStateProperty.all(Colors.deepOrange), // Farbe des Hakens
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
         home: HomePage(
        itemListService: itemListService,
        shopService: shopService,
        userinfoService: userinfoService,
        productGroupService: productGroupService,
        templateService: templateService,
      ),
    );
  }
}
