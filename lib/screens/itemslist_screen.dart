import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart/objects/productgroup.dart';
import '../objects/itemlist.dart'; // Dein Isar-Modell für Itemlist
import 'package:printing/printing.dart'; // Für PDF-Erstellung und Drucken
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf_wd;
import 'package:share_plus/share_plus.dart'; // Für die Sharing-Funktionalität
import 'package:path_provider/path_provider.dart';

class ItemListScreen extends StatefulWidget {
  final String listName;
  final String shoppingListId;
  final List<Itemlist>? items;
  final String? initialStoreId;
  final Isar isar; // Hinzufügen des Isar-Parameters

  ItemListScreen({
    required this.listName,
    required this.shoppingListId,
    this.items,
    this.initialStoreId,
    required this.isar, // Initialisiere die Isar-Instanz
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

  void loadItems() async {
    final productGroups = await widget.isar.productgroups
        .filter()
        .storeIdEqualTo(widget.initialStoreId!)
        .findAll();

    // Load the saved list from Isar
    Itemlist? savedList = await widget.isar.itemlists
        .filter()
        .idEqualTo(int.parse(widget.shoppingListId))
        .findFirst();

    if (savedList != null) {
      // Get the saved items from the list
      List<Map<String, dynamic>> savedItems = savedList.getItems();
      Map<String, List<Map<String, dynamic>>> groupedItems = {};

      for (var singleItem in savedItems) {
        // Find the group name based on the saved groupId
        final groupName = productGroups
            .firstWhere(
              (group) => group.id.toString() == singleItem['groupId'],
              orElse: () => Productgroup(
                name: 'Unbekannt',
                itemCount: 0,
                storeId: '0',
                order: 0,
              ),
            )
            .name;

        // Preserve `isDone` state when loading from database
        groupedItems.putIfAbsent(groupName, () => []).add(singleItem);
      }

      // Set the state with the loaded items
      setState(() {
        itemsByGroup = groupedItems;
      });

      // Log the loaded items and their states
      print('==== Loaded Items from Database ====');
      for (var group in itemsByGroup.keys) {
        for (var item in itemsByGroup[group]!) {
          print('Item: ${item['name']}, isDone: ${item['isDone']}');
        }
      }
      print('==================================');
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
        // Fetch the list to update
        Itemlist? listToUpdate = await widget.isar.itemlists
            .filter()
            .idEqualTo(int.parse(widget.shoppingListId))
            .findFirst();

        if (listToUpdate != null) {
          // Get the current items
          List<Map<String, dynamic>> currentItems = listToUpdate.getItems();

          // Find the correct item in the full list (currentItems) based on name or another unique property
          var itemToUpdate = currentItems.firstWhere(
              (item) =>
                  item['name'] == itemsByGroup[groupName]![itemIndex]['name'],
              orElse: () => {});

          if (itemToUpdate.isNotEmpty) {
            // Update the `isDone` status of the found item
            itemToUpdate['isDone'] =
                itemsByGroup[groupName]![itemIndex]['isDone'];

            // Save the entire list with updated items
            listToUpdate.setItems(currentItems);
            await widget.isar.itemlists.put(listToUpdate);

            // Log the entire list content after saving
            print('==== Current List Contents (after toggleItemDone) ====');
            for (var i = 0; i < currentItems.length; i++) {
              print(
                  'Item $i: ${currentItems[i]['name']}, isDone: ${currentItems[i]['isDone']}');
            }
            print('===============================');

            print("List successfully updated.");
          } else {
            print('Item not found in the current list.');
          }
        }
      });
    }
  }

  void _addItemToList(String itemName, String groupId) async {
    if (items.isEmpty) {
      print('Es gibt keine Listen.');
      return;
    }

    final listToAddTo = items.firstWhere(
      (list) => list.id.toString() == widget.shoppingListId,
      orElse: () {
        print(
            'Keine passende Liste gefunden für shoppingListId: ${widget.shoppingListId}');
        return Itemlist(
          name: 'Unbekannte Liste',
          groupId: 'unknown',
          items: [],
        );
      },
    );

    if (listToAddTo.name == 'Unbekannte Liste') {
      print(
          'Artikel kann nicht hinzugefügt werden, da keine Liste gefunden wurde.');
      return;
    }

    await widget.isar.writeTxn(() async {
      // Fetch the list to update
      Itemlist? listToUpdate = await widget.isar.itemlists
          .filter()
          .idEqualTo(int.parse(widget.shoppingListId))
          .findFirst();

      if (listToUpdate != null) {
        // Get the current items and retain their `isDone` status
        List<Map<String, dynamic>> currentItems =
            List.from(listToUpdate.getItems());

        // Log current items
        for (var i = 0; i < currentItems.length; i++) {
          print(
              'Item $i: ${currentItems[i]['name']}, isDone: ${currentItems[i]['isDone']}');
        }

        // Add the new item with `isDone: false`
        currentItems
            .add({'name': itemName, 'isDone': false, 'groupId': groupId});

        // Save the updated list with the new item
        listToUpdate.setItems(currentItems);
        await widget.isar.itemlists.put(listToUpdate);

        // Log the entire list content after adding
        print('==== List after adding a new item ====');
        for (var i = 0; i < currentItems.length; i++) {
          print(
              'Item $i: ${currentItems[i]['name']}, isDone: ${currentItems[i]['isDone']}');
        }
        print('=====================================');

        print("List successfully updated.");
      }
    });

    // Reload the items after the update to refresh the UI
    setState(() {
      loadItems();
    });
  }

  void _showAddItemDialog() async {
    TextEditingController itemNameController = TextEditingController();
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
            backgroundColor: Color(0xFF334B46),
            title: Text('Artikel hinzufügen',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: itemNameController,
                  decoration: InputDecoration(
                    labelText: 'Artikelname',
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Color(0xFF4A6963),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF4A6963),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButton<String>(
                    value: selectedGroupId,
                    dropdownColor: Color(0xFF4A6963),
                    onChanged: (newValue) {
                      setState(() {
                        selectedGroupId = newValue;
                      });
                    },
                    items: groupItems,
                    hint: Text('Warengruppe wählen',
                        style: TextStyle(color: Colors.white)),
                    isExpanded: true,
                    underline: SizedBox(),
                    iconEnabledColor: Colors.white,
                    iconSize: 30,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF587A6F)),
                child:
                    Text('Hinzufügen', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  if (itemNameController.text.isNotEmpty &&
                      selectedGroupId != null) {
                    _addItemToList(itemNameController.text, selectedGroupId!);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
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
            pdf_wd.Text(widget.listName, style: pdf_wd.TextStyle(fontSize: 24)),
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
                        style: pdf_wd.TextStyle(fontSize: 14));
                  }).toList(),
                ],
              );
            }).toList(),
          ],
        );
      },
    ));
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
        actions: [
          IconButton(icon: Icon(Icons.print), onPressed: createPdf),
        ],
      ),
      body: ListView.builder(
        itemCount: itemsByGroup.keys.length,
        itemBuilder: (context, index) {
          String groupId = itemsByGroup.keys.elementAt(index);
          return ExpansionTile(
            title: Text(groupId),
            children: itemsByGroup[groupId]!.map((item) {
              return ListTile(
                title: Text(item['name'] ?? 'Unnamed Item'),
                trailing: Checkbox(
                  value: item['isDone'] ?? false,
                  onChanged: (value) {
                    toggleItemDone(
                        groupId, itemsByGroup[groupId]!.indexOf(item));
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}