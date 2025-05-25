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

import 'package:smart/services/itemlist_service.dart';
import 'package:smart/services/productgroup_service.dart';
import 'package:smart/services/shop_service.dart';
import 'package:smart/services/template_service.dart';

class CreateListScreen extends StatefulWidget {
  final ItemListService itemListService;
  final ShopService shopService;
  final ProductGroupService productGroupService;
  final TemplateService templateService;

  const CreateListScreen({
    super.key,
    required this.itemListService,
    required this.shopService,
    required this.productGroupService,
    required this.templateService,
  });

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
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
    'lib/img/bild6.png': 'Büro',
  };

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await widget.templateService.fetchAllTemplates();
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
    final template =
        await widget.templateService.fetchTemplateById(int.parse(templateId));
    if (template != null) {
      setState(() {
        _listNameController.text = template.name;
        _selectedImagePath = template.imagePath;
        _items = template.getItems();
        _selectedTemplateId = templateId;
      });
    }
  }

  Future<void> _createList() async {
    if (_listNameController.text.trim().length < 3 ||
        _selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Namen (mind. 3 Zeichen) und Bild wählen.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newList = Itemlist(
      name: _listNameController.text.trim(),
      shopId: '',
      imagePath: _selectedImagePath!,
      items: _items,
      creationDate: DateTime.now(),
    );

    await widget.itemListService.addItemList(newList);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreScreen(
          listId: newList.id.toString(),
          listName: newList.name,
          itemListService: widget.itemListService,
          shopService: widget.shopService,
          productGroupService: widget.productGroupService,
          onStoreSelected: (selectedStoreId) async {
            newList.shopId = selectedStoreId;
            await widget.itemListService.updateItemList(newList);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ItemListScreen(
                  listName: newList.name,
                  shoppingListId: newList.id.toString(),
                  items: [newList],
                  initialStoreId: selectedStoreId,
                  itemListService: widget.itemListService,
                  shopService: widget.shopService,
                  productGroupService: widget.productGroupService,
                ),
              ),
            );
          },
        ),
      ),
    );
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
      final existingShop = await widget.shopService.fetchShopByName(shopName);
      shopId = existingShop?.id ?? -1;

      debugPrint(
          'Found existing shop: Name = ${existingShop?.name}, ID = $shopId');

      if (shopId != -1) {
        for (String groupName in importedGroupNames) {
          final existingGroup = await widget.productGroupService
              .fetchByNameAndShop(groupName, shopId.toString());
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

      shopName = await createUniqueShop(shopName);
      final newShop = Einkaufsladen(name: shopName);
      shopId = await widget.shopService.addShop(newShop);

      for (int i = 0; i < importedGroupNames.length; i++) {
        final groupName = importedGroupNames[i];
        final productGroup = Productgroup(
          name: groupName,
          storeId: shopId.toString(),
          order: i,
        );
        final groupId =
            await widget.productGroupService.addProductGroup(productGroup);
        groupNameToId[groupName] = groupId.toString();
        debugPrint(
            "Created new group in new shop: Name = $groupName, ID = $groupId");
      }

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

    await widget.itemListService.addItemList(newList);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<String> createUniqueShop(String shopName) async {
    String uniqueName = shopName;
    int counter = 1;

    while (true) {
      final existingShop = await widget.shopService.fetchShopByName(uniqueName);

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
    final existingShop = await widget.shopService.fetchShopByName(shopName);

    if (existingShop != null) {
      final existingGroups = await widget.productGroupService
          .fetchProductGroupsByStoreIdSorted(existingShop.id.toString());

      List<String> existingGroupNames =
          existingGroups.map((g) => g.name.trim()).toList();
      List<String> normalizedImported =
          importedGroupNames.map((n) => n.trim()).toList();

      debugPrint(
          "Comparing imported groups with existing shop (order preserved)...");
      debugPrint("Shop Name: $shopName");
      debugPrint("Imported Groups: $normalizedImported");
      debugPrint("Existing Groups: $existingGroupNames");

      if (_deepEquals(existingGroupNames, normalizedImported)) {
        debugPrint("Exact match found for shop: $shopName");
        return true;
      } else {
        debugPrint("No exact match found.");
      }
    } else {
      debugPrint("Shop not found: $shopName");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Neue Einkaufsliste erstellen"),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
      ),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
     body: LayoutBuilder(
  builder: (context, constraints) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Padding(
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
                          color: Color.fromARGB(255, 46, 46, 46),
                          fontSize: 16,
                        ),
                        children: const [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFFBDBDBD),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFFBDBDBD),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5A462),
                        width: 2,
                      ),
                    ),
                  ),
                  style: const TextStyle(
                    color: Color.fromARGB(255, 26, 26, 26),
                  ),
                ),

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
                        style: const TextStyle(color: Color(0xFF212121)),
                      ),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    label: RichText(
                      text: const TextSpan(
                        text: 'Bild auswählen',
                        style: TextStyle(
                          color: Color.fromARGB(255, 52, 52, 52),
                          fontSize: 16,
                        ),
                        children: [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFBDBDBD), width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5A462), width: 2),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Color(0xFF212121)),
                ),

                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedTemplateId,
                  onChanged: (value) {
                    if (value != null) _applyTemplate(value);
                  },
                  items: _templateItems,
                  decoration: InputDecoration(
                    label: RichText(
                      text: const TextSpan(
                        text: 'Vorlage auswählen',
                        style: TextStyle(
                          color: Color.fromARGB(255, 58, 58, 58),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFBDBDBD), width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5A462), width: 2),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    color: Color(0xFF212121),
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: Color(0xFFBDBDBD), thickness: 1),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'ODER',
                        style: TextStyle(
                          color: Color.fromARGB(255, 109, 108, 108),
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: Color(0xFFBDBDBD), thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles();
                      if (result != null) {
                        final file = File(result.files.single.path!);
                        try {
                          final csvContent =
                              await file.readAsString(encoding: utf8);
                          await importList(csvContent);
                        } catch (e) {
                          debugPrint("UTF-8 decoding failed $e");
                        }
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text(
                      'Liste importieren',
                      style: TextStyle(
                        fontSize: 23,
                        color: Color.fromARGB(255, 105, 105, 105),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD3D3D3),
                      foregroundColor: const Color(0xFF4A4A4A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                ),

                const Spacer(), // 👈 schiebt den Button ganz ans untere Ende

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_listNameController.text.isNotEmpty &&
                            _selectedImagePath != null)
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
                      backgroundColor:
                          MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return const Color.fromARGB(255, 255, 255, 255);
                          }
                          return Colors.white;
                        },
                      ),
                      foregroundColor:
                          MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return const Color.fromARGB(255, 249, 217, 169);
                          }
                          return const Color(0xFFE5A462);
                        },
                      ),
                      side: MaterialStateProperty.resolveWith<BorderSide>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return const BorderSide(
                              color: Color.fromARGB(255, 255, 226, 182),
                              width: 3.0,
                            );
                          }
                          return const BorderSide(
                            color: Color(0xFFE5A462),
                            width: 3.0,
                          );
                        },
                      ),
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
               ),
      ),
    );
  },
), // LayoutBuilder
); // Scaffold
} 
} // 👈 FEHLT bei dir: schließt die build-Methode