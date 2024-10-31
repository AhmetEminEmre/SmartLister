import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import 'package:smart/objects/productgroup.dart';
import 'package:smart/objects/template.dart';
import '../objects/itemlist.dart';
import '../objects/shop.dart';
import 'package:smart/screens/homepage_screen.dart'; 



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open([ItemlistSchema, EinkaufsladenSchema, TemplateSchema, ProductgroupSchema], directory: dir.path);
  runApp(MyApp(isar: isar));
}

class MyApp extends StatelessWidget {
  final Isar isar;

  const MyApp({super.key, required this.isar});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(isar: isar),
    );
  }
}
