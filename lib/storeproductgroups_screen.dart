import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart/addstoreonly_screen.dart';
import 'homepage.dart';

class EditStoreScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final bool isNewStore;

  EditStoreScreen(
      {required this.storeId,
      required this.storeName,
      this.isNewStore = false});

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
      var querySnapshot = await _firestore.collection('product_groups')
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

  void _deleteProductGroup(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Warengruppe löschen'),
          content: Text('Sind Sie sicher, dass Sie diese Warengruppe löschen möchten?'),
          actions: <Widget>[
            TextButton(
              child: Text('Abbrechen'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Löschen'),
              onPressed: () {
                _firestore.collection('product_groups').doc(docId).delete().then((_) {
                  Navigator.of(context).pop();
                  _loadProductGroups();
                  _reorderProductGroupsAfterDeletion(docId);
                }).catchError((error) {
                  print("Fehler beim Löschen der Warengruppe: $error");
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _reorderProductGroupsAfterDeletion(String deletedDocId) {
    int orderIndex = 0;
    List<DocumentSnapshot> updatedProductGroups = [];
    for (var doc in _productGroups) {
      if (doc.id != deletedDocId) {
        updatedProductGroups.add(doc);
      }
    }
    _productGroups = updatedProductGroups;
    for (var doc in _productGroups) {
      doc.reference.update({'order': orderIndex++}).catchError((error) {
        print("Fehler beim Aktualisieren der Order nach Löschung: $error");
      });
    }
    _loadProductGroups();
  }

  Widget _buildReorderableTile(DocumentSnapshot doc) {
    return ListTile(
      key: ValueKey(doc.id),
      title: Text(doc['name']),
      trailing: _isEditMode ? IconButton(
        icon: Icon(Icons.delete, color: Colors.red),
        onPressed: () => _deleteProductGroup(doc.id),
      ) : ReorderableDragStartListener(
        index: _productGroups.indexOf(doc),
        child: Icon(Icons.reorder, color: Theme.of(context).colorScheme.secondary),
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
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: _isLoading
          ? CircularProgressIndicator()
          : _productGroups.isEmpty
              ? Text("Keine Produktgruppen verfügbar.")
              : ReorderableListView(
                  onReorder: _onReorder,
                  children: _productGroups.map((doc) => _buildReorderableTile(doc)).toList(),
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
                  _addProductGroup(groupNameController.text);
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

  void _addProductGroup(String name) async {
    try {
      var maxOrderQuery = await _firestore.collection('product_groups')
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
    } catch (e) {
      print("Fehler beim Hinzufügen einer Produktgruppe: $e");
    }
  }

  void _addDefaultProductGroups() {
    for (int i = 0; i < defaultProductGroups.length; i++) {
      var group = defaultProductGroups[i];
      DocumentReference ref = _firestore.collection('product_groups').doc();
      ref.set({
        'id': ref.id,
        'name': group['name'],
        'storeId': widget.storeId,
        'order': i
      });
      _loadProductGroups();
    }
  }

  void _promptAddDefaultProductGroups() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Standardwarengruppen"),
        content: Text("Wollen Sie Standardwarengruppen zu diesem Laden hinzufügen?"),
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
