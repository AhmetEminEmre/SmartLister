import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../objects/productgroup.dart';
import '../objects/shop.dart';

class EditStoreScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final bool isNewStore;
  final Isar isar;

  const EditStoreScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    this.isNewStore = false,
    required this.isar,
  });

  @override
  _EditStoreScreenState createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  List<Productgroup> _productGroups = [];
  bool _isLoading = true;
  bool _isEditMode = false;
  late TextEditingController _storeNameController;
  late String storename;

  @override
  void initState() {
    super.initState();
    _storeNameController = TextEditingController(text: widget.storeName);
    storename = widget.storeName;
    _fetchProductGroups();

    if (widget.isNewStore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptAddDefaultProductGroups();
      });
    }
  }

  Future<void> _fetchProductGroups() async {
    final productGroups = await widget.isar.productgroups
        .filter()
        .storeIdEqualTo(widget.storeId)
        .sortByOrder()
        .findAll();

    setState(() {
      _productGroups = productGroups;
      _isLoading = false;
    });
  }

  Future<void> _addDefaultProductGroups() async {
    final defaultGroups = [
      'Obst & Gemüse',
      'Säfte',
      'Fleisch',
      'Fischprodukte',
    ];

    final existingGroups = await widget.isar.productgroups
        .filter()
        .storeIdEqualTo(widget.storeId)
        .findAll();
    Set<String> existingNames = existingGroups.map((g) => g.name).toSet();

    try {
      await widget.isar.writeTxn(() async {
        for (var groupName in defaultGroups) {
          if (!existingNames.contains(groupName)) {
            final productGroup = Productgroup(
              name: groupName,
              storeId: widget.storeId,
              order: defaultGroups.indexOf(groupName),
            );
            await widget.isar.productgroups.put(productGroup);
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fehlende Standard Warengruppen hinzugefügt.'),
        backgroundColor: Colors.green,
      ));

      _fetchProductGroups();
    } catch (e) {
      print("Error adding product groups: $e");
    }
  }

  void _promptAddDefaultProductGroups() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF334B46),
          title: const Text('Standard Warengruppen hinzufügen?',
              style: TextStyle(color: Colors.white)),
          content: const Text(
              'Möchten Sie die Standard Warengruppen zur neuen Filiale hinzufügen?',
              style: TextStyle(color: Colors.white)),
          actions: <Widget>[
            TextButton(
              child: const Text('Ja', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
                _addDefaultProductGroups();
              },
            ),
            TextButton(
              child: const Text('Nein', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveStoreName() async {
    final newStoreName = _storeNameController.text.trim();

    if (newStoreName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Der Name des Ladens darf nicht leer sein.'),
        backgroundColor: Colors.red,
      ));
      return;
    } else if (newStoreName == storename) {
      setState(() {
        _isEditMode = false;
      });
      return;
    }

    await widget.isar.writeTxn(() async {
      final shop = await widget.isar.einkaufsladens
          .filter()
          .idEqualTo(int.parse(widget.storeId))
          .findFirst();
      if (shop != null) {
        shop.name = newStoreName;
        storename = newStoreName;
        await widget.isar.einkaufsladens.put(shop);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Ladenname erfolgreich geändert.'),
      backgroundColor: Colors.green,
    ));

    setState(() {
      _isEditMode = false;
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _saveStoreName();
      }
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

  void _updateProductGroupOrder() async {
    await widget.isar.writeTxn(() async {
      for (int i = 0; i < _productGroups.length; i++) {
        _productGroups[i].order = i;
        await widget.isar.productgroups.put(_productGroups[i]);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Produktgruppenreihenfolge aktualisiert.'),
      backgroundColor: Colors.green,
    ));
  }

  void _showAddProductGroupDialog() {
    TextEditingController groupNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF334B46),
          title: const Text('Warengruppe hinzufügen',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: groupNameController,
            decoration: InputDecoration(
              hintText: 'Warengruppe Name',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF4A6963),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (groupNameController.text.isNotEmpty) {
                  _addProductGroupIfNotExists(groupNameController.text);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Der Name der Warengruppe darf nicht leer sein.'),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              child: const Text('Hinzufügen',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

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
        );
        await widget.isar.productgroups.put(productGroup);
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Warengruppe hinzugefügt.'),
        backgroundColor: Colors.green,
      ));

      _fetchProductGroups();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Warengruppe existiert bereits.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _deleteProductGroup(Productgroup group) async {
    await widget.isar.writeTxn(() async {
      await widget.isar.productgroups.delete(group.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Warengruppe gelöscht.'),
      backgroundColor: Colors.green,
    ));

    _fetchProductGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isEditMode
            ? TextField(
                controller: _storeNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Ladenname bearbeiten",
                  hintStyle: TextStyle(color: Colors.white54),
                ),
                onSubmitted: (_) => _toggleEditMode(),
              )
            : Text(storename, //hier anpassung
                style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF334B46),
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
          ? const Center(child: CircularProgressIndicator())
          : _productGroups.isEmpty
              ? const Center(
                  child: Text("Keine Produktgruppen verfügbar.",
                      style: TextStyle(color: Colors.white)))
              : ReorderableListView(
                  onReorder: _onReorder,
                  children: _productGroups.map((group) {
                    return Container(
                      key: ValueKey(group.id),
                      decoration: const BoxDecoration(
                        color: Color(0xFF334B46),
                        border: Border(
                          bottom: BorderSide(color: Colors.white24, width: 0.5),
                        ),
                      ),
                      child: ListTile(
                        title: Text(group.name,
                            style: const TextStyle(color: Colors.white)),
                        trailing: _isEditMode
                            ? IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteProductGroup(group),
                              )
                            : ReorderableDragStartListener(
                                index: _productGroups.indexOf(group),
                                child: const Icon(Icons.reorder,
                                    color: Color(0xFF96b17c)),
                              ),
                      ),
                    );
                  }).toList(),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF96b17c),
        onPressed: _showAddProductGroupDialog,
        tooltip: 'Warengruppe hinzufügen',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
