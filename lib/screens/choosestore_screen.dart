import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../objects/itemlist.dart';
import '../objects/shop.dart';
import 'itemslist_screen.dart';

class StoreScreen extends StatefulWidget {
  final String listId;
  final String listName;
  final Isar isar;
  final Function(String storeId) onStoreSelected;

  const StoreScreen({super.key, 
    required this.listId,
    required this.listName,
    required this.isar,
    required this.onStoreSelected,
  });

  @override
  _StoreScreenState createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String? _selectedStoreId;
  List<Einkaufsladen> _stores = [];

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  void _loadStores() async {
    final stores = await widget.isar.einkaufsladens.where().findAll();
    setState(() {
      _stores = stores;
    });
  }

  Future<bool> _isStoreAssignedToList(String storeId) async {
    final listsWithStore =
        await widget.isar.itemlists.filter().shopIdEqualTo(storeId).findAll();
    return listsWithStore.isNotEmpty;
  }

  Future<List<Itemlist>> _fetchItemsForList(String listId) async {
    return await widget.isar.itemlists
        .filter()
        .idEqualTo(int.parse(listId))
        .findAll();
  }

  Future<void> _deleteStore(String storeId) async {
    final isAssigned = await _isStoreAssignedToList(storeId);
    if (isAssigned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Dieser Laden ist einer Liste zugeordnet und kann nicht gelöscht werden.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await widget.isar.writeTxn(() async {
      await widget.isar.einkaufsladens.delete(int.parse(storeId));
    });

    _loadStores();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Einkaufsladen zuordnen"),
      ),
      body: Column(
        children: [
          // Dropdown zum Auswählen eines Stores
          DropdownButton<String>(
            value: _selectedStoreId,
            hint: const Text("Einkaufsladen wählen"),
            onChanged: (value) {
              setState(() {
                _selectedStoreId = value;
              });
            },
            items: _stores.map((store) {
              return DropdownMenuItem<String>(
                value: store.id.toString(),
                child: GestureDetector(
                  onLongPress: () async {
                    final shouldDelete = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Laden löschen?'),
                          content: const Text(
                              'Möchten Sie diesen Laden wirklich löschen?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Nein'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Ja'),
                            ),
                          ],
                        );
                      },
                    );

                    if (shouldDelete == true) {
                      await _deleteStore(store.id.toString());
                    }
                  },
                  child: Text(store.name),
                ),
              );
            }).toList(),
          ),
          ElevatedButton(
            onPressed: _selectedStoreId != null
                ? () async {
                    final items = await _fetchItemsForList(widget.listId);
                    widget.onStoreSelected(_selectedStoreId!);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemListScreen(
                          listName: widget.listName,
                          shoppingListId: widget.listId,
                          items: items,
                          initialStoreId: _selectedStoreId!,
                          isar: widget.isar,
                        ),
                      ),
                    );
                  }
                : null,
            child: const Text('Weiter zur Einkaufsliste'),
          ),
        ],
      ),
    );
  }
}
