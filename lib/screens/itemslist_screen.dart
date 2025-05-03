import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart/objects/productgroup.dart';
import 'package:smart/objects/shop.dart';
import '../objects/itemlist.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf_wd;

class ItemListScreen extends StatefulWidget {
  final String listName;
  final String shoppingListId;
  final List<Itemlist>? items;
  final String? initialStoreId;
  final Isar isar;

  const ItemListScreen({
    super.key,
    required this.listName,
    required this.shoppingListId,
    this.items,
    this.initialStoreId,
    required this.isar,
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

  void deleteSelectedItems() async {
    if (selectedItems.isEmpty && selectedGroups.isEmpty) {
      setState(() {
        _isDeleteMode = false;
      });
      return;
    }
    //check if all selected
    bool allItemsSelected = itemsByGroup.values
        .expand((groupItems) => groupItems)
        .every((item) => selectedItems.contains(item['name']));

    if (allItemsSelected) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF96b17c),
            title: const Text(
              'Liste löschen?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Mit diesem Schritt löschen Sie die gesamte Einkaufsliste. Möchten Sie fortfahren?',
              style: TextStyle(color: Colors.white),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Abbrechen',
                    style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Löschen',
                    style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  await widget.isar.writeTxn(() async {
                    await widget.isar.itemlists
                        .delete(int.parse(widget.shoppingListId));
                  });
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ],
          );
        },
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF96b17c),
          title:
              const Text('Bestätigen', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Möchten Sie das/die ausgewählte(n) Element wirklich löschen?',
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child:
                  const Text('Löschen', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  await widget.isar.writeTxn(() async {
                    final listToUpdate = await widget.isar.itemlists
                        .filter()
                        .idEqualTo(int.parse(widget.shoppingListId))
                        .findFirst();

                    if (listToUpdate == null) {
                      debugPrint("Fehler: Die Liste wurde nicht gefunden.");
                      return;
                    }

                    for (String groupId in itemsByGroup.keys.toList()) {
                      List<Map<String, dynamic>> itemsInGroup =
                          itemsByGroup[groupId]!;
                      itemsInGroup.removeWhere(
                          (item) => selectedItems.contains(item['name']));

                      if (itemsInGroup.isEmpty) {
                        itemsByGroup.remove(groupId);
                      } else {
                        itemsByGroup[groupId] = itemsInGroup;
                      }
                    }

                    List<Map<String, dynamic>> currentItems = [];
                    itemsByGroup.forEach((_, items) {
                      currentItems.addAll(items);
                    });

                    listToUpdate.setItems(currentItems);
                    await widget.isar.itemlists.put(listToUpdate);

                    await loadItems();
                  });
                } catch (e) {
                  debugPrint("Error during deletion: $e");
                }

                toggleDeleteMode();
                await loadItems();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> loadItems() async {
    print('🚀 loadItems() wurde aufgerufen!');

    // Überprüfung, ob ein Shop ausgewählt wurde
    if (_selectedShopId == null) {
      print('❌ Kein Shop ausgewählt. Abbruch.');
      return;
    }

    final allGroups = await widget.isar.productgroups.where().findAll();
    print(
        '🌍 ALLE Gruppen-IDs in DB: ${allGroups.map((g) => '${g.id} → ${g.name}').toList()}');

    // Warengruppen aus der Datenbank laden, sortiert nach Order
    final productGroups = await widget.isar.productgroups
        .filter()
        .storeIdEqualTo(_selectedShopId!) // ✅ Filter nach aktuellem Shop
        .sortByOrder() // ✅ Sortierung nach Reihenfolge aus der Datenbank
        .findAll();

    print(
        '📦 Geladene Warengruppen: ${productGroups.map((pg) => pg.name).toList()}');

    // Einkaufsliste aus der Datenbank laden
    Itemlist? savedList = await widget.isar.itemlists
        .filter()
        .idEqualTo(
            int.parse(widget.shoppingListId)) // 🔥 Laden der gesamten Liste
        .findFirst();

    if (savedList != null) {
      // Geladene Artikel aus der Liste abrufen
      List<Map<String, dynamic>> savedItems = savedList.getItems();
      print('🧐 Geladene Artikel in der Liste: $savedItems');

      // Artikel gruppieren basierend auf den Warengruppen
      Map<String, List<Map<String, dynamic>>> groupedItems = {};
      for (var singleItem in savedItems) {
        final groupName = productGroups
            .firstWhere((group) => group.id.toString() == singleItem['groupId']
                ,
                orElse: () => Productgroup( //prob needs better solution
                  name: 'Unbekannt',
                  storeId: '0',
                  order: 0,
                ),
                )
            .name;

        groupedItems.putIfAbsent(groupName, () => []).add(singleItem);
      }

      print('🔄 Gruppierte Artikel: $groupedItems');

      // Artikel in der Reihenfolge der Warengruppen sortieren
      Map<String, List<Map<String, dynamic>>> orderedGroupedItems = {};
      for (var group in productGroups) {
        if (groupedItems.containsKey(group.name)) {
          orderedGroupedItems[group.name] = groupedItems[group.name]!;
        }
      }

      // State aktualisieren und sortierte Artikel speichern
      setState(() {
        itemsByGroup = orderedGroupedItems;
      });

      // Debug-Ausgabe der finalen gruppierten Artikel
      debugPrint('==== Sortierte und gruppierte Artikel ====');
      for (var group in itemsByGroup.keys) {
        for (var item in itemsByGroup[group]!) {
          print('📋 Artikel: ${item['name']}, Erledigt: ${item['isDone']}');
        }
      }
      debugPrint('==========================================');
    } else {
      print('❌ Keine gespeicherte Liste gefunden.');
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
    // Lade alle verfügbaren Shops aus der Isar-Datenbank
    final shops =
        await widget.isar.collection<Einkaufsladen>().where().findAll();

    // Lade die Einkaufsliste mit der gespeicherten Shop-ID
    final list = await widget.isar.itemlists
        .filter()
        .idEqualTo(int.parse(widget.shoppingListId))
        .findFirst();

    setState(() {
      _availableShops = shops; // Speichert alle Shops für das Dropdown
      if (list != null) {
        _selectedShopId = list.shopId; // Speichert die Shop-ID der Liste
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

    await widget.isar.writeTxn(() async {
      final list = await widget.isar.itemlists
          .filter()
          .idEqualTo(int.parse(widget.shoppingListId))
          .findFirst();

      if (list == null) return;

      // 1. Artikel laden
      List<Map<String, dynamic>> currentItems = list.getItems();

      // 🔥 ALLE Gruppen laden, nicht nur vom neuen Shop
      final allGroups = await widget.isar.productgroups.where().findAll();

      // 2. Gruppen im neuen Shop laden
      final newShopGroups = await widget.isar.productgroups
          .filter()
          .storeIdEqualTo(newShopId)
          .findAll();

      // 3. Name -> Gruppe Map bauen
      final Map<String, Productgroup> nameToGroup = {
        for (var group in newShopGroups) group.name: group
      };

      // 4. Fehlende Gruppen vorbereiten
      Set<String> existingGroupNames = nameToGroup.keys.toSet();
      Set<String> usedGroupNames = currentItems
          .map((item) => _getGroupNameById(item['groupId'], allGroups))
          .toSet();

      List<String> missingGroupNames =
          usedGroupNames.difference(existingGroupNames).toList()..sort();

      // 5. Neue Gruppen anlegen mit passender Order (am Ende)
      int maxOrder = newShopGroups.isEmpty
          ? 0
          : newShopGroups.map((g) => g.order).reduce((a, b) => a > b ? a : b);

      for (var i = 0; i < missingGroupNames.length; i++) {
        final newGroup = Productgroup(
          name: missingGroupNames[i],
          storeId: newShopId,
          order: maxOrder + i + 1,
        );
        final newGroupId = await widget.isar.productgroups.put(newGroup);
        nameToGroup[missingGroupNames[i]] = newGroup..id = newGroupId;
      }

      // 6. Artikel aktualisieren mit neuen Gruppen-IDs
      for (var item in currentItems) {
        final originalGroupName =
            _getGroupNameById(item['groupId'], allGroups);
        final newGroup = nameToGroup[originalGroupName];
        if (newGroup != null) {
          item['groupId'] = newGroup.id.toString();
        }
      }

      // 7. Speichern
      list.shopId = newShopId;
      list.setItems(currentItems);
      await widget.isar.itemlists.put(list);
    });

    setState(() {
      _selectedShopId = newShopId;
      _selectedShopName = newShop.name;
    });

    loadItems();
  }

  Future<void> toggleItemDone(String groupName, int itemIndex) async {
    if (itemsByGroup.containsKey(groupName) &&
        itemIndex < itemsByGroup[groupName]!.length) {
      setState(() {
        var itemDetails = itemsByGroup[groupName]![itemIndex];
        itemDetails['isDone'] = !(itemDetails['isDone'] ?? false);
      });

      await widget.isar.writeTxn(() async {
        Itemlist? listToUpdate = await widget.isar.itemlists
            .filter()
            .idEqualTo(int.parse(widget.shoppingListId))
            .findFirst();

        if (listToUpdate != null) {
          List<Map<String, dynamic>> currentItems = listToUpdate.getItems();

          var itemToUpdate = currentItems.firstWhere(
              (item) =>
                  item['name'] == itemsByGroup[groupName]![itemIndex]['name'],
              orElse: () => {});

          if (itemToUpdate.isNotEmpty) {
            itemToUpdate['isDone'] =
                itemsByGroup[groupName]![itemIndex]['isDone'];

            listToUpdate.setItems(currentItems);
            await widget.isar.itemlists.put(listToUpdate);

            debugPrint(
                '==== Current List Contents (after toggleItemDone) ====');
            for (var i = 0; i < currentItems.length; i++) {
              debugPrint(
                  'Item $i: ${currentItems[i]['name']}, isDone: ${currentItems[i]['isDone']}');
            }
            debugPrint('===============================');

            debugPrint("List successfully updated.");
          } else {
            debugPrint('Item not found in the current list.');
          }
        }
      });
    }
  }

  void _addItemToList(String itemName, String groupId) async {
    if (items.isEmpty) {
      debugPrint('Es gibt keine Listen.');
      return;
    }

    final listToAddTo = items.firstWhere(
      (list) => list.id.toString() == widget.shoppingListId,
      orElse: () {
        debugPrint(
            'Keine passende Liste gefunden für shoppingListId: ${widget.shoppingListId}');
        return Itemlist(
          name: 'Unbekannte Liste',
          shopId: 'unknown',
          items: [],
          creationDate: DateTime.now(),
        );
      },
    );

    if (listToAddTo.name == 'Unbekannte Liste') {
      debugPrint(
          'Artikel kann nicht hinzugefügt werden, da keine Liste gefunden wurde.');
      return;
    }

    await widget.isar.writeTxn(() async {
      Itemlist? listToUpdate = await widget.isar.itemlists
          .filter()
          .idEqualTo(int.parse(widget.shoppingListId))
          .findFirst();

      if (listToUpdate != null) {
        List<Map<String, dynamic>> currentItems =
            List.from(listToUpdate.getItems());

        for (var i = 0; i < currentItems.length; i++) {
          debugPrint(
              'Item $i: ${currentItems[i]['name']}, isDone: ${currentItems[i]['isDone']}');
        }

        currentItems
            .add({'name': itemName, 'isDone': false, 'groupId': groupId});

        listToUpdate.setItems(currentItems);
        await widget.isar.itemlists.put(listToUpdate);

        debugPrint('==== List after adding a new item ====');
        for (var i = 0; i < currentItems.length; i++) {
          debugPrint(
              'Item $i: ${currentItems[i]['name']}, isDone: ${currentItems[i]['isDone']}');
        }
        debugPrint('=====================================');

        debugPrint("List successfully updated.");
      }
    });

    setState(() {
      loadItems();
    });
  }

  void _showAddItemDialog() async {
    TextEditingController itemNameController = TextEditingController();
    TextEditingController newGroupNameController = TextEditingController();
    String? selectedGroupId;

    final productGroups = await widget.isar.productgroups
        .filter()
        .storeIdEqualTo(widget.initialStoreId!)
        .sortByOrder()
        .findAll();

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
                          await widget.isar.writeTxn(() async {
                            final lastGroup = await widget.isar.productgroups
                                .filter()
                                .storeIdEqualTo(widget.initialStoreId!)
                                .sortByOrderDesc()
                                .findFirst();

                            final newOrder =
                                lastGroup != null ? lastGroup.order + 1 : 0;

                            Productgroup newGroup = Productgroup(
                              name: newGroupNameController.text,
                              storeId: widget.initialStoreId!,
                              order: newOrder,
                            );
                            await widget.isar.writeTxn(() async {
                              await widget.isar.productgroups.put(newGroup);
                            });

                            _addItemToList(itemNameController.text,
                                newGroup.id.toString());
                          });
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
                        await widget.isar.writeTxn(() async {
                          final lastGroup = await widget.isar.productgroups
                              .filter()
                              .storeIdEqualTo(widget.initialStoreId!)
                              .sortByOrderDesc()
                              .findFirst();

                          final newOrder =
                              lastGroup != null ? lastGroup.order + 1 : 0;

                          Productgroup newGroup = Productgroup(
                            name: newGroupNameController.text,
                            storeId: widget.initialStoreId!,
                            order: newOrder,
                          );
                          await widget.isar.productgroups.put(newGroup);

                          setState(() {
                            groupItems.add(DropdownMenuItem<String>(
                              value: newGroup.id.toString(),
                              child: Text(newGroup.name),
                            ));
                            selectedGroupId = newGroup.id.toString();
                          });
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
            if (_isDeleteMode)
              IconButton(
                  icon: const Icon(Icons.check), onPressed: deleteSelectedItems)
            else
              IconButton(
                  icon: const Icon(Icons.delete), onPressed: toggleDeleteMode),
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
                if (_isDeleteMode)
                  Checkbox(
                    value: selectedGroups.contains(groupId),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value ?? false) {
                          selectedGroups.add(groupId);
                          selectedItems.addAll(itemsByGroup[groupId]!
                              .map((item) => item['name']));
                        } else {
                          selectedGroups.remove(groupId);
                          selectedItems.removeAll(itemsByGroup[groupId]!
                              .map((item) => item['name']));
                        }
                      });
                    },
                  ),
                // WARENGRUPPEN TEXT
                Text(
                  groupId,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: const Color.fromARGB(255, 133, 131, 131),
                  ),
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
                        if (_isDeleteMode)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Checkbox(
                              value: selectedItems.contains(item['name']),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value ?? false) {
                                    selectedItems.add(item['name']);
                                  } else {
                                    selectedItems.remove(item['name']);
                                  }
                                });
                              },
                            ),
                          ),
                        //EINZELNE ARTIKEL
                        Expanded(
                          child: ListTile(
                            title: Text(
                              item['name'],
                              style: TextStyle(
                                fontSize: 23, // Ändere die Schriftgröße hier
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            trailing: !_isDeleteMode
                                ? Checkbox(
                                    value: item['isDone'] ?? false,
                                    onChanged: (bool? value) {
                                      if (value != null) {
                                        toggleItemDone(
                                            groupId,
                                            itemsByGroup[groupId]!
                                                .indexOf(item));
                                      }
                                    },
                                  )
                                : null,
                          ),
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
