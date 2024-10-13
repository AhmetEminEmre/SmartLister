import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../objects/productgroup.dart'; // Your Isar model for ProductGroup

class EditStoreScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final bool isNewStore; // This flag determines if the store is new
  final Isar isar;

  EditStoreScreen({
    required this.storeId,
    required this.storeName,
    required this.isNewStore, // Accept isNewStore as a parameter
    required this.isar,
  });

  @override
  _EditStoreScreenState createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  List<Productgroup> _productGroups = [];
  bool _isLoading = true;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();

    // Fetch the product groups when the screen is initialized
    _fetchProductGroups();

    // Check if this is a new store, then show the prompt after the UI is built
    if (widget.isNewStore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptAddDefaultProductGroups();
      });
    }
  }

  // Fetch product groups from the Isar database
  Future<void> _fetchProductGroups() async {
    final productGroups = await widget.isar.productgroups
        .filter()
        .storeIdEqualTo(widget.storeId)
        .findAll();

    setState(() {
      _productGroups = productGroups;
      _isLoading = false;
    });
  }

  // Add default product groups
  Future<void> _addDefaultProductGroups() async {
    final defaultGroups = [
      'Obst & Gemüse',
      'Säfte',
      'Fleisch',
      'Fischprodukte',
    ];

    try {
      await widget.isar.writeTxn(() async {
        for (var group in defaultGroups) {
          final productGroup = Productgroup(
            name: group,
            storeId: widget.storeId,
            order: defaultGroups.indexOf(group),
            itemCount: 0,
          );
          await widget.isar.productgroups.put(productGroup);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Standard Warengruppen hinzugefügt.'),
        backgroundColor: Colors.green,
      ));

      // Refresh the product groups
      _fetchProductGroups();
    } catch (e) {
      print("Error adding product groups: $e");
    }
  }

  // Prompt to ask if the user wants to add default product groups
  void _promptAddDefaultProductGroups() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF334B46),
          title: Text('Standard Warengruppen hinzufügen?',
              style: TextStyle(color: Colors.white)),
          content: Text(
              'Möchten Sie die Standard Warengruppen zur neuen Filiale hinzufügen?',
              style: TextStyle(color: Colors.white)),
          actions: <Widget>[
            TextButton(
              child: Text('Ja', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _addDefaultProductGroups(); // Only add groups if user agrees
              },
            ),
            TextButton(
              child: Text('Nein', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without action
              },
            ),
          ],
        );
      },
    );
  }

  // Toggle edit mode for reorderable list
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  // Handle reorder logic
  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final item = _productGroups.removeAt(oldIndex);
      _productGroups.insert(newIndex, item);
    });

    _updateProductGroupOrder();
  }

  // Update the order of product groups in the database
  void _updateProductGroupOrder() async {
    await widget.isar.writeTxn(() async {
      for (int i = 0; i < _productGroups.length; i++) {
        _productGroups[i].order = i;
        await widget.isar.productgroups.put(_productGroups[i]);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Produktgruppenreihenfolge aktualisiert.'),
      backgroundColor: Colors.green,
    ));
  }

  // Show add product group dialog
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
                    content: Text('Der Name der Warengruppe darf nicht leer sein.'),
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

  // Add new product group if it doesn't already exist
  Future<void> _addProductGroupIfNotExists(String name) async {
    final existingGroup = await widget.isar.productgroups
        .filter()
        .nameEqualTo(name)
        .storeIdEqualTo(widget.storeId)
        .findFirst();

    if (existingGroup == null) {
      await widget.isar.writeTxn(() async {
        final newOrder = _productGroups.length;
        final productGroup = Productgroup(
          name: name,
          storeId: widget.storeId,
          order: newOrder,
          itemCount: 0,
        );
        await widget.isar.productgroups.put(productGroup);
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Warengruppe hinzugefügt.'),
        backgroundColor: Colors.green,
      ));

      // Refresh the product groups
      _fetchProductGroups();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Warengruppe existiert bereits.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Delete a product group
  void _deleteProductGroup(Productgroup group) async {
    await widget.isar.writeTxn(() async {
      await widget.isar.productgroups.delete(group.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Warengruppe gelöscht.'),
      backgroundColor: Colors.green,
    ));

    // Refresh the product groups
    _fetchProductGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName, style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF334B46),
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
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _productGroups.isEmpty
              ? Center(child: Text("Keine Produktgruppen verfügbar.",
                  style: TextStyle(color: Colors.white)))
              : ReorderableListView(
                  onReorder: _onReorder,
                  children: _productGroups.map((group) {
                    return Container(
                      key: ValueKey(group.id),
                      decoration: BoxDecoration(
                        color: Color(0xFF334B46),
                        border: Border(
                          bottom: BorderSide(color: Colors.white24, width: 0.5),
                        ),
                      ),
                      child: ListTile(
                        title: Text(group.name, style: TextStyle(color: Colors.white)),
                        trailing: _isEditMode
                            ? IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteProductGroup(group),
                              )
                            : ReorderableDragStartListener(
                                index: _productGroups.indexOf(group),
                                child: Icon(Icons.reorder, color: Color(0xFF96b17c)),
                              ),
                      ),
                    );
                  }).toList(),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF96b17c),
        onPressed: _showAddProductGroupDialog,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Warengruppe hinzufügen',
      ),
    );
  }
}
