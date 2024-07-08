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
  final String shoppingListId;
  final List<TemplateList>? items;
  final String? initialStoreId;

  ItemListScreen(
      {required this.listName,
      required this.shoppingListId,
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
    loadItems();
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
      var listDoc = await _firestore.collection('shopping_lists').doc(widget.shoppingListId).get();
      currentStoreId = listDoc.data()?['ladenId'] as String?;

      if (currentStoreId == null) {
        print("No store ID found for list: ${widget.shoppingListId}");
        return;
      }

      var items = List<Map<String, dynamic>>.from(listDoc.data()?['items'] ?? []);
      var groupsSnapshot = await _firestore
          .collection('product_groups')
          .where('storeId', isEqualTo: currentStoreId)
          .orderBy('order')
          .get();

      Map<String, String> groupNames = {};
      Map<String, int> groupOrder = {};
      for (var doc in groupsSnapshot.docs) {
        groupNames[doc.id] = doc.data()['name'] as String;
        groupOrder[doc.id] = doc.data()['order'] as int;
      }

      List<Map<String, dynamic>> validItems = [];
      for (var item in items) {
        if (groupNames.containsKey(item['groupId'])) {
          validItems.add(item);
        }
      }

      validItems.sort((a, b) {
        int orderA = groupOrder[a['groupId']] ?? 1000;
        int orderB = groupOrder[b['groupId']] ?? 1000;
        return orderA.compareTo(orderB);
      });

      await _firestore.collection('shopping_lists').doc(widget.shoppingListId).update({'items': validItems});

      Map<String, List<Map<String, dynamic>>> groupedItems = {};
      for (var item in validItems) {
        String groupName = groupNames[item['groupId']] ?? 'idk';
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
          .doc(widget.shoppingListId)
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
          backgroundColor: Color(0xFF96b17c),
          title: Text('Bestätigen', style: TextStyle(color: Colors.white)),
          content: Text(
            'Möchten Sie die ausgewählten Artikel und Gruppen wirklich löschen?',
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Abbrechen', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Löschen', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await _firestore.runTransaction((transaction) async {
                  final listRef = _firestore
                      .collection('shopping_lists')
                      .doc(widget.shoppingListId);
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
      },
    );
  }
}


  void _showAddItemDialog() async {
    TextEditingController itemNameController = TextEditingController();
    String? selectedGroupId;

    var listDoc = await _firestore
        .collection('shopping_lists')
        .doc(widget.shoppingListId)
        .get();
    var storeId = listDoc.data()?['ladenId'] as String?;

    if (storeId == null) {
      print("No store ID found for list: ${widget.shoppingListId}");
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
                    iconEnabledColor:
                        Colors.white,
                    iconSize: 30,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF587A6F),
                ),
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

  void _addItemToList(String itemName, String groupId) async {
    await _firestore
        .collection('shopping_lists')
        .doc(widget.shoppingListId)
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
      final shareableLink = await createLink(widget.shoppingListId);
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
        title: Text(
          '${widget.listName}',
          style: TextStyle(
              color: Colors.white,
              fontSize: 20),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          if (!_isDeleteMode)
            IconButton(
              icon: Icon(Icons.share, color: Colors.white),
              onPressed: shareList,
              tooltip: 'Liste sharen',
            ),
          IconButton(
            icon: Icon(Icons.print, color: Colors.white),
            onPressed: createPdf,
            tooltip: 'Liste drucken',
          ),
          IconButton(
            icon: Icon(_isDeleteMode ? Icons.check : Icons.delete,
                color: Colors.white),
            onPressed: toggleDeleteMode,
            tooltip: _isDeleteMode ? 'Fertig' : 'Löschen',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFb0c69f), Color(0xFF96b17c)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      backgroundColor: Color(0xFF334B46),
      body: ListView.builder(
        itemCount: itemsByGroup.keys.length,
        itemBuilder: (context, index) {
          String group = itemsByGroup.keys.elementAt(index);
          return Theme(
            data: Theme.of(context).copyWith(
              unselectedWidgetColor:
                  Colors.white,
              iconTheme:
                  IconThemeData(color: Colors.white),
            ),
            child: ExpansionTile(
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
                      checkColor: Colors.white,
                      activeColor:
                          Color(0xFF96b17c),
                    ),
                  Text(group.toUpperCase(),
                      style: TextStyle(color: Colors.white)),
                ],
              ),
              iconColor: Colors.white,
              collapsedIconColor:
                  Colors.white,
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
                        checkColor: Colors.white,
                        activeColor: Color(
                            0xFF96b17c),
                      ),
                    Expanded(
                      child: CheckboxListTile(
                        title: Text(item['name'],
                            style: TextStyle(color: Colors.white)),
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
                        checkColor: Colors.white,
                        activeColor: Color(
                            0xFF96b17c),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isDeleteMode ? deleteSelectedItems : _showAddItemDialog,
        child:
            Icon(_isDeleteMode ? Icons.delete : Icons.add, color: Colors.white),
        backgroundColor: _isDeleteMode
            ? Colors.red
            : Color(0xFF96b17c),
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
