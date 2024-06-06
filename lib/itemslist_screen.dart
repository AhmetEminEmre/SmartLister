import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    var listDoc = await _firestore.collection('shopping_lists').doc(widget.shoppingListsId).get();
    var storeId = listDoc.data()?['ladenId'] as String?;

    if (storeId == null) {
        print("No store ID found for list: ${widget.shoppingListsId}");
        return;
    }

    var snapshot = await _firestore.collection('product_groups')
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.listName}'),
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
}
