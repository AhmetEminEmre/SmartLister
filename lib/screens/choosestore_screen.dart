import 'package:flutter/material.dart';
import '../objects/itemlist.dart';
import '../objects/shop.dart';
import '../screens/itemslist_screen.dart';
import '../services/itemlist_service.dart';
import '../services/shop_service.dart';
import '../services/productgroup_service.dart';
import 'package:provider/provider.dart';
import 'package:smart/font_scaling.dart';

class StoreScreen extends StatefulWidget {
  final String listId;
  final String listName;
  final ItemListService itemListService;
  final ShopService shopService;
  final Function(String storeId) onStoreSelected;
  final ProductGroupService productGroupService;

  const StoreScreen({
    super.key,
    required this.listId,
    required this.listName,
    required this.itemListService,
    required this.shopService,
    required this.onStoreSelected,
    required this.productGroupService,
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

  Future<void> _loadStores() async {
    final stores = await widget.shopService.fetchShops();
    setState(() {
      _stores = stores;
    });
  }

  Future<bool> _isStoreAssignedToList(String storeId) async {
    final lists = await widget.itemListService.fetchItemListsByShopId(storeId);
    return lists.isNotEmpty;
  }

  Future<List<Itemlist>> _fetchItemsForList(String listId) async {
    final item =
        await widget.itemListService.fetchItemListById(int.parse(listId));
    return item != null ? [item] : [];
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

    await widget.shopService.deleteShop(int.parse(storeId));
    await _loadStores();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
     final scaling = context.watch<FontScaling>().factor;
    return Scaffold(
      appBar: AppBar(
        title:  Text(
          "Einkaufsladen zuordnen",
            style: TextStyle(
          color: Colors.black,
          fontSize: 22 * scaling, // 👈 SCALING HINZUFÜGEN!
        ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12.0, bottom: 18.0),
              child: Text(
                'Wähle den Laden aus, in dem du einkaufen möchtest.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF212121),
                ),
              ),
            ),
    Padding(
            padding: const EdgeInsets.only(left: 8), // Verschiebt Dropdown leicht nach links 
              child: SizedBox(
                width: 280,
                child: DropdownButtonFormField<String>(
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
                          style:
                               TextStyle(color: Color(0xFF212121),  fontSize: 16 * scaling,),
                        ),
                      ),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    label: RichText(
                      text:  TextSpan(
                        text: 'Bitte auswählen...',
                        style: TextStyle(
                          color: Color.fromARGB(255, 46, 46, 46),
                          fontSize: 16 * scaling,
                        ),
                        children: [
                          TextSpan(
                            text: ' *',
                            style:
                                TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFBDBDBD), width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5A462), width: 2),
                    ),
                  ),
                  dropdownColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
  onPressed: _selectedStoreId != null
      ? () async {
          // ✅ 1. Speichere Shop-Id sicher in Liste
          await widget.onStoreSelected(_selectedStoreId!);

          // ✅ 2. Navigiere erst NACH erfolgreichem Speichern
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ItemListScreen(
                listName: widget.listName,
                shoppingListId: widget.listId,
                // 🚫 KEIN `items` mehr übergeben — immer selbst laden!
                initialStoreId: _selectedStoreId!,
                itemListService: widget.itemListService,
                productGroupService: widget.productGroupService,
                shopService: widget.shopService,
              ),
            ),
          );
      }
      : null,
                style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.disabled)) {
                        return const Color(0xFFFFD9B3);
                      }
                      return const Color(0xFFE5A462);
                    },
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 16),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  minimumSize:
                      WidgetStateProperty.all(const Size.fromHeight(56)),
                ),
                child: const Text(
                  'Fertigstellen',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
//   