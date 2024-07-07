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
          backgroundColor: Color(0xFF334B46),
          title: Text('Warengruppe löschen',
              style: TextStyle(color: Colors.white)),
          content: Text(
              'Diese Gruppe wird $count mal verwendet. Wollen Sie sie trotzdem löschen?',
              style: TextStyle(color: Colors.white)),
          actions: <Widget>[
            TextButton(
              child: Text('Ja', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteGroupAndItems(docId);
              },
            ),
            TextButton(
              child: Text('Nein', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(),
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
    return Container(
      key: ValueKey(doc.id),
      decoration: BoxDecoration(
        color: Color(0xFF334B46),
        border: Border(
          bottom: BorderSide(color: Colors.white24, width: 0.5),
        ),
      ),
      child: ListTile(
        title: Text(doc['name'], style: TextStyle(color: Colors.white)),
        trailing: _isEditMode
            ? IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteProductGroup(doc.id),
              )
            : ReorderableDragStartListener(
                index: _productGroups.indexOf(doc),
                child: Icon(Icons.reorder, color: Color(0xFF96b17c)),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName, style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF587A6F),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome_motion, color: Colors.white),
            onPressed: _promptAddDefaultProductGroups,
          ),
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit,
                color: Colors.white),
            onPressed: _toggleEditMode,
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _productGroups.isEmpty
              ? Center(
                  child: Text("Keine Produktgruppen verfügbar.",
                      style: TextStyle(color: Colors.white)))
              : ReorderableListView(
                  onReorder: _onReorder,
                  children: _productGroups
                      .map((doc) => _buildReorderableTile(doc))
                      .toList(),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF96b17c),
        onPressed: _showAddProductGroupDialog,
        child: Icon(Icons.add, color: Colors.white),
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
          backgroundColor: Color(0xFF334B46),
          title: Text('Warengruppe hinzufügen',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: groupNameController,
            decoration: InputDecoration(
              hintText: 'Warengruppe Name',
              hintStyle: TextStyle(color: Colors.white54),
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
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (groupNameController.text.isNotEmpty) {
                  _addProductGroupIfNotExists(groupNameController.text);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('Der Name der Warengruppe darf nicht leer sein.'),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              child: Text('Hinzufügen', style: TextStyle(color: Colors.white)),
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
        var newOrder = _productGroups.length;
        await _firestore.collection('product_groups').add({
          'name': name,
          'storeId': widget.storeId,
          'order': newOrder,
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Warengruppe hinzugefügt.'),
          backgroundColor: Colors.green,
        ));
        _loadProductGroups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Warengruppe existiert bereits.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print("Fehler beim Hinzufügen der Produktgruppe: $e");
    }
  }

  void _promptAddDefaultProductGroups() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF334B46),
          title: Text('Standard Warengruppen hinzufügen?',
              style: TextStyle(color: Colors.white)),
          content: Text(
              'Möchten Sie die Standard Warengruppen zur neuen Filiale hinzufügen?',
              style: TextStyle(color: Colors.white)),
          actions: <Widget>[
            TextButton(
              child: Text('Nein', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Ja', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
                _addDefaultProductGroups();
              },
            ),
          ],
        );
      },
    );
  }

  void _addDefaultProductGroups() async {
    try {
      var existingGroups = await _firestore
          .collection('product_groups')
          .where('storeId', isEqualTo: widget.storeId)
          .get();
      var existingNames = existingGroups.docs.map((doc) => doc['name']).toSet();

      List<Future<void>> tasks = [];

      for (var group in defaultProductGroups) {
        if (!existingNames.contains(group['name'])) {
          var newOrder = existingGroups.size + tasks.length;
          tasks.add(_firestore.collection('product_groups').add({
            'name': group['name'],
            'storeId': widget.storeId,
            'order': newOrder,
          }));
        }
      }

      await Future.wait(tasks);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Standard Warengruppen hinzugefügt.'),
        backgroundColor: Colors.green,
      ));

      _loadProductGroups();
    } catch (e) {
      print("Fehler beim Hinzufügen der Standard Warengruppen: $e");
    }
  }
}
