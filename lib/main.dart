import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import 'package:smart/objects/productgroup.dart';
import 'package:smart/objects/template.dart';
import '../objects/itemlist.dart'; // Your Isar model
import '../objects/shop.dart'; // Your Isar model
import 'package:smart/screens/homepage_screen.dart'; 



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get the directory for Isar database storage
  final dir = await getApplicationDocumentsDirectory();

  // Initialize Isar with the directory
  final isar = await Isar.open([ItemlistSchema, EinkaufsladenSchema, TemplateSchema, ProductgroupSchema], directory: dir.path);
  runApp(MyApp(isar: isar));
}

class MyApp extends StatelessWidget {
  final Isar isar;

  MyApp({required this.isar});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(isar: isar), // Pass Isar instance to HomePage
    );
  }
}
