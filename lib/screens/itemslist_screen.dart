import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf_wd;
import 'package:share_plus/share_plus.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import '../objects/template.dart';

class ItemListScreen extends StatefulWidget {
  final String listName;
  final String shoppingListsId;
  final List<TemplateList>? items;
  final String? initialStoreId;

  ItemListScreen(
      {required this.listName,
      required this.shoppingListsId,
      this.items,
      this.initialStoreId});

  @override
  _ItemListScreenState createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<Map<String, dynamic>>> itemsByGroup = {};
  bool _isDeleteMode = false;
  Set<String> selectedItems = Set();
  Set<String> selectedGroups = Set();
  List<TemplateList> items = [];
  String? currentStoreId;

  @override
  void initState() {
    super.initState();
    if (widget.items != null && widget.items!.isNotEmpty) {
      loadItems();
      setTemplateItems(widget.items!);
    } else {
      loadItems();
    }
  }

  void setTemplateItems(List<TemplateList> items) {
    var groupedItems = Map<String, List<Map<String, dynamic>>>();
    for (var item in items) {
      print("Setting group name: ${item.groupName} for item: ${item.name}");
      groupedItems.putIfAbsent(item.groupName, () => []).add({
        'name': item.name,
        'isDone': item.isDone,
        'groupId': item.groupId,
      });
    }
    setState(() {
      itemsByGroup = groupedItems;
    });
  }

  void loadItems() async {
    try {
      var listDoc = await _firestore
          .collection('shopping_lists')
          .doc(widget.shoppingListsId)
          .get();
      currentStoreId = listDoc.data()?['ladenId'] as String?;

      if (currentStoreId == null) {
        print("No store ID found for list: ${widget.shoppingListsId}");
        return;
      }

      var items =
          List<Map<String, dynamic>>.from(listDoc.data()?['items'] ?? []);
      var groupsSnapshot = await _firestore
          .collection('product_groups')
          .where('storeId', isEqualTo: currentStoreId)
          .get();

      Map<String, String> groupNames = {};
      for (var doc in groupsSnapshot.docs) {
        groupNames[doc.id] = doc.data()['name'] as String;
      }

      List<Map<String, dynamic>> validItems = [];
      for (var item in items) {
        if (groupNames.containsKey(item['groupId'])) {
          validItems.add(item);
        }
      }

      await _firestore
          .collection('shopping_lists')
          .doc(widget.shoppingListsId)
          .update({'items': validItems});

      Map<String, List<Map<String, dynamic>>> groupedItems = {};
      for (var item in validItems) {
        String groupName = groupNames[item['groupId']] ?? 'Unbekannte Gruppe';
        groupedItems.putIfAbsent(groupName, () => []).add(item);
      }

      setState(() {
        itemsByGroup = groupedItems;
      });
    } catch (e) {
      print('Error loading items: $e');
    }
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

  void toggleDeleteMode() {
    setState(() {
      _isDeleteMode = !_isDeleteMode;
      if (!_isDeleteMode) {
        selectedItems.clear();
        selectedGroups.clear();
      }
    });
  }

  void deleteSelectedItems() {
    if (selectedItems.isNotEmpty || selectedGroups.isNotEmpty) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Bestätigen'),
              content: Text(
                  'Möchten Sie die ausgewählten Artikel und Gruppen wirklich löschen?'),
              actions: <Widget>[
                TextButton(
                  child: Text('Abbrechen'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Löschen'),
                  onPressed: () async {
                    await _firestore.runTransaction((transaction) async {
                      final listRef = _firestore
                          .collection('shopping_lists')
                          .doc(widget.shoppingListsId);
                      var snapshot = await transaction.get(listRef);
                      var items = List<Map<String, dynamic>>.from(
                          snapshot.data()?['items'] ?? []);

                      items.removeWhere(
                          (item) => selectedItems.contains(item['name']));

                      selectedGroups.forEach((groupId) {
                        items.removeWhere((item) => item['groupId'] == groupId);
                      });

                      transaction.update(listRef, {'items': items});
                    });
                    Navigator.of(context).pop();
                    toggleDeleteMode();
                    loadItems();
                  },
                ),
              ],
            );
          });
    }
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
        .orderBy('order')
        .get();

    if (snapshot.docs.isEmpty) {
      print("No product groups found for store ID: $storeId");
      return;
    }
    List<DropdownMenuItem<String>> groupItems = snapshot.docs.map((doc) {
      var name = doc.data()['name'] as String?;
      return DropdownMenuItem<String>(
        value: doc.id,
        child: Text(name ?? 'Unbekannt'),
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

  Future<String> createLink(String refCode) async {
    final String url = "https://smartlister01.page.link/?id=$refCode";

    final DynamicLinkParameters parameters = DynamicLinkParameters(
      androidParameters: const AndroidParameters(
        packageName: "com.example.smart",
        minimumVersion: 0,
      ),
      iosParameters: const IOSParameters(
        bundleId: "com.example.smart",
        minimumVersion: "0",
      ),
      link: Uri.parse(url),
      uriPrefix: "https://smartlister01.page.link",
    );

    final FirebaseDynamicLinks dynamicLinks = FirebaseDynamicLinks.instance;
    final ShortDynamicLink shortLink =
        await dynamicLinks.buildShortLink(parameters);
    return shortLink.shortUrl.toString();
  }

  void shareList() async {
    try {
      final shareableLink = await createLink(widget.shoppingListsId);
      print('Generated short link: $shareableLink');
      await Share.share(shareableLink);
    } catch (e) {
      print('Error generating dynamic link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.listName}'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          if (!_isDeleteMode)
            IconButton(
              icon: Icon(Icons.share),
              onPressed: shareList,
              tooltip: 'Liste sharen',
            ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: createPdf,
            tooltip: 'Liste drucken',
          ),
          IconButton(
            icon: Icon(_isDeleteMode ? Icons.check : Icons.delete),
            onPressed: toggleDeleteMode,
            tooltip: _isDeleteMode ? 'Fertig' : 'Löschen',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: itemsByGroup.keys.length,
        itemBuilder: (context, index) {
          String group = itemsByGroup.keys.elementAt(index);
          return ExpansionTile(
            title: Row(
              children: [
                if (_isDeleteMode)
                  Checkbox(
                    value: selectedGroups.contains(group),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value ?? false) {
                          selectedGroups.add(group);
                          selectedItems.addAll(itemsByGroup[group]!
                              .map((item) => item['name'] as String));
                        } else {
                          selectedGroups.remove(group);
                          selectedItems.removeAll(itemsByGroup[group]!
                              .map((item) => item['name'] as String));
                        }
                      });
                    },
                  ),
                Text(group),
              ],
            ),
            children: itemsByGroup[group]!.map((item) {
              return Row(
                children: [
                  if (_isDeleteMode)
                    Checkbox(
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
                  Expanded(
                    child: CheckboxListTile(
                      title: Text(item['name']),
                      value: item['isDone'],
                      onChanged: !_isDeleteMode
                          ? (bool? value) {
                              if (value != null) {
                                int itemIndex =
                                    itemsByGroup[group]!.indexOf(item);
                                toggleItemDone(group, itemIndex);
                              }
                            }
                          : null,
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isDeleteMode ? deleteSelectedItems : _showAddItemDialog,
        child: Icon(_isDeleteMode ? Icons.delete : Icons.add),
        backgroundColor: _isDeleteMode ? Colors.red : null,
        tooltip: _isDeleteMode ? 'Ausgewählte löschen' : 'Artikel hinzufügen',
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
            crossAxisAlignment: pdf_wd.CrossAxisAlignment.start,
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
                    ...entry.value
                        .map((item) => pdf_wd.Text(
                              item['name'],
                              style: pdf_wd.TextStyle(fontSize: 14),
                            ))
                        .toList(),
                  ],
                );
              }).toList(),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
