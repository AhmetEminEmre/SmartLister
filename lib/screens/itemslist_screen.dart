import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart/objects/productgroup.dart';
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

  @override
  void initState() {
    super.initState();
    items = widget.items ?? [];
    loadItems();
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
    final productGroups = await widget.isar.productgroups
        .filter()
        .storeIdEqualTo(widget.initialStoreId!)
        .sortByOrder()
        .findAll();

    Itemlist? savedList = await widget.isar.itemlists
        .filter()
        .idEqualTo(int.parse(widget.shoppingListId))
        .findFirst();

    if (savedList != null) {
      List<Map<String, dynamic>> savedItems = savedList.getItems();
      Map<String, List<Map<String, dynamic>>> groupedItems = {};

      for (var singleItem in savedItems) {
        final groupName = productGroups
            .firstWhere(
              (group) => group.id.toString() == singleItem['groupId'],
              orElse: () => Productgroup(
                name: 'Unbekannt',
                storeId: '0',
                order: 0,
              ),
            )
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

      debugPrint('==== Loaded Items from Database with Correct Order ====');
      for (var group in itemsByGroup.keys) {
        for (var item in itemsByGroup[group]!) {
          print('Item: ${item['name']}, isDone: ${item['isDone']}');
        }
      }
      debugPrint('==================================');
    }
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

            debugPrint('==== Current List Contents (after toggleItemDone) ====');
            for (var i = 0; i < currentItems.length; i++) {
              debugPrint('Item $i: ${currentItems[i]['name']}, isDone: ${currentItems[i]['isDone']}');
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
        debugPrint('Keine passende Liste gefunden für shoppingListId: ${widget.shoppingListId}');
        return Itemlist(
          name: 'Unbekannte Liste',
          shopId: 'unknown',
          items: [],
          creationDate: DateTime.now(),
        );
      },
    );

    if (listToAddTo.name == 'Unbekannte Liste') {
      debugPrint('Artikel kann nicht hinzugefügt werden, da keine Liste gefunden wurde.');
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
          debugPrint('Item $i: ${currentItems[i]['name']}, isDone: ${currentItems[i]['isDone']}');
        }

        currentItems
            .add({'name': itemName, 'isDone': false, 'groupId': groupId});

        listToUpdate.setItems(currentItems);
        await widget.isar.itemlists.put(listToUpdate);

        debugPrint('==== List after adding a new item ====');
        for (var i = 0; i < currentItems.length; i++) {
          debugPrint('Item $i: ${currentItems[i]['name']}, isDone: ${currentItems[i]['isDone']}');
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
    TextEditingController newGroupNameController =
        TextEditingController();
    String? selectedGroupId;

    final productGroups = await widget.isar.productgroups
        .filter()
        .storeIdEqualTo(widget.initialStoreId!)
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
            backgroundColor: const Color(0xFF334B46),
            title: const Text('Artikel hinzufügen',
                style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: itemNameController,
                    decoration: InputDecoration(
                      labelText: 'Artikelname',
                      labelStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: const Color(0xFF4A6963),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Warengruppe auswählen
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A6963),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButton<String>(
                      value: selectedGroupId,
                      dropdownColor: const Color(0xFF4A6963),
                      onChanged: (newValue) {
                        setState(() {
                          selectedGroupId = newValue;
                        });
                      },
                      items: groupItems,
                      hint: const Text('Warengruppe wählen',
                          style: TextStyle(color: Colors.white)),
                      isExpanded: true,
                      underline: const SizedBox(),
                      iconEnabledColor: Colors.white,
                      iconSize: 30,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF587A6F)),
                    child: const Text('Artikel hinzufügen',
                        style: TextStyle(color: Colors.white)),
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
                            await widget.isar.productgroups.put(newGroup);

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
                      labelStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: const Color(0xFF4A6963),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF587A6F)),
                    child: const Text('Warengruppe hinzufügen',
                        style: TextStyle(color: Colors.white)),
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

    String pdfFileName = widget.listName.replaceAll(' ', '_') + '.pdf';
    await Printing.sharePdf(bytes: await pdf.save(), filename: pdfFileName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: createPdf,
          ),
          if (_isDeleteMode)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: deleteSelectedItems,
            )
          else
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: toggleDeleteMode,
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: itemsByGroup.keys.length,
        itemBuilder: (context, index) {
          String groupId = itemsByGroup.keys.elementAt(index);
          return ExpansionTile(
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
                Text(groupId),
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
                        Expanded(
                          child: ListTile(
                            title: Text(item['name']),
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
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: !_isDeleteMode
          ? FloatingActionButton(
              onPressed: _showAddItemDialog,
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}
