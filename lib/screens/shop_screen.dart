import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditStoreScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final bool isNewStore;

  EditStoreScreen({
    required this.storeId,
    required this.storeName,
    this.isNewStore = false,
  });

  @override
  _EditStoreScreenState createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, String>> defaultProductGroups = [
    {'name': 'Obst & Gemüse'},
    {'name': 'Säfte'},
    {'name': 'Fleisch'},
    {'name': 'Fischprodukte'}
  ];

  List<DocumentSnapshot> _productGroups = [];
  bool _isLoading = true;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.isNewStore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptAddDefaultProductGroups();
      });
    }
    _loadProductGroups();
  }

  void _loadProductGroups() async {
    setState(() {
      _isLoading = true;
    });
    try {
      var querySnapshot = await _firestore
          .collection('product_groups')
          .where('storeId', isEqualTo: widget.storeId)
          .orderBy('order', descending: false)
          .get();
      setState(() {
        _productGroups = querySnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print("Fehler beim Laden der Produktgruppen: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _productGroups.removeAt(oldIndex);
      _productGroups.insert(newIndex, item);
    });
    _updateProductGroupOrder();
  }

  void _updateProductGroupOrder() {
    for (int i = 0; i < _productGroups.length; i++) {
      _productGroups[i].reference.update({'order': i});
    }
  }

  void _deleteProductGroup(String docId) async {

    var shoppingLists = await _firestore.collection('shopping_lists').get();
    var count = 0;

    for (var doc in shoppingLists.docs) {
      var items = List.from(doc.data()['items']);
      if (items.any((item) => item['groupId'] == docId)) {
        count++;
      }
    }

    print("count, listen die diese gruppe usen: $count");

    if (count > 0) {
      _showDeleteWarning(count, docId);
    } else {
      _deleteGroupAndItems(docId);
      _loadProductGroups();
    }
  }

  void _showDeleteWarning(int count, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Warengruppe löschen'),
          content: Text(
              'Diese Gruppe wird $count mal verwendet. Wollen Sie sie trotzdem löschen?'),
          actions: <Widget>[
            TextButton(
              child: Text('Nein'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Ja'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteGroupAndItems(docId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteGroupAndItems(String docId) async {
    await _firestore.collection('product_groups').doc(docId).delete();

    var listsToUpdate = await _firestore.collection('shopping_lists').get();
    List<Future<void>> updateTasks = [];

    for (var doc in listsToUpdate.docs) {
      var items = List<Map<String, dynamic>>.from(doc.data()['items'] ?? []);
      int originalLength = items.length;
      items.removeWhere((item) => item['groupId'] == docId);
      int newLength = items.length;

      if (originalLength != newLength) {
        updateTasks
            .add(doc.reference.update({'items': items}).catchError((error) {
          print("error after updating: $error");
        }));
      }
    }

    try {
      await Future.wait(updateTasks);
    } catch (e) {
      print("error bei update: $e");
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Warengruppe gelöscht.'),
      backgroundColor: Colors.green,
    ));

    _loadProductGroups();
    _reorderProductGroupsAfterDeletion();
  }

  void _reorderProductGroupsAfterDeletion() async {
    int newOrder = 0;
    List<Future<void>> updateTasks = [];

    for (var doc in _productGroups) {
      updateTasks
          .add(doc.reference.update({'order': newOrder++}).catchError((error) {
        print("error after adding: $error");
      }));
    }

    try {
      await Future.wait(updateTasks);
    } catch (e) {
      print("reorder error: $e");
    }

    _loadProductGroups();
  }

  Widget _buildReorderableTile(DocumentSnapshot doc) {
    return ListTile(
      key: ValueKey(doc.id),
      title: Text(doc['name']),
      trailing: _isEditMode
          ? IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteProductGroup(doc.id),
            )
          : ReorderableDragStartListener(
              index: _productGroups.indexOf(doc),
              child: Icon(Icons.reorder,
                  color: Theme.of(context).colorScheme.secondary),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName),
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome_motion),
            onPressed: _promptAddDefaultProductGroups,
          ),
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _productGroups.isEmpty
              ? Center(child: Text("Keine Produktgruppen verfügbar."))
              : ReorderableListView(
                  onReorder: _onReorder,
                  children: _productGroups
                      .map((doc) => _buildReorderableTile(doc))
                      .toList(),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductGroupDialog,
        child: Icon(Icons.add),
        tooltip: 'Warengruppe hinzufügen',
      ),
    );
  }

  void _showAddProductGroupDialog() {
    TextEditingController groupNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Warengruppe hinzufügen'),
          content: TextField(
            controller: groupNameController,
            decoration: InputDecoration(hintText: 'Warengruppe Name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (groupNameController.text.isNotEmpty) {
                  _addProductGroupIfNotExists(groupNameController.text);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Hinzufügen'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addProductGroupIfNotExists(String name) async {
    try {
      var existingGroups = await _firestore
          .collection('product_groups')
          .where('storeId', isEqualTo: widget.storeId)
          .where('name', isEqualTo: name)
          .get();

      if (existingGroups.docs.isEmpty) {
        var maxOrderQuery = await _firestore
            .collection('product_groups')
            .where('storeId', isEqualTo: widget.storeId)
            .orderBy('order', descending: true)
            .limit(1)
            .get();

        int maxOrder = 0;
        if (maxOrderQuery.docs.isNotEmpty) {
          maxOrder = maxOrderQuery.docs.first.data()['order'] + 1;
        }

        DocumentReference ref = _firestore.collection('product_groups').doc();
        await ref.set({
          'id': ref.id,
          'name': name,
          'storeId': widget.storeId,
          'order': maxOrder
        });
        _loadProductGroups();
      } else {
        print("Warengruppe bereits vorhanden.");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Warengruppe "$name" ist bereits vorhanden.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print("Fehler beim Hinzufügen einer Produktgruppe: $e");
    }
  }

  void _addDefaultProductGroups() async {
    for (var group in defaultProductGroups) {
      await _addProductGroupIfNotExists(group['name']!);
    }
  }

  void _promptAddDefaultProductGroups() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Standardwarengruppen"),
          content: Text(
              "Wollen Sie Standardwarengruppen zu diesem Laden hinzufügen?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addDefaultProductGroups();
              },
              child: Text('Ja'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Nein'),
            ),
          ],
        );
      },
    );
  }
}
