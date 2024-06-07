import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homepage.dart';
import 'firebase_auth.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf_wd;

class ItemListScreen extends StatefulWidget {
  final String listName;
  final String shoppingListsId;

  ItemListScreen({required this.listName, required this.shoppingListsId});

  @override
  _ItemListScreenState createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<Map<String, dynamic>>> itemsByGroup = {};
  Set<Map<String, dynamic>> selectedItems =
      Set(); //maybe use later for selecting multiple items and delting them, does not work as of yet

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() async {
    var groupsSnapshot = await _firestore.collection('product_groups').get();
    Map<String, String> groupNames = {};
    for (var doc in groupsSnapshot.docs) {
      groupNames[doc.id] = doc.data()['name'] as String;
    }

    var listDoc = await _firestore
        .collection('shopping_lists')
        .doc(widget.shoppingListsId)
        .get();
    var items = List<Map<String, dynamic>>.from(listDoc.data()?['items'] ?? []);
    Map<String, List<Map<String, dynamic>>> groupedItems = {};

    for (var item in items) {
      String groupId = item['groupId'];
      String groupName = groupNames[groupId] ?? 'idk group';
      groupedItems.putIfAbsent(groupName, () => []).add(item);
    }

    setState(() {
      itemsByGroup = groupedItems;
    });
  }

  void toggleItemDone(String groupName, int index) {
    setState(() {
      itemsByGroup[groupName]![index]['isDone'] =
          !itemsByGroup[groupName]![index]['isDone'];
      _firestore
          .collection('shopping_lists')
          .doc(widget.shoppingListsId)
          .update({'items': itemsByGroup.values.expand((x) => x).toList()});
    });
  }

  void _showAddItemDialog() async {
    TextEditingController itemNameController = TextEditingController();
    String? selectedGroupId;

    var listDoc = await _firestore
        .collection('shopping_lists')
        .doc(widget.shoppingListsId)
        .get();
    var storeId = listDoc.data()?['ladenId'] as String?;

    if (storeId == null) {
      print("No store ID found for list: ${widget.shoppingListsId}");
      return;
    }

    var snapshot = await _firestore
        .collection('product_groups')
        .where('storeId', isEqualTo: storeId)
        .get();

    if (snapshot.docs.isEmpty) {
      print("No product groups found for store ID: $storeId");
      return;
    }

    List<DropdownMenuItem<String>> groupItems = snapshot.docs.map((doc) {
      var name = doc.data()['name'] as String?;
      print("Product Group ID: ${doc.id}, Name: ${doc.data()['name']}");
      return DropdownMenuItem<String>(
        value: doc.id,
        child: Text(name ?? 'idk'),
      );
    }).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Artikel hinzufügen'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: itemNameController,
                  decoration: InputDecoration(labelText: 'Artikelname'),
                ),
                DropdownButton<String>(
                  value: selectedGroupId,
                  onChanged: (newValue) {
                    setState(() {
                      selectedGroupId = newValue;
                    });
                  },
                  items: groupItems,
                  hint: Text('Warengruppe wählen'),
                ),
              ],
            ),
            actions: <Widget>[
              ElevatedButton(
                child: Text('Hinzufügen'),
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

  void _addItemToList(String itemName, String groupId) async {
    await _firestore
        .collection('shopping_lists')
        .doc(widget.shoppingListsId)
        .update({
      'items': FieldValue.arrayUnion([
        {'name': itemName, 'groupId': groupId, 'isDone': false}
      ])
    });
    loadItems();
  }

  //  void deleteItem(String groupName, Map<String, dynamic> item) {
  //   setState(() {
  //     itemsByGroup[groupName]!.remove(item);
  //   });
  //   _firestore
  //     .collection('shopping_lists')
  //     .doc(widget.shoppingListsId)
  //     .update({
  //       'items': FieldValue.arrayRemove([item])
  //     })
  //     .then((value) => print("Item Deleted"))
  // }

  void deleteSelectedItems() async {
    if (selectedItems.isNotEmpty) {
      await _firestore
          .collection('shopping_lists')
          .doc(widget.shoppingListsId)
          .update({'items': FieldValue.arrayRemove(selectedItems.toList())});
      selectedItems.clear();
      loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.listName}'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      HomePage(uid: FirebaseAuth.instance.currentUser!.uid)),
              (Route<dynamic> route) => false,
            );
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.print),
            onPressed: createPdf,
            tooltip: 'Liste drucken',
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: deleteSelectedItems,
            tooltip: 'Ausgewählte Artikel löschen',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: itemsByGroup.keys.length,
        itemBuilder: (context, index) {
          String group = itemsByGroup.keys.elementAt(index);
          return ExpansionTile(
            title: Text(group),
            children: itemsByGroup[group]!.map((item) {
              return CheckboxListTile(
                title: Text(item['name']),
                value: item['isDone'],
                onChanged: (bool? value) {
                  int itemIndex = itemsByGroup[group]!.indexOf(item);
                  toggleItemDone(group, itemIndex);
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        tooltip: 'Artikel hinzufügen',
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> createPdf() async {
    final pdf = pdf_wd.Document();
    pdf.addPage(
      pdf_wd.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pdf_wd.Context context) {
          return pdf_wd.Column(
            crossAxisAlignment: pdf_wd.CrossAxisAlignment
                .start, //linksbündig, ansonsten wird zentriert
            children: [
              pdf_wd.Container(
                child: pdf_wd.Text(widget.listName,
                    style: pdf_wd.TextStyle(
                        fontWeight: pdf_wd.FontWeight.bold, fontSize: 24)),
              ),
              pdf_wd.Divider(),
              ...itemsByGroup.entries.map((entry) {
                return pdf_wd.Column(
                    crossAxisAlignment: pdf_wd.CrossAxisAlignment.start,
                    children: [
                      pdf_wd.Text(entry.key,
                          style: pdf_wd.TextStyle(
                              fontWeight: pdf_wd.FontWeight.bold, fontSize: 16)),
                      pdf_wd.Column(
                        children: entry.value
                            .map((item) => pdf_wd.Text(item['name']))
                            .toList(),
                      ),
                    ]);
              }).toList(),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
        //custom filename needs a lot more adjustments need to look into it //writing directly into directory
    }
}
