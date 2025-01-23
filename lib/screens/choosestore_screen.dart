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

  const StoreScreen({
    super.key,
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
        title: const Text(
          "Einkaufsladen zuordnen",
          style: TextStyle(
            color: Colors.black, // Textfarbe des Titels
          ),
        ),
        backgroundColor: Colors.white, // AppBar-Hintergrundfarbe
        iconTheme: const IconThemeData(
          color: Colors.black, // Icon-Farbe
        ),
        elevation: 0, // Entfernt den Schatten der AppBar
      ),
      backgroundColor: Colors.white, // Hintergrundfarbe des gesamten Screens
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(
                  left: 12.0, bottom: 8.0), // Abstand links und unten
              child: Text(
                'Wähle den Laden aus, in dem du einkaufen möchtest.',
                style: TextStyle(
                  fontSize: 16, // Schriftgröße
                  fontWeight: FontWeight.w500, // Schriftstärke
                  color: Color(0xFF212121), // Textfarbe
                ),
              ),
            ),

            // Dropdown zum Auswählen eines Stores
            DropdownButtonFormField<String>(
              value: _selectedStoreId,
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
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Nein'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
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
                    child: Text(
                      store.name,
                      style: const TextStyle(
                        color: Color(0xFF212121), // Textfarbe im Dropdown
                      ),
                    ),
                  ),
                );
              }).toList(),
              decoration: InputDecoration(
                label: RichText(
                  text: TextSpan(
                    text: 'Bitte auswählen...',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 46, 46, 46), // Label-Farbe
                      fontSize: 16,
                    ),
                    children: const [
                      TextSpan(
                        text: ' *', // Rotes Sternchen
                        style: TextStyle(
                          color: Colors.red, // Sternchen-Farbe
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                filled: true,
                fillColor: Colors.white, // Weißer Hintergrund
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFBDBDBD), // Grauer Rand
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(
                        0xFFBDBDBD), // Grauer Rand für nicht fokussierten Zustand
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(
                        0xFFE5A462), // Orange Rand für fokussierten Zustand
                    width: 2,
                  ),
                ),
              ),
              dropdownColor: Colors.white, // Dropdown-Hintergrund
            ),

            // Fertigstellen-Button
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: 
              
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
                child: const Text(
                  'Fertigstellen',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // Textfarbe Weiß
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return const Color(
                            0xFFFFD9B3); // Helles Orange für disabled Zustand
                      }
                      return const Color(
                          0xFFE5A462); // Starkes Orange für enabled Zustand
                    },
                  ),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 16),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  minimumSize: MaterialStateProperty.all(
                    const Size.fromHeight(56),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
