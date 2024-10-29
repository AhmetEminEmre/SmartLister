import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart/screens/choosestore_screen.dart'; // Stelle sicher, dass der korrekte Pfad verwendet wird
import 'package:smart/screens/itemslist_screen.dart'; // Verwende diesen Screen nach der Store-Auswahl
import '../objects/itemlist.dart'; // Dein Isar-Modell für Itemlist
import '../objects/template.dart'; // Dein Isar-Modell für Template
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker for file selection
import 'dart:io';
import 'package:smart/screens/choosestore_screen.dart';
import 'package:smart/screens/itemslist_screen.dart';
import '../objects/itemlist.dart';
import '../objects/template.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart/objects/productgroup.dart';
import '../objects/itemlist.dart';
import '../objects/shop.dart';

class CreateListScreen extends StatefulWidget {
  final Isar isar;

  const CreateListScreen({super.key, required this.isar});

  @override
  _CreateListScreenState createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final TextEditingController _listNameController = TextEditingController();
  List<DropdownMenuItem<String>> _templateItems = [];
  String? _selectedTemplateId;
  String? _selectedStoreId;
  String? _selectedImagePath;
  List<Map<String, dynamic>> _items = [];

  final Map<String, String> imageNameToPath = {
    'Fahrrad ': 'lib/img/bild1.png',
    'Einkaufswagerl': 'lib/img/bild2.png',
    'Fleisch/Fisch': 'lib/img/bild3.png',
    'Euro': 'lib/img/bild4.png',
    'Kaffee': 'lib/img/bild5.png',
  };

  final Map<String, String> imagePathToName = {
    'lib/img/bild1.png': 'Fahrrad',
    'lib/img/bild2.png': 'Einkaufswagerl',
    'lib/img/bild3.png': 'Fleisch/Fisch',
    'lib/img/bild4.png': 'Euro',
    'lib/img/bild5.png': 'Kaffee',
  };

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await widget.isar.templates.where().findAll();
    setState(() {
      _templateItems = templates.map((template) {
        return DropdownMenuItem<String>(
          value: template.id.toString(),
          child: Text(template.name),
        );
      }).toList();
    });
  }

  Future<void> _applyTemplate(String templateId) async {
    final template = await widget.isar.templates
        .where()
        .idEqualTo(int.parse(templateId))
        .findFirst();

    if (template != null) {
      _listNameController.text = template.name;
      _selectedImagePath = template.imagePath;
      _items = template.getItems();

      setState(() {
        _selectedTemplateId = templateId;
      });
    }
  }

  Future<String> createUniqueShop(String shopName) async {
    String uniqueName = shopName;
    int counter = 1;

    while (true) {
      final existingShop = await widget.isar.einkaufsladens
          .filter()
          .nameEqualTo(uniqueName)
          .findFirst();

      if (existingShop == null) {
        return uniqueName;
      } else {
        uniqueName = "$shopName($counter)";
        counter++;
      }
    }
  }

  Future<bool> isProductGroupOrderMatching(
      String shopName, List<String> importedGroupIds) async {
    final existingShop = await widget.isar.einkaufsladens
        .filter()
        .nameEqualTo(shopName)
        .findFirst();

    if (existingShop != null) {
      final existingGroups = await widget.isar.productgroups
          .filter()
          .storeIdEqualTo(existingShop.id.toString())
          .findAll();

      List<String> existingGroupIds =
          existingGroups.map((group) => group.id.toString()).toList();
      return existingGroupIds == importedGroupIds;
    }

    return false;
  }

  Future<void> importList(String csvContent) async {
    List<String> lines = csvContent.split('\n');
    if (lines.isEmpty) return;

    // Parse the shop name and product groups from the first line
    String shopName = lines[0].split(';')[0].trim();
    List<String> importedGroupIds = lines[0]
        .split(';')
        .skip(1)
        .where((groupId) => groupId.isNotEmpty)
        .toList();

    // Check if a matching shop exists, otherwise create a new one with a unique name
    if (await isProductGroupOrderMatching(shopName, importedGroupIds)) {
      print("Matching shop found. Using existing shop: $shopName");
    } else {
      shopName = await createUniqueShop(shopName);
      print("Creating new shop with name: $shopName");

      // Create the shop and save it to Isar
      final newShop = Einkaufsladen(name: shopName);
      await widget.isar.writeTxn(() async {
        await widget.isar.einkaufsladens.put(newShop);

// Add product groups to this new shop with the imported order
        for (int i = 0; i < importedGroupIds.length; i++) {
          final groupId = importedGroupIds[i];
          final productGroup = Productgroup(
            name: groupId,
            itemCount: 0, // Default item count (set based on your requirements)
            storeId: newShop.id.toString(),
            order:
                i, // Assign order based on the position in `importedGroupIds`
          );
          await widget.isar.productgroups.put(productGroup);
        }
      });
    }

    // Continue with importing items into the list
    List<Map<String, dynamic>> importedItems = [];
    for (int i = 1; i < lines.length; i++) {
      var line = lines[i].trim();
      if (line.isEmpty) continue;

      var fields = line.split(';');
      if (fields.length >= 3) {
        final groupId = fields[0].trim();
        final itemName = fields[1].trim();
        final status = fields[2].toLowerCase() == 'true';

        importedItems.add({
          'groupId': groupId,
          'name': itemName,
          'isDone': status,
        });
        print(
            'Imported Item - Group: $groupId, Name: $itemName, Status: $status');
      }
    }

    // You can now save these items into a new or existing list
  }

  Future<void> _createList() async {
    if (_listNameController.text.trim().isEmpty ||
        _listNameController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Der Name der Einkaufsliste muss mindestens 3 Zeichen lang sein.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (_selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bitte wählen Sie ein Bild aus.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final newList = Itemlist(
      name: _listNameController.text.trim(),
      groupId: '', // `groupId` wird später festgelegt
      imagePath: _selectedImagePath!,
      items: _items,
    );

    await widget.isar.writeTxn(() async {
      await widget.isar.itemlists.put(newList);
    });

    // Weiterleitung zum ChooseStoreScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreScreen(
          listId: newList.id.toString(),
          listName: newList.name,
          isar: widget.isar,
          onStoreSelected: (selectedStoreId) async {
            newList.groupId = selectedStoreId; // Setze den Store

            await widget.isar.writeTxn(() async {
              await widget.isar.itemlists.put(newList);
            });

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ItemListScreen(
                  listName: newList.name,
                  shoppingListId:
                      newList.id.toString(), // Übergebe hier die shoppingListId
                  items: [newList],
                  initialStoreId: selectedStoreId,
                  isar: widget.isar,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Neue Einkaufsliste erstellen"),
        backgroundColor: const Color(0xFF334B46),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _listNameController,
              decoration: const InputDecoration(
                labelText: 'Name der Einkaufsliste',
                filled: true,
                fillColor: Color(0xFF4A6963),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedTemplateId,
              onChanged: (value) {
                if (value != null) _applyTemplate(value);
              },
              items: _templateItems,
              hint: const Text('Vorlage auswählen',
                  style: TextStyle(color: Colors.white)),
              isExpanded: true,
              dropdownColor: const Color(0xFF4A6963),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedImagePath,
              onChanged: (value) {
                setState(() {
                  _selectedImagePath = value;
                });
              },
              items: imageNameToPath.keys.map((name) {
                return DropdownMenuItem<String>(
                  value: imageNameToPath[name],
                  child:
                      Text(name, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              hint: const Text('Bild auswählen',
                  style: TextStyle(color: Colors.white)),
              isExpanded: true,
              dropdownColor: const Color(0xFF4A6963),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _createList,
              icon: const Icon(Icons.add),
              label: const Text('Neue Einkaufsliste erstellen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF587A6F),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10), // Add spacing between buttons
            ElevatedButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles();
                if (result != null) {
                  final file = File(result.files.single.path!);
                  final csvContent = await file.readAsString();
                  await importList(csvContent);
                }
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Liste importieren'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF587A6F),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
