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
  final List<Itemlist> items;
  final String? initialStoreId;
  final Isar isar; // Hinzufügen des Isar-Parameters

  ItemListScreen({
    required this.listName,
    required this.shoppingListId,
    required this.items,
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
  late List<Itemlist> items;
  String? currentStoreId;

  @override
  void initState() {
    super.initState();
    items = widget.items;
    _groupItemsByCategory(items);
  }

  void _groupItemsByCategory(List<Itemlist> items) async {
    Map<String, List<Map<String, dynamic>>> groupedItems = {};

    // Produktgruppen für den Store abrufen
    final productGroups = await widget.isar.productgroups
        .filter()
        .storeIdEqualTo(widget.initialStoreId!)
        .findAll();

    // Map von groupId -> groupName erstellen
    Map<String, String> groupIdToName = {
      for (var group in productGroups) group.id.toString(): group.name
    };

    // Abgerufene Produktgruppen zum Debuggen ausgeben
    print("Fetched product groups:");
    for (var group in productGroups) {
      print("Group ID: ${group.id}, Group Name: ${group.name}");
    }

    for (var item in items) {
      List<Map<String, dynamic>> itemList = item.getItems(); // Hole Items aus der Itemliste

      for (var singleItem in itemList) {
        String groupName = groupIdToName[item.groupId ?? ""] ?? "Unbekannt";
        groupedItems.putIfAbsent(groupName, () => []).add(singleItem);
      }
    }

    setState(() {
      itemsByGroup = groupedItems;
    });
  }

  Future<void> toggleItemDone(String groupId, int itemIndex) async {
    setState(() {
      var itemDetails = itemsByGroup[groupId]![itemIndex];
      itemDetails['isDone'] = !(itemDetails['isDone'] ?? false);
    });

    await widget.isar.writeTxn(() async {
      var listToUpdate = widget.items.firstWhere((list) => list.groupId == groupId);
      listToUpdate.setItems(itemsByGroup[groupId]!);
      await widget.isar.itemlists.put(listToUpdate);
    });
  }

  Future<void> deleteSelectedItems() async {
    setState(() {
      selectedItems.forEach((itemId) {
        items.removeWhere((item) => item.id.toString() == itemId);
      });
      selectedGroups.forEach((groupId) {
        itemsByGroup.remove(groupId);
      });
      _groupItemsByCategory(items);
      selectedItems.clear();
      selectedGroups.clear();
    });

    await widget.isar.writeTxn(() async {
      for (var itemId in selectedItems) {
        await widget.isar.itemlists.delete(int.parse(itemId));
      }
    });
  }

  void _addItemToList(String itemName, String groupId) async {
    final listToAddTo = items.firstWhere((list) => list.id.toString() == widget.shoppingListId);
    var currentItems = listToAddTo.getItems();
    currentItems.add({'name': itemName, 'isDone': false, 'groupId': groupId});
    listToAddTo.setItems(currentItems);

    await widget.isar.writeTxn(() async {
      await widget.isar.itemlists.put(listToAddTo);
    });

    setState(() {
      _groupItemsByCategory(items);
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
            title: Text('Artikel hinzufügen', style: TextStyle(color: Colors.white)),
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
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                    hint: Text('Warengruppe wählen', style: TextStyle(color: Colors.white)),
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
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF587A6F)),
                child: Text('Hinzufügen', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  if (itemNameController.text.isNotEmpty && selectedGroupId != null) {
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
                  pdf_wd.Text(entry.key, style: pdf_wd.TextStyle(fontSize: 18, fontWeight: pdf_wd.FontWeight.bold)),
                  ...entry.value.map((item) {
                    return pdf_wd.Text(item['name'] ?? 'Unnamed Item', style: pdf_wd.TextStyle(fontSize: 14));
                  }).toList(),
                ],
              );
            }).toList(),
          ],
        );
      },
    ));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
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
                    toggleItemDone(groupId, itemsByGroup[groupId]!.indexOf(item));
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
