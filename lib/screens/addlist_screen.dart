import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart/screens/choosestore_screen.dart';
import 'package:smart/screens/itemslist_screen.dart';
import '../objects/itemlist.dart';
import '../objects/template.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:smart/objects/productgroup.dart';
import '../objects/shop.dart';
import 'dart:convert';

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
      String shopName, List<String> importedGroupNames) async {
    final existingShop = await widget.isar.einkaufsladens
        .filter()
        .nameEqualTo(shopName)
        .findFirst();

    if (existingShop != null) {
      final existingGroups = await widget.isar.productgroups
          .filter()
          .storeIdEqualTo(existingShop.id.toString())
          .sortByOrder()
          .findAll();

      List<String> existingGroupNames = existingGroups
          .map((group) => group.name.trim())
          .toList();
      List<String> normalizedImportedGroupNames =
          importedGroupNames.map((name) => name.trim()).toList();

      print(
          "Comparing imported groups with existing shop (order preserved)...");
      print("Shop Name: $shopName");
      print("Imported Groups (order-preserved): $normalizedImportedGroupNames");
      print("Existing Shop Groups (order-preserved): $existingGroupNames");

      if (_deepEquals(existingGroupNames, normalizedImportedGroupNames)) {
        print(
            "Exact match found for shop: $shopName with correct group order.");
        return true;
      } else {
        print("No exact match found. Group order or names do not match.");
      }
    } else {
      print("No shop found with the name: $shopName");
    }
    return false;
  }

  bool _deepEquals(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  Future<void> importList(String csvContent) async {
    List<String> lines = csvContent.split('\n');
    if (lines.isEmpty) return;

    String listName = lines[0].split(';')[0].trim();
    String imagepath = lines[0].split(';')[1].trim();
    String shopName = lines[0].split(';')[2].trim();

    print("Starting import for list: $listName, with shop: $shopName");

    List<String> importedGroupNames = lines[0]
        .split(';')
        .skip(3)
        .where((groupName) => groupName.isNotEmpty)
        .map((name) => name.trim())
        .toList();

    print("Imported Group Names (normalized): $importedGroupNames");

    int shopId = -1;
    Map<String, String> groupNameToId = {};

    bool matchingOrder =
        await isProductGroupOrderMatching(shopName, importedGroupNames);
    if (matchingOrder) {
      final existingShop = await widget.isar.einkaufsladens
          .filter()
          .nameEqualTo(shopName)
          .findFirst();
      shopId = existingShop?.id ?? -1;

      print('Found existing shop: Name = ${existingShop?.name}, ID = $shopId');

      if (shopId != -1) {
        for (String groupName in importedGroupNames) {
          final existingGroup = await widget.isar.productgroups
              .filter()
              .nameEqualTo(groupName)
              .storeIdEqualTo(shopId.toString())
              .findFirst();
          if (existingGroup != null) {
            groupNameToId[groupName] = existingGroup.id.toString();
            print(
                "Found existing group: Name = ${existingGroup.name}, ID = ${existingGroup.id}");
          } else {
            print("Group not found in existing shop: $groupName");
          }
        }
      } else {
        print("Shop ID retrieval failed for shop: $shopName");
      }
    } else {
      print("No matching shop with correct group order. Creating a new shop.");

      // if shops don't match
      shopName = await createUniqueShop(shopName);
      final newShop = Einkaufsladen(name: shopName);
      await widget.isar.writeTxn(() async {
        shopId = await widget.isar.einkaufsladens.put(newShop);
        for (int i = 0; i < importedGroupNames.length; i++) {
          final groupName = importedGroupNames[i];
          final productGroup = Productgroup(
            name: groupName,
            storeId: shopId.toString(),
            order: i,
          );
          final groupId = await widget.isar.productgroups.put(productGroup);
          groupNameToId[groupName] = groupId.toString();
          print(
              "Created new group in new shop: Name = $groupName, ID = $groupId");
        }
      });
      print(
          "Created new shop with name: $shopName, ID: $shopId, and groups: $groupNameToId");
    }

    List<Map<String, dynamic>> importedItems = [];
    for (int i = 1; i < lines.length; i++) {
      var line = lines[i].trim();
      if (line.isEmpty) continue;

      var fields = line.split(';');
      if (fields.length >= 3) {
        final groupName = fields[0].trim();
        final groupId = groupNameToId[groupName] ?? "0";
        final itemName = fields[1].trim();
        final status = fields[2] == 'true';

        importedItems.add({
          'groupId': groupId,
          'name': itemName,
          'isDone': status,
        });
        print(
            "Imported item: Group ID = $groupId, Name = $itemName, Status = $status");
      }
    }

    print("Final imported items: $importedItems");

    final newList = Itemlist(
      name: listName,
      imagePath: imagepath,
      shopId: shopId.toString(),
      items: importedItems,
      creationDate: DateTime.now(),
    );

    await widget.isar.writeTxn(() async {
      await widget.isar.itemlists.put(newList);
    });
    Navigator.popUntil(context, (route) => route.isFirst);
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
      shopId: '',
      imagePath: _selectedImagePath!,
      items: _items,
      creationDate: DateTime.now(),
    );

    await widget.isar.writeTxn(() async {
      await widget.isar.itemlists.put(newList);
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreScreen(
          listId: newList.id.toString(),
          listName: newList.name,
          isar: widget.isar,
          onStoreSelected: (selectedStoreId) async {
            newList.shopId = selectedStoreId;
            await widget.isar.writeTxn(() async {
              await widget.isar.itemlists.put(newList);
            });

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ItemListScreen(
                  listName: newList.name,
                  shoppingListId: newList.id.toString(),
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
                child: Text(name, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            hint: const Text('Bild auswählen',
                style: TextStyle(color: Colors.white)),
            isExpanded: true,
            dropdownColor: const Color(0xFF4A6963),
          ),
          const SizedBox(height: 20),

          if (_selectedImagePath != null) 
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Image.asset(
                _selectedImagePath!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
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
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles();
              if (result != null) {
                final file = File(result.files.single.path!);
                String csvContent;

                try {
                  csvContent = await file.readAsString(encoding: utf8);
                  await importList(csvContent);
                } catch (e) {
                  print("UTF-8 decoding failed$e");
                }
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