import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart/objects/productgroup.dart';
import 'package:smart/objects/shop.dart';
import '../objects/itemlist.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf_wd;

import '../services/itemlist_service.dart';
import '../services/productgroup_service.dart';
import '../services/shop_service.dart';

class ItemListScreen extends StatefulWidget {
  final String listName;
  final String shoppingListId;
  final List<Itemlist>? items;
  final String? initialStoreId;
  final ItemListService itemListService;
  final ProductGroupService productGroupService;
  final ShopService shopService;

  const ItemListScreen({
    super.key,
    required this.listName,
    required this.shoppingListId,
    this.items,
    this.initialStoreId,
    required this.itemListService,
    required this.productGroupService,
    required this.shopService,
  });

  @override
  _ItemListScreenState createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  Map<String, List<Map<String, dynamic>>> itemsByGroup = {};
  bool _isDeleteMode = false;
  Set<String> selectedItems = {};
  Set<String> selectedGroups = {};
  List<Itemlist> items = [];
  String? currentStoreId;
  List<Einkaufsladen> _availableShops = []; // Liste aller Shops
  String? _selectedShopId; // Die aktuell gewählte Shop-ID
  String _selectedShopName =
      "Kein Shop gefunden"; // Fallback falls kein Shop existiert

  @override
  void initState() {
    super.initState();
    items = widget.items ?? [];
    loadShops();
  }

  void toggleDeleteMode() {
    setState(() {
      if (_isDeleteMode) {
        selectedItems.clear();
        selectedGroups.clear();
      }
      _isDeleteMode = !_isDeleteMode;
    });
  }

  void deleteProductGroup(String groupName) async {
    final list = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));
    if (list == null) return;

    final currentItems = list.getItems();
    final remainingItems = currentItems.where((item) {
      final group = itemsByGroup[groupName];
      return group == null ||
          !group.any((element) => element['name'] == item['name']);
    }).toList();

    list.setItems(remainingItems);
    await widget.itemListService.updateItemList(list);

    setState(() {
      itemsByGroup.remove(groupName);
    });
  }

  void deleteItem(String groupName, String itemName) async {
    final list = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));
    if (list == null) return;

    final currentItems = list.getItems();
    final updatedItems =
        currentItems.where((item) => item['name'] != itemName).toList();

    list.setItems(updatedItems);
    await widget.itemListService.updateItemList(list);

    setState(() {
      itemsByGroup[groupName]?.removeWhere((item) => item['name'] == itemName);
      if (itemsByGroup[groupName]?.isEmpty ?? false) {
        itemsByGroup.remove(groupName);
      }
    });
  }

  Future<void> loadItems() async {
    if (_selectedShopId == null) return;

    final productGroups =
        await widget.productGroupService.fetchProductGroups(_selectedShopId!);

    final savedList = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));

    if (savedList != null) {
      final savedItems = savedList.getItems();

      Map<String, List<Map<String, dynamic>>> groupedItems = {};
      for (var singleItem in savedItems) {
        final groupName = productGroups
            .firstWhere((g) => g.id.toString() == singleItem['groupId'],
                orElse: () =>
                    Productgroup(name: 'Unbekannt', storeId: '0', order: 0))
            .name;
        groupedItems.putIfAbsent(groupName, () => []).add(singleItem);
      }

      Map<String, List<Map<String, dynamic>>> orderedGroupedItems = {};
      for (var group in productGroups) {
        if (groupedItems.containsKey(group.name)) {
          orderedGroupedItems[group.name] = groupedItems[group.name]!;
        }
      }

      setState(() {
        itemsByGroup = orderedGroupedItems;
      });
    }
  }

  String _getGroupNameById(String groupId, List<Productgroup> productGroups) {
    return productGroups
        .firstWhere(
          (group) => group.id.toString() == groupId,
          orElse: () => Productgroup(name: 'Unbekannt', storeId: 'x', order: 0),
        )
        .name;
  }

  void loadShops() async {
    final shops = await widget.shopService.fetchShops();

    final list = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));

    setState(() {
      _availableShops = shops;
      if (list != null) {
        _selectedShopId = list.shopId;
        _selectedShopName = shops
            .firstWhere(
              (shop) => shop.id.toString() == list.shopId,
              orElse: () =>
                  Einkaufsladen(name: "Kein Shop gefunden", imagePath: null),
            )
            .name;
      }
    });

    await loadItems();
  }

  void _updateShop(String newShopId) async {
    final newShop =
        _availableShops.firstWhere((shop) => shop.id.toString() == newShopId);

    final list = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));
    if (list == null) return;

    final currentItems = list.getItems();

    final allGroups = await widget.productGroupService
        .fetchProductGroups(widget.initialStoreId!);
    final newShopGroups =
        await widget.productGroupService.fetchProductGroups(newShopId);

    final Map<String, Productgroup> nameToGroup = {
      for (var group in newShopGroups) group.name: group
    };

    final existingGroupNames = nameToGroup.keys.toSet();
    final usedGroupNames = currentItems
        .map((item) => _getGroupNameById(item['groupId'], allGroups))
        .toSet();

    final missingGroupNames =
        usedGroupNames.difference(existingGroupNames).toList()..sort();

    int maxOrder = newShopGroups.isEmpty
        ? 0
        : newShopGroups.map((g) => g.order).reduce((a, b) => a > b ? a : b);

    for (var i = 0; i < missingGroupNames.length; i++) {
      final newGroup = Productgroup(
        name: missingGroupNames[i],
        storeId: newShopId,
        order: maxOrder + i + 1,
      );

      final newGroupId =
          await widget.productGroupService.addProductGroup(newGroup);
      nameToGroup[missingGroupNames[i]] = newGroup..id = newGroupId;
    }

    for (var item in currentItems) {
      final originalGroupName = _getGroupNameById(item['groupId'], allGroups);
      final newGroup = nameToGroup[originalGroupName];
      if (newGroup != null) {
        item['groupId'] = newGroup.id.toString();
      }
    }

    list.shopId = newShopId;
    list.setItems(currentItems);

    // ✅ ersetzt durch Service
    await widget.itemListService.updateItemList(list);

    setState(() {
      _selectedShopId = newShopId;
      _selectedShopName = newShop.name;
    });

    loadItems();
  }

  Future<void> toggleItemDone(String groupName, int itemIndex) async {
    final itemDetails = itemsByGroup[groupName]![itemIndex];
    setState(() {
      itemDetails['isDone'] = !(itemDetails['isDone'] ?? false);
    });

    final list = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));
    if (list != null) {
      final currentItems = list.getItems();
      final itemToUpdate = currentItems.firstWhere(
        (item) => item['name'] == itemDetails['name'],
        orElse: () => {},
      );

      if (itemToUpdate.isNotEmpty) {
        itemToUpdate['isDone'] = itemDetails['isDone'];
        list.setItems(currentItems);

        await widget.itemListService.updateItemList(list);
      }
    }
  }

  void _addItemToList(String itemName, String groupId) async {
    final list = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));
    if (list == null) return;

    final currentItems = List<Map<String, dynamic>>.from(list.getItems());
    currentItems.add({'name': itemName, 'isDone': false, 'groupId': groupId});
    list.setItems(currentItems);

    await widget.itemListService.updateItemList(list);

    await loadItems();
  }

  void _showAddItemDialog() async {
    TextEditingController itemNameController = TextEditingController();
    TextEditingController newGroupNameController = TextEditingController();
    String? selectedGroupId;

    final productGroups = await widget.productGroupService
        .fetchProductGroups(widget.initialStoreId!);

    List<DropdownMenuItem<String>> groupItems = productGroups.map((group) {
      return DropdownMenuItem<String>(
        value: group.id.toString(),
        child: Text(group.name),
      );
    }).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Color.fromARGB(255, 255, 255, 255),
            title: const Text('Artikel hinzufügen',
                style: TextStyle(color: Color.fromARGB(255, 22, 22, 22))),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: itemNameController,
                    decoration: InputDecoration(
                      labelText: 'Artikelname',
                      labelStyle: const TextStyle(
                        color: Color.fromARGB(255, 54, 54, 54),
                        fontSize: 16,
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
                  Container(
                    width: MediaQuery.of(context).size.width *
                        0.8, // Dynamische Breite
                    child: DropdownButtonFormField<String>(
                      value: selectedGroupId,
                      onChanged: (newValue) {
                        setState(() {
                          selectedGroupId = newValue;
                        });
                      },
                      items: groupItems,
                      isExpanded: true,
                      icon:
                          const SizedBox.shrink(), // 👈 Icon ganz deaktivieren
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFBDBDBD), width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFBDBDBD), width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5A462), width: 2),
                        ),
                      ),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: Color(0xFF212121),
                        fontSize: 16,
                      ),
                      hint: Row(
                        children: const [
                          Expanded(
                            child: Text(
                              'Warengruppe wählen',
                              style: TextStyle(
                                color: Color.fromARGB(255, 54, 54, 54),
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_drop_down, color: Color(0xFFE5A462)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                          255, 239, 141, 37), // Orangener Hintergrund
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12), // Abgerundete Ecken
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                    ),
                    child: const Text(
                      'Artikel hinzufügen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ), // Weiße Schrift
                    ),
                    onPressed: () async {
                      if (itemNameController.text.isNotEmpty) {
                        if (selectedGroupId != null) {
                          _addItemToList(
                              itemNameController.text, selectedGroupId!);
                        } else if (newGroupNameController.text.isNotEmpty) {
                          final lastGroup = await widget.productGroupService
                              .fetchLastGroupByStoreId(widget.initialStoreId!);

                          final newOrder =
                              lastGroup != null ? lastGroup.order + 1 : 0;

                          Productgroup newGroup = Productgroup(
                            name: newGroupNameController.text,
                            storeId: widget.initialStoreId!,
                            order: newOrder,
                          );

                          // ✅ Service zum Hinzufügen verwenden
                          final newGroupId = await widget.productGroupService
                              .addProductGroup(newGroup);
                          newGroup.id = newGroupId;

                          _addItemToList(
                              itemNameController.text, newGroup.id.toString());
                        }
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: newGroupNameController,
                    decoration: InputDecoration(
                      labelText: 'Neue Warengruppe hinzufügen',
                      labelStyle: const TextStyle(
                        color: Color.fromARGB(255, 54, 54, 54),
                        fontSize: 16,
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
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                          255, 239, 141, 37), // Orangener Hintergrund
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12), // Abgerundete Ecken
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                    ),
                    child: const Text(
                      'Warengruppe hinzufügen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ), // Weiße Schrift
                    ),
                    onPressed: () async {
                      if (newGroupNameController.text.isNotEmpty) {
                        // ✅ zuletzt sortierte Gruppe holen
                        final lastGroup = await widget.productGroupService
                            .fetchLastGroupByStoreId(widget.initialStoreId!);

                        final newOrder =
                            lastGroup != null ? lastGroup.order + 1 : 0;

                        // ✅ neue Gruppe erstellen und via Service speichern
                        Productgroup newGroup = Productgroup(
                          name: newGroupNameController.text,
                          storeId: widget.initialStoreId!,
                          order: newOrder,
                        );
                        final newGroupId = await widget.productGroupService
                            .addProductGroup(newGroup);
                        newGroup.id = newGroupId;

                        // ✅ Dropdown aktualisieren
                        setState(() {
                          groupItems.add(DropdownMenuItem<String>(
                            value: newGroup.id.toString(),
                            child: Text(newGroup.name),
                          ));
                          selectedGroupId = newGroup.id.toString();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  //PDF erstellem
  Future<void> createPdf() async {
    final pdf = pdf_wd.Document();
    pdf.addPage(pdf_wd.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pdf_wd.Context context) {
        return pdf_wd.Column(
          crossAxisAlignment: pdf_wd.CrossAxisAlignment.start,
          children: [
            pdf_wd.Text(widget.listName,
                style: const pdf_wd.TextStyle(fontSize: 24)),
            pdf_wd.Divider(),
            ...itemsByGroup.entries.map((entry) {
              return pdf_wd.Column(
                crossAxisAlignment: pdf_wd.CrossAxisAlignment.start,
                children: [
                  pdf_wd.Text(entry.key,
                      style: pdf_wd.TextStyle(
                          fontSize: 18, fontWeight: pdf_wd.FontWeight.bold)),
                  ...entry.value.map((item) {
                    return pdf_wd.Text(item['name'] ?? 'Unnamed Item',
                        style: const pdf_wd.TextStyle(fontSize: 14));
                  }),
                ],
              );
            }),
          ],
        );
      },
    ));

    String pdfFileName = '${widget.listName.replaceAll(' ', '_')}.pdf';
    await Printing.sharePdf(bytes: await pdf.save(), filename: pdfFileName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100), // Extra Platz für Dropdown
        child: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.print), onPressed: createPdf),
            IconButton(
              icon: Icon(_isDeleteMode ? Icons.close : Icons.delete,
                  color: Colors.black),
              onPressed: toggleDeleteMode,
            ),
          ],
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 55.0), // Abstand zum Rand
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Hier wird alles linksbündig!
              mainAxisAlignment:
                  MainAxisAlignment.end, // Damit es nicht oben klebt
              children: [
                // Listenname (Titel)
                Text(
                  widget.listName,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                // Dropdown für den Shop
                DropdownButton<String>(
                  value: _selectedShopId,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _updateShop(newValue); // Speichert den neuen Shop in Isar
                    }
                  },
                  icon: const Icon(Icons.arrow_drop_down, size: 24),
                  iconEnabledColor: Color(0xFFE5A462),
                  padding: const EdgeInsets.only(
                      right: 8), // 👈 Icon nach links verschieben

                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6D4C41)),
                  dropdownColor: Colors.white,
                  underline: Container(),
                  items: _availableShops
                      .map<DropdownMenuItem<String>>((Einkaufsladen shop) {
                    return DropdownMenuItem<String>(
                      value: shop.id.toString(),
                      child: Text(shop.name,
                          style: const TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        itemCount: itemsByGroup.keys.length,
        itemBuilder: (context, index) {
          String groupId = itemsByGroup.keys.elementAt(index);
          return ExpansionTile(
            //WARENGRUPPEN DROPWDOWN
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    groupId,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 133, 131, 131),
                    ),
                  ),
                ),
                if (_isDeleteMode)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteProductGroup(groupId),
                  ),
              ],
            ),

            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...itemsByGroup[groupId]!.map((item) {
                    return Row(
                      children: [
                        // Checkbox im Delete-Modus links (readonly)
                        if (_isDeleteMode)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, right: 8.0),
                            child: Checkbox(
                              value: item['isDone'] ?? false,
                              onChanged: null, // readonly
                            ),
                          ),
                        //EINZELNE ARTIKEL
                        // ListTile mit Name & isDone-Checkbox rechts im Normalmodus
                        Expanded(
                          child: ListTile(
                            title: Text(
                              item['name'],
                              style: const TextStyle(fontSize: 23),
                            ),
                            trailing: !_isDeleteMode
                                ? Checkbox(
                                    value: item['isDone'] ?? false,
                                    onChanged: (bool? value) {
                                      if (value != null) {
                                        toggleItemDone(
                                          groupId,
                                          itemsByGroup[groupId]!.indexOf(item),
                                        );
                                      }
                                    },
                                  )
                                : null,
                          ),
                        ),
                        if (_isDeleteMode)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteItem(groupId, item['name']),
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
      // ADD ARTIKEL BUTTON
      floatingActionButton: !_isDeleteMode
          ? Padding(
              padding: const EdgeInsets.only(
                  right: 16.0, bottom: 16.0), // Abstand rechts und unten
              child: SizedBox(
                height: 80, // Höhe des Buttons
                width: 80, // Breite des Buttons
                child: FloatingActionButton(
                  onPressed: _showAddItemDialog,
                  backgroundColor:
                      Color.fromARGB(255, 239, 141, 37), // Hintergrundfarbe
                  foregroundColor: Colors.white, // Icon-Farbe
                  child: const Icon(Icons.add, size: 36), // Größeres Icon
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40), // Eckenradius
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
