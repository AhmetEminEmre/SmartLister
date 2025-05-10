import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart/objects/itemlist.dart';
import '../objects/productgroup.dart';
import '../objects/shop.dart';
import 'package:smart/services/productgroup_service.dart';
import 'package:smart/services/shop_service.dart';
import 'package:smart/services/itemlist_service.dart';

class EditStoreScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final bool isNewStore;
  final ProductGroupService productGroupService;
  final ShopService shopService;
  final ItemListService itemListService;

  const EditStoreScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    this.isNewStore = false,
    required this.productGroupService,
    required this.shopService,
    required this.itemListService,
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
    final productGroups =
        await widget.productGroupService.fetchProductGroups(widget.storeId);
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
      'Getreide, Reis & Nudeln',
      'Käse & Feinkost',
      'Milchprodukte'
    ];

    final existingGroups =
        await widget.productGroupService.fetchProductGroups(widget.storeId);
    Set<String> existingNames = existingGroups.map((g) => g.name).toSet();

    for (var groupName in defaultGroups) {
      if (!existingNames.contains(groupName)) {
        final productGroup = Productgroup(
          name: groupName,
          storeId: widget.storeId,
          order: defaultGroups.indexOf(groupName),
        );
        await widget.productGroupService.addProductGroup(productGroup);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Fehlende Standard Warengruppen hinzugefügt.'),
      backgroundColor: Colors.green,
    ));

    _fetchProductGroups();
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
                backgroundColor: const Color.fromARGB(
                    255, 239, 141, 37), // Orangener Hintergrund
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Abgerundete Ecken
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              child: const Text(
                'Hinzufügen',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600), // Weiße Schrift
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
                style: TextStyle(
                    color: Color(0xFF4A4A4A),
                    fontSize: 18), // Dunkelgraue Schrift
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

  final shop = await widget.shopService.fetchShopById(int.parse(widget.storeId));
  if (shop != null) {
    shop.name = newStoreName;
    storename = newStoreName;
    await widget.shopService.addShop(shop);
  }

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
  for (int i = 0; i < _productGroups.length; i++) {
    _productGroups[i].order = i;
  }
  await widget.productGroupService.updateProductGroupOrder(_productGroups);

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
      return Center( // <-- manuell zentrieren
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 360, 
            height: 230,// ✅ hier kannst du wirklich die Breite bestimmen
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Neue Warengruppe hinzufügen',
                    style: TextStyle(
                      color: Color.fromARGB(255, 92, 91, 91),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                    ),
                    style: const TextStyle(
                      color: Color.fromARGB(255, 26, 26, 26),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 239, 141, 37),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 16,
                          ),
                        ),
                        child: const Text(
                          'Hinzufügen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          if (groupNameController.text.trim().isNotEmpty) {
                            _addProductGroupIfNotExists(groupNameController.text.trim());
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Der Name der Warengruppe darf nicht leer sein!',
                                  textAlign: TextAlign.center,
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        child: const Text(
                          'Abbrechen',
                          style: TextStyle(
                            color: Color(0xFF4A4A4A),
                            fontSize: 18,
                          ),
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
          ),
        ),
      );
    },
  );
}



Future<void> _addProductGroupIfNotExists(String name) async {
  final existingGroup = await widget.productGroupService.fetchByNameAndShop(name, widget.storeId);

  if (existingGroup == null) {
    final newOrder = _productGroups.length;
    final productGroup = Productgroup(
      name: name,
      storeId: widget.storeId,
      order: newOrder,
    );
    await widget.productGroupService.addProductGroup(productGroup);

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
  await widget.productGroupService.deleteProductGroup(group.id);

  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text('Warengruppe gelöscht.'),
    backgroundColor: Colors.green,
  ));

  _fetchProductGroups();
}
Future<void> _deleteStore() async {
  final storeId = widget.storeId;

  final assignedLists =
      await widget.itemListService.fetchItemListsByShopId(storeId);

  if (assignedLists.isNotEmpty) {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Laden und zugehörige Listen löschen?'),
        content: const Text(
          'Dieser Laden ist noch mit \${assignedLists.length} Einkaufsliste(n) verknüpft. '
          'Möchtest du den Laden und alle zugehörigen Listen wirklich löschen?',
        ),
        actions: [
          TextButton(
            child: const Text('Nein'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Ja, alles löschen'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;

    for (final list in assignedLists) {
      await widget.itemListService.deleteItemList(list.id);
    }
    await widget.shopService.deleteShop(int.parse(storeId));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Laden und zugehörige Listen gelöscht')),
    );
    Navigator.of(context).pop();
    return;
  }

  final confirmDelete = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Laden löschen?'),
      content: const Text('Möchtest du diesen Laden wirklich löschen?'),
      actions: [
        TextButton(
          child: const Text('Nein'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(
          child: const Text('Ja'),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );

  if (confirmDelete == true) {
    await widget.shopService.deleteShop(int.parse(storeId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Laden erfolgreich gelöscht')),
    );
    Navigator.of(context).pop();
  }
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
                    color: Color.fromARGB(255, 26, 25, 25), fontSize: 26)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_motion,
                color: Color.fromARGB(255, 30, 30, 30)),
            onPressed: _promptAddDefaultProductGroups,
          ),
          IconButton(
  icon: Icon(
    _isEditMode ? Icons.check : Icons.edit,
    color: const Color.fromARGB(255, 31, 31, 31),
  ),
  onPressed: _toggleEditMode,
),

        ],
      ),
    backgroundColor: Colors.white,
body: _isLoading
    ? const Center(child: CircularProgressIndicator())
    : Column(
        children: [
          Expanded(
            child: _productGroups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.category_outlined,
                            size: 72, color: Color(0xFFBDBDBD)),
                        SizedBox(height: 16),
                        Text(
                          "Noch keine Warengruppen",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF444444),
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            "Tippe auf das Plus-Symbol, um deine \nerste Warengruppe zu erstellen.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView(
                    onReorder: _onReorder,
                    children: _productGroups.map((group) {
                      // …

                          return Container(
  key: ValueKey(group.id),
  decoration: const BoxDecoration(
    color: Color.fromARGB(255, 255, 255, 255),
    border: Border(
      bottom: BorderSide(
        color: Color.fromRGBO(126, 126, 126, 0.284),
        width: 1,
      ),
    ),
  ),
  child: ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 4),
    title: Text(
      group.name,
      style: const TextStyle(
        color: Color.fromARGB(255, 31, 31, 31),
        fontSize: 20,
      ),
    ),
   trailing: SizedBox(
  width: 30, // etwas mehr Platz nach rechts
  height: 40,
  child: Center(
    child: _isEditMode
        ? IconButton(
            icon: const Icon(Icons.delete,
                color: Color.fromARGB(255, 239, 141, 37)),
            onPressed: () => _deleteProductGroup(group),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )
        : ReorderableDragStartListener(
            index: _productGroups.indexOf(group),
            child: const Icon(Icons.reorder,
                color: Color.fromARGB(255, 239, 141, 37)),
          ),
  ),
),

  ),
);


                          }).toList(),
                        ),
                ),
                // PLUS- UND LÖSCHEN-BUTTON FEST UNTEN RECHTS
                // PLUS- UND LÖSCHEN-BUTTON FEST UNTEN RECHTS
              Padding(
  padding: const EdgeInsets.only(right: 20.0, bottom: 20.0),
  child: _isEditMode
      ? Center( // 🟥 NUR der Delete-Button soll zentriert sein
          child: ElevatedButton.icon(
            onPressed: _deleteStore,
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text(
              "Laden löschen",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        )
      : Align( // 🟧 Plus-Button bleibt rechts
          alignment: Alignment.bottomRight,
  child: SizedBox(
  width: 74,
  height: 74,
  child: FloatingActionButton(
    onPressed: _showAddProductGroupDialog,
    backgroundColor: const Color.fromARGB(255, 239, 141, 37),
    foregroundColor: Colors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(32),
    ),
   child: const Icon(Icons.add, size: 50),

    tooltip: 'Warengruppe hinzufügen',
  ),
),


      ),
),

              ],
            ),
    );
  }
}
