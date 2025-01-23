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
    'Einkaufssackerl ': 'lib/img/bild1.png',
    'Schneidebrett': 'lib/img/bild2.png',
    'Drogerie': 'lib/img/bild3.png',
    'Gardening': 'lib/img/bild4.png',
    'Party': 'lib/img/bild5.png',
    'Büro': 'lib/img/bild6.png',
  };

  final Map<String, String> imagePathToName = {
    'lib/img/bild1.png': 'Einkaufssackerl',
    'lib/img/bild2.png': 'Schneidebrett',
    'lib/img/bild3.png': 'Drogerie',
    'lib/img/bild4.png': 'Gardening',
    'lib/img/bild5.png': 'Party',
    'lib/img/bild6.png': 'Bür0',
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

      List<String> existingGroupNames =
          existingGroups.map((group) => group.name.trim()).toList();
      List<String> normalizedImportedGroupNames =
          importedGroupNames.map((name) => name.trim()).toList();

      debugPrint(
          "Comparing imported groups with existing shop (order preserved)...");
      debugPrint("Shop Name: $shopName");
      debugPrint(
          "Imported Groups (order-preserved): $normalizedImportedGroupNames");
      debugPrint("Existing Shop Groups (order-preserved): $existingGroupNames");

      if (_deepEquals(existingGroupNames, normalizedImportedGroupNames)) {
        debugPrint(
            "Exact match found for shop: $shopName with correct group order.");
        return true;
      } else {
        debugPrint("No exact match found. Group order or names do not match.");
      }
    } else {
      debugPrint("No shop found with the name: $shopName");
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

    debugPrint("Starting import for list: $listName, with shop: $shopName");

    List<String> importedGroupNames = lines[0]
        .split(';')
        .skip(3)
        .where((groupName) => groupName.isNotEmpty)
        .map((name) => name.trim())
        .toList();

    debugPrint("Imported Group Names (normalized): $importedGroupNames");

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

      debugPrint(
          'Found existing shop: Name = ${existingShop?.name}, ID = $shopId');

      if (shopId != -1) {
        for (String groupName in importedGroupNames) {
          final existingGroup = await widget.isar.productgroups
              .filter()
              .nameEqualTo(groupName)
              .storeIdEqualTo(shopId.toString())
              .findFirst();
          if (existingGroup != null) {
            groupNameToId[groupName] = existingGroup.id.toString();
            debugPrint(
                "Found existing group: Name = ${existingGroup.name}, ID = ${existingGroup.id}");
          } else {
            debugPrint("Group not found in existing shop: $groupName");
          }
        }
      } else {
        debugPrint("Shop ID retrieval failed for shop: $shopName");
      }
    } else {
      debugPrint(
          "No matching shop with correct group order. Creating a new shop.");

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
          debugPrint(
              "Created new group in new shop: Name = $groupName, ID = $groupId");
        }
      });
      debugPrint(
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
        debugPrint(
            "Imported item: Group ID = $groupId, Name = $itemName, Status = $status");
      }
    }

    debugPrint("Final imported items: $importedItems");

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
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
      ),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _listNameController,
              cursorColor: Color.fromARGB(255, 37, 37, 37),
              decoration: InputDecoration(
                label: RichText(
                  text: TextSpan(
                    text: 'Name',
                    style: const TextStyle(
                      color: Color.fromARGB(
                          255, 46, 46, 46), // Label-Farbe (Orange)
                      fontSize: 16,
                    ),
                    children: const [
                      TextSpan(
                        text: ' *', // Sternchen hinzufügen
                        style: TextStyle(
                          color: Colors.red, // Sternchen-Farbe (Rot)
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                filled: true,
                fillColor: Colors.white, // Weißer Hintergrund innen
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFBDBDBD), // Grauer Rand
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(
                        0xFFBDBDBD), // Grauer Rand für nicht fokussierten Zustand
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(
                        0xFFE5A462), // Orangefarbener Rand für fokussierten Zustand
                    width: 2, // Etwas dicker für den Fokus
                  ),
                ),
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 26, 26, 26), // Dunkle Schriftfarbe
              ),
            ),
            // DROPWDOWN BILD AUSWÄHLEN
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedImagePath,
              onChanged: (value) {
                setState(() {
                  _selectedImagePath = value;
                });
              },
              items: imageNameToPath.keys.map((name) {
                return DropdownMenuItem<String>(
                  value: imageNameToPath[name],
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFF212121), // Dropdown-Textfarbe
                    ),
                  ),
                );
              }).toList(),
              decoration: InputDecoration(
                label: RichText(
                  text: TextSpan(
                    text: 'Bild auswählen',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 52, 52, 52), // Orange Label
                      fontSize: 16,
                    ),
                    children: const [
                      TextSpan(
                        text: ' *', // Sternchen hinzufügen
                        style: TextStyle(
                          color: Colors.red, // Sternchen-Farbe (Rot)
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                filled: true,
                fillColor: Colors.white, // Hintergrundfarbe
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFBDBDBD), // Grauer Rand
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(
                        0xFFBDBDBD), // Grauer Rand für nicht fokussierten Zustand
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(
                        0xFFE5A462), // Orange Rand für fokussierten Zustand
                    width: 2,
                  ),
                ),
              ),
              dropdownColor: Colors.white, // Dropdown-Hintergrund
              style: const TextStyle(
                color: Color(0xFF212121), // Textfarbe im Dropdown
              ),
            ),

            // DROPWDOWN VORLAGE
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedTemplateId,
              onChanged: (value) {
                if (value != null) _applyTemplate(value);
              },
              items: _templateItems,
              decoration: InputDecoration(
                label: RichText(
                  text: TextSpan(
                    text: 'Vorlage auswählen',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 58, 58, 58), // Orange Label
                      fontSize: 16, // Schriftgröße anpassen
                    ),
                    children: const [
                      TextSpan(
                        text: '', // Sternchen hinzufügen
                        style: TextStyle(
                          color: Colors.red, // Sternchen-Farbe
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                filled: true,
                fillColor: Colors.white, // Hintergrundfarbe
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFBDBDBD), // Grauer Rand
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(
                        0xFFBDBDBD), // Grauer Rand für nicht fokussierten Zustand
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(
                        0xFFE5A462), // Orange Rand für fokussierten Zustand
                    width: 2,
                  ),
                ),
              ),
              dropdownColor: Colors.white, // Dropdown-Hintergrund
              style: const TextStyle(
                color: Color(0xFF212121), // Textfarbe im Dropdown
                fontSize: 16, // Schriftgröße
              ),
            ),

// Text "ODER"
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Color(0xFFBDBDBD), // Farbe der Linie
                    thickness: 1, // Dicke der Linie
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'ODER',
                    style: TextStyle(
                      color: Color.fromARGB(255, 109, 108, 108), // Textfarbe
                      fontSize: 22, // Schriftgröße
                      fontWeight: FontWeight.w500, // Schriftstärke
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Color(0xFFBDBDBD), // Farbe der Linie
                    thickness: 1, // Dicke der Linie
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            //BUTTON LISTE IMPORTIEREN
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null) {
                    final file = File(result.files.single.path!);
                    String csvContent;

                    try {
                      csvContent = await file.readAsString(encoding: utf8);
                      await importList(csvContent);
                    } catch (e) {
                      debugPrint("UTF-8 decoding failed$e");
                    }
                  }
                },
                icon: const Icon(Icons.upload_file),
                label: const Text(
                  'Liste importieren',
                  style: TextStyle(
                      fontSize: 23, // Schriftgröße
                      color: Color.fromARGB(255, 105, 105, 105),
                      fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD3D3D3),
                  foregroundColor: const Color(0xFF4A4A4A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  minimumSize: const Size.fromHeight(
                      56), // Gleiche Größe wie bei Homepage-Buttons
                ),
              ),
            ),

            // BUTTON WEITER
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: double.infinity,
                child: 

                ElevatedButton(
  onPressed: (_listNameController.text.isNotEmpty && _selectedImagePath != null)
      ? _createList
      : null,
  child: const Text(
    'Weiter',
    style: TextStyle(
      fontSize: 23,
      fontWeight: FontWeight.w700,
    ),
  ),
  style: ButtonStyle(
    // Hintergrundfarbe je nach Zustand
    backgroundColor: MaterialStateProperty.resolveWith<Color>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return Color.fromARGB(255, 255, 255, 255); // Heller Orange-Ton für disabled
        }
        return Colors.white; // Weißer Hintergrund für enabled
      },
    ),
    // Textfarbe je nach Zustand
    foregroundColor: MaterialStateProperty.resolveWith<Color>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return Color.fromARGB(255, 249, 217, 169); // Abgeschwächtes Orange für disabled
        }
        return const Color(0xFFE5A462); // Starkes Orange für enabled
      },
    ),
    // Randfarbe je nach Zustand
    side: MaterialStateProperty.resolveWith<BorderSide>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return const BorderSide(
            color: Color.fromARGB(255, 255, 226, 182), // Abgeschwächter Rand für disabled
            width: 3.0,
          );
        }
        return const BorderSide(
          color: Color(0xFFE5A462), // Starker orangefarbener Rand für enabled
          width: 3.0,
        );
      },
    ),
    padding: MaterialStateProperty.all(
      const EdgeInsets.symmetric(vertical: 16.0),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Abgerundete Ecken
      ),
    ),
  ),
),

              ),
            ),
          ],
        ),
      ),
    );
  }
}
