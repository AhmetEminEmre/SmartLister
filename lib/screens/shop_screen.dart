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
      'Backwaren',
      'Tiefkühlprodukte',
      'Süßwaren & Snacks',
      'Konserven & Fertiggerichte',
      'Getreide, Reis & Nudeln'
      'Käse & Feinkost',
      'Milchprodukte'
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
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Standard-Warengruppen hinzufügen?',
              style: TextStyle(
                  color: Color.fromARGB(255, 75, 75, 75),
                  fontSize: 23,
                  fontWeight: FontWeight.w600)),
          content: const Text(
              'Möchten Sie die Standard-Warengruppen dieser Filiale hinzufügen?',
              style: TextStyle(
                  color: Color.fromARGB(255, 6, 6, 6),
                  fontSize: 17,
                  fontWeight: FontWeight.w500)),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor:
                    const  Color.fromARGB(255, 239, 141, 37), // Orangener Hintergrund
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Abgerundete Ecken
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    
              ),
              child: const Text(
                'Hinzufügen',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600), // Weiße Schrift
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _addDefaultProductGroups();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFD3D3D3), // Grauer Hintergrund
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Abgerundete Ecken
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              child: const Text(
                'Überspringen',
                style:
                    TextStyle(color: Color(0xFF4A4A4A), fontSize: 18), // Dunkelgraue Schrift
              ),
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
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 10.0, // 90% der Bildschirmbreite
        height: MediaQuery.of(context).size.height * 0.24, // 60% der Bildschirmhöhe
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // Abgerundete Ecken
        ),
      child: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text(
      'Neue Warengruppe hinzufügen',
      style: TextStyle(
        color: Color.fromARGB(255, 92, 91, 91),
        fontSize: 23,
        fontWeight: FontWeight.w600,
      ),
    ),
    const SizedBox(height: 35), // Abstand zwischen Text und Textfeld
    TextField(
      controller: groupNameController,
      decoration: InputDecoration(
        labelText: 'Name der Warengruppe',
        labelStyle: const TextStyle(
          color: Color.fromARGB(255, 54, 54, 54),
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFBDBDBD),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFBDBDBD),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFE5A462),
            width: 2,
          ),
        ),
      ),
      style: const TextStyle(
        color: Color.fromARGB(255, 26, 26, 26),
      ),
    ),
    const SizedBox(height: 30), // Abstand zwischen Textfeld und Buttons
    Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 239, 141, 37), // Orangener Hintergrund
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Abgerundete Ecken
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 12,
            ),
          ),
          child: const Text(
            'Hinzufügen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ), // Weiße Schrift
          ),
          onPressed: () {
            if (groupNameController.text.isNotEmpty) {
              _addProductGroupIfNotExists(groupNameController.text);
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Der Name der Warengruppe darf nicht leer sein.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        const SizedBox(width: 8), // Abstand zwischen den Buttons
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFD3D3D3), // Grauer Hintergrund
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Abgerundete Ecken
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 12,
            ),
          ),
          child: const Text(
            'Überspringen',
            style: TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 18,
            ), // Dunkelgraue Schrift
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  ],
),

      ),
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
                style: const TextStyle(color: Color.fromARGB(255, 35, 34, 34)),
                decoration: const InputDecoration(
                  hintText: "Ladenname bearbeiten",
                  hintStyle: TextStyle(color: Color.fromARGB(136, 160, 61, 61)),
                ),
                onSubmitted: (_) => _toggleEditMode(),
              )
            : Text(storename,
                style: const TextStyle(
                    color: Color.fromARGB(255, 26, 25, 25), fontSize: 23)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_motion,
                color: Color.fromARGB(255, 30, 30, 30)),
            onPressed: _promptAddDefaultProductGroups,
          ),
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit,
                color: const Color.fromARGB(255, 31, 31, 31)),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      backgroundColor: Colors.white,
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
                        //hintergrund von warengruppen
                        color: Color.fromARGB(255, 255, 255, 255),
                        border: Border(
                          //linien zw warengruppen
                          bottom: BorderSide(
                              color: Color.fromRGBO(126, 126, 126, 0.284),
                              width: 1),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 35.0,
                            vertical: 4), // Abstand links und rechts
                        title: Text(
                          group.name,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 31, 31, 31),
                            fontSize: 20,
                          ),
                        ),
                        trailing: _isEditMode
                            ? IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Color.fromARGB(255, 239, 141, 37)),
                                onPressed: () => _deleteProductGroup(group),
                              )
                            : ReorderableDragStartListener(
                                index: _productGroups.indexOf(group),
                                child: const Icon(Icons.reorder,
                                    color: Color.fromARGB(255, 239, 141, 37)),
                              ),
                      ),
                    );
                  }).toList(),
                ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
            right: 16.0, bottom: 16.0), // Abstand rechts und unten
        child: SizedBox(
          height: 80, // Höhe des Buttons
          width: 80, // Breite des Buttons
          child: FloatingActionButton(
            onPressed: _showAddProductGroupDialog,
            backgroundColor:
                Color.fromARGB(255, 239, 141, 37), // Hintergrundfarbe
            foregroundColor: Colors.white, // Icon-Farbe
            child: const Icon(Icons.add, size: 36), // Größeres Icon
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40), // Eckenradius
            ),
            tooltip: 'Warengruppe hinzufügen',
          ),
        ),
      ),
    );
  }
}
