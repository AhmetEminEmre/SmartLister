import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart/objects/productgroup.dart';
import 'package:smart/objects/shop.dart';
import '../objects/itemlist.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf_wd;

import '../services/itemlist_service.dart';
import '../services/productgroup_service.dart';
import '../services/shop_service.dart';


class ItemListScreen extends StatefulWidget {
  final String listName;
  final String shoppingListId;
  final List<Itemlist>? items;
  final String? initialStoreId;
  final ItemListService itemListService;
  final ProductGroupService productGroupService;
  final ShopService shopService;

  const ItemListScreen({
    super.key,
    required this.listName,
    required this.shoppingListId,
    this.items,
    this.initialStoreId,
    required this.itemListService,
    required this.productGroupService,
    required this.shopService,
  });

  @override
  _ItemListScreenState createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  Map<String, List<Map<String, dynamic>>> itemsByGroup = {};
  bool _isDeleteMode = false;
  Set<String> selectedItems = {};
  Set<String> selectedGroups = {};
  List<Itemlist> items = [];
  String? currentStoreId;
  List<Einkaufsladen> _availableShops = []; // Liste aller Shops
  String? _selectedShopId; // Die aktuell gewählte Shop-ID
  String _selectedShopName =
      "Kein Shop gefunden"; // Fallback falls kein Shop existiert

  @override
  void initState() {
    super.initState();
    items = widget.items ?? [];
    loadShops();
  }

  void toggleDeleteMode() {
    setState(() {
      if (_isDeleteMode) {
        selectedItems.clear();
        selectedGroups.clear();
      }
      _isDeleteMode = !_isDeleteMode;
    });
  }

  void deleteProductGroup(String groupName) async {
    final list = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));
    if (list == null) return;

    final currentItems = list.getItems();
    final remainingItems = currentItems.where((item) {
      final group = itemsByGroup[groupName];
      return group == null ||
          !group.any((element) => element['name'] == item['name']);
    }).toList();

    list.setItems(remainingItems);
    await widget.itemListService.updateItemList(list);

    setState(() {
      itemsByGroup.remove(groupName);
    });
  }

  void deleteItem(String groupName, String itemName) async {
    final list = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));
    if (list == null) return;

    final currentItems = list.getItems();
    final updatedItems =
        currentItems.where((item) => item['name'] != itemName).toList();

    list.setItems(updatedItems);
    await widget.itemListService.updateItemList(list);

    setState(() {
      itemsByGroup[groupName]?.removeWhere((item) => item['name'] == itemName);
      if (itemsByGroup[groupName]?.isEmpty ?? false) {
        itemsByGroup.remove(groupName);
      }
    });
  }

  Future<void> loadItems() async {
    if (_selectedShopId == null) return;

    final productGroups =
        await widget.productGroupService.fetchProductGroups(_selectedShopId!);

    final savedList = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));

    if (savedList != null) {
      final savedItems = savedList.getItems();

      Map<String, List<Map<String, dynamic>>> groupedItems = {};
      for (var singleItem in savedItems) {
        final groupName = productGroups
            .firstWhere((g) => g.id.toString() == singleItem['groupId'],
                orElse: () =>
                    Productgroup(name: 'Unbekannt', storeId: '0', order: 0))
            .name;
        groupedItems.putIfAbsent(groupName, () => []).add(singleItem);
      }

      Map<String, List<Map<String, dynamic>>> orderedGroupedItems = {};
      for (var group in productGroups) {
        if (groupedItems.containsKey(group.name)) {
          orderedGroupedItems[group.name] = groupedItems[group.name]!;
        }
      }

      setState(() {
        itemsByGroup = orderedGroupedItems;
      });
    }
  }

  String _getGroupNameById(String groupId, List<Productgroup> productGroups) {
    return productGroups
        .firstWhere(
          (group) => group.id.toString() == groupId,
          orElse: () => Productgroup(name: 'Unbekannt', storeId: 'x', order: 0),
        )
        .name;
  }

  void loadShops() async {
    final shops = await widget.shopService.fetchShops();

    final list = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));

    setState(() {
      _availableShops = shops;
      if (list != null) {
        _selectedShopId = list.shopId;
        _selectedShopName = shops
            .firstWhere(
              (shop) => shop.id.toString() == list.shopId,
              orElse: () =>
                  Einkaufsladen(name: "Kein Shop gefunden", imagePath: null),
            )
            .name;
      }
    });

    await loadItems();
  }

  void _updateShop(String newShopId) async {
    final newShop =
        _availableShops.firstWhere((shop) => shop.id.toString() == newShopId);

    final list = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));
    if (list == null) return;

    final currentItems = list.getItems();

    final allGroups = await widget.productGroupService
        .fetchProductGroups(widget.initialStoreId!);
    final newShopGroups =
        await widget.productGroupService.fetchProductGroups(newShopId);

    final Map<String, Productgroup> nameToGroup = {
      for (var group in newShopGroups) group.name: group
    };

    final existingGroupNames = nameToGroup.keys.toSet();
    final usedGroupNames = currentItems
        .map((item) => _getGroupNameById(item['groupId'], allGroups))
        .toSet();

    final missingGroupNames =
        usedGroupNames.difference(existingGroupNames).toList()..sort();

    int maxOrder = newShopGroups.isEmpty
        ? 0
        : newShopGroups.map((g) => g.order).reduce((a, b) => a > b ? a : b);

    for (var i = 0; i < missingGroupNames.length; i++) {
      final newGroup = Productgroup(
        name: missingGroupNames[i],
        storeId: newShopId,
        order: maxOrder + i + 1,
      );

      final newGroupId =
          await widget.productGroupService.addProductGroup(newGroup);
      nameToGroup[missingGroupNames[i]] = newGroup..id = newGroupId;
    }

    for (var item in currentItems) {
      final originalGroupName = _getGroupNameById(item['groupId'], allGroups);
      final newGroup = nameToGroup[originalGroupName];
      if (newGroup != null) {
        item['groupId'] = newGroup.id.toString();
      }
    }

    list.shopId = newShopId;
    list.setItems(currentItems);

    // ✅ ersetzt durch Service
    await widget.itemListService.updateItemList(list);

    setState(() {
      _selectedShopId = newShopId;
      _selectedShopName = newShop.name;
    });

    loadItems();
  }

  Future<void> toggleItemDone(String groupName, int itemIndex) async {
    final itemDetails = itemsByGroup[groupName]![itemIndex];
    setState(() {
      itemDetails['isDone'] = !(itemDetails['isDone'] ?? false);
    });

    final list = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));
    if (list != null) {
      final currentItems = list.getItems();
      final itemToUpdate = currentItems.firstWhere(
        (item) => item['name'] == itemDetails['name'],
        orElse: () => {},
      );

      if (itemToUpdate.isNotEmpty) {
        itemToUpdate['isDone'] = itemDetails['isDone'];
        list.setItems(currentItems);

        await widget.itemListService.updateItemList(list);
      }
    }
  }

  void _addItemToList(String itemName, String groupId) async {
    final list = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));
    if (list == null) return;

    final currentItems = List<Map<String, dynamic>>.from(list.getItems());
    currentItems.add({'name': itemName, 'isDone': false, 'groupId': groupId});
    list.setItems(currentItems);

    await widget.itemListService.updateItemList(list);

    await loadItems();
  }

  void _showAddItemDialog() async {
    TextEditingController itemNameController = TextEditingController();
    TextEditingController newGroupNameController = TextEditingController();
    String? selectedGroupId;

    final productGroups = await widget.productGroupService
        .fetchProductGroups(widget.initialStoreId!);

    List<DropdownMenuItem<String>> groupItems = productGroups.map((group) {
      return DropdownMenuItem<String>(
        value: group.id.toString(),
        child: Text(group.name),
      );
    }).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
   return AlertDialog(
  backgroundColor: Colors.white,
  title: const Text(
    'Artikel hinzufügen',
    style: TextStyle(color: Color(0xFF161616), fontSize: 20, fontWeight: FontWeight.w500),
  ),
  content: SizedBox(
    width: 400,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: itemNameController,
          decoration: InputDecoration(
            labelText: 'Artikelname',
            labelStyle: TextStyle(
              color: Colors.black.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            floatingLabelStyle: const TextStyle(
              color: Color(0xFF7D9205),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF7D9205), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
          ),
          style: const TextStyle(color: Colors.black87),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: selectedGroupId,
          onChanged: (newValue) {
            setState(() {
              selectedGroupId = newValue;
            });
          },
          items: groupItems,
          isExpanded: true,
          icon: const SizedBox.shrink(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF7D9205), width: 2),
            ),
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Color(0xFF212121), fontSize: 16),
          hint: const Text(
            'Warengruppe wählen',
            style: TextStyle(color: Color(0xFF363636), fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFE2E2E2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Abbrechen',
                style: TextStyle(color: Color(0xFF5F5F5F), fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEF8D25),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (itemNameController.text.isNotEmpty) {
                  if (selectedGroupId != null) {
                    _addItemToList(itemNameController.text, selectedGroupId!);
                  } else if (newGroupNameController.text.isNotEmpty) {
                    final lastGroup = await widget.productGroupService.fetchLastGroupByStoreId(widget.initialStoreId!);
                    final newOrder = lastGroup != null ? lastGroup.order + 1 : 0;

                    final newGroup = Productgroup(
                      name: newGroupNameController.text,
                      storeId: widget.initialStoreId!,
                      order: newOrder,
                    );
                    final newGroupId = await widget.productGroupService.addProductGroup(newGroup);
                    newGroup.id = newGroupId;
                    _addItemToList(itemNameController.text, newGroup.id.toString());
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Hinzufügen',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: newGroupNameController,
          decoration: InputDecoration(
            labelText: 'Bezeichnung ',
            labelStyle: TextStyle(
              color: Colors.black.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            floatingLabelStyle: const TextStyle(
              color: Color(0xFF7D9205),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF7D9205), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
          ),
          style: const TextStyle(color: Colors.black87),
        ),
        const SizedBox(height: 12),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFEF8D25),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            if (newGroupNameController.text.isNotEmpty) {
              final lastGroup = await widget.productGroupService.fetchLastGroupByStoreId(widget.initialStoreId!);
              final newOrder = lastGroup != null ? lastGroup.order + 1 : 0;

              final newGroup = Productgroup(
                name: newGroupNameController.text,
                storeId: widget.initialStoreId!,
                order: newOrder,
              );
              final newGroupId = await widget.productGroupService.addProductGroup(newGroup);
              newGroup.id = newGroupId;

              setState(() {
                groupItems.add(DropdownMenuItem<String>(
                  value: newGroup.id.toString(),
                  child: Text(newGroup.name),
                ));
                selectedGroupId = newGroup.id.toString();
              });
            }
          },
          child: const Text(
            'Neue Warengruppe',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    ),
  ),
);



        });
      },
    );
  }

  //PDF erstellem
  Future<void> createPdf() async {
    final pdf = pdf_wd.Document();
    pdf.addPage(pdf_wd.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pdf_wd.Context context) {
        return pdf_wd.Column(
          crossAxisAlignment: pdf_wd.CrossAxisAlignment.start,
          children: [
            pdf_wd.Text(widget.listName,
                style: const pdf_wd.TextStyle(fontSize: 24)),
            pdf_wd.Divider(),
            ...itemsByGroup.entries.map((entry) {
              return pdf_wd.Column(
                crossAxisAlignment: pdf_wd.CrossAxisAlignment.start,
                children: [
                  pdf_wd.Text(entry.key,
                      style: pdf_wd.TextStyle(
                          fontSize: 18, fontWeight: pdf_wd.FontWeight.bold)),
                  ...entry.value.map((item) {
                    return pdf_wd.Text(item['name'] ?? 'Unnamed Item',
                        style: const pdf_wd.TextStyle(fontSize: 14));
                  }),
                ],
              );
            }),
          ],
        );
      },
    ));

    String pdfFileName = '${widget.listName.replaceAll(' ', '_')}.pdf';
    await Printing.sharePdf(bytes: await pdf.save(), filename: pdfFileName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: PreferredSize(
  preferredSize: const Size.fromHeight(110),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      title: Transform.translate(
  offset: const Offset(-12, 0), // 👈 verschiebt nur den Titel nach links
  child: Text(
    widget.listName,
    style: const TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w500,
      color: Colors.black,
    ),
  ),
),

        centerTitle: false,
       actions: [
  IconButton(
    icon: const Icon(Icons.print, color: Color.fromARGB(255, 28, 27, 27)),
    iconSize: 28, // z. B. 28 statt Standard 24
    onPressed: createPdf,
  ),
  IconButton(
    icon: Icon(
      _isDeleteMode ? Icons.close : Icons.delete,
      color: Color.fromARGB(255, 28, 27, 27),
    ),
    iconSize: 28, // größer als Standard
    onPressed: toggleDeleteMode,
  ),
],

        elevation: 0,
      ),
      Padding(
        padding: const EdgeInsets.only(left: 60.0, bottom: 10),
        child: Material(
          borderRadius: BorderRadius.circular(6),
          color: const Color(0xFFF2E4D9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          
            child: DropdownButtonHideUnderline(
  child: DropdownButton<String>(
    value: _selectedShopId,
    isDense: true,
    onChanged: (String? newValue) {
      if (newValue != null) _updateShop(newValue);
    },
    dropdownColor: Colors.white,
    // 👇 Entfernt den standardmäßigen Dropdown-Pfeil
    icon: const SizedBox.shrink(),
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: Color(0xFF986224),
    ),
    // 👇 eigene Darstellung des Dropdowns (sichtbarer Button)
    selectedItemBuilder: (BuildContext context) {
      return _availableShops.map((shop) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              shop.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF986224),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down, color: Color(0xFF986224)),
          ],
        );
      }).toList();
    },
    // 👇 was in der Liste angezeigt wird
    items: _availableShops.map((shop) {
      return DropdownMenuItem<String>(
        value: shop.id.toString(),
        child: Text(
          shop.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF986224),
          ),
        ),
      );
    }).toList(),
  ),
),


            
          ),
        ),
      ),
    ],
  ),
),


      backgroundColor: Colors.white,
 body: itemsByGroup.isEmpty
    ? Align(
        alignment: Alignment.topCenter,
        child: FractionallySizedBox(
          heightFactor: 0.82, // Höhe des Platzes, den die Mitte einnimmt
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Image(
                image: AssetImage('lib/img3/Karotte.png'),
                width: 70,
                height: 70,
              ),
              SizedBox(height: 8),
              Text(
                'Noch keine Artikel',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 74, 69, 69),
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Tippe auf das Plus-Symbol, um \ndeinen ersten Artikel hinzuzufügen.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 57, 57, 57),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      )
  






      
     : ListView.builder(
        itemCount: itemsByGroup.keys.length,
        itemBuilder: (context, index) {
          String groupId = itemsByGroup.keys.elementAt(index);
          return ExpansionTile(
             /////hierrrr
              tilePadding: const EdgeInsets.only(left: 22, right: 24),
 childrenPadding: const EdgeInsets.only(top: 0),

  collapsedShape: RoundedRectangleBorder(
    side: BorderSide.none,
    borderRadius: BorderRadius.zero,
  ),
  shape: RoundedRectangleBorder(
    side: BorderSide.none,
    borderRadius: BorderRadius.zero,
  ),
            //WARENGRUPPEN DROPWDOWN
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    groupId,
                   style: const TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w400,
  color: Color.fromARGB(255, 148, 146, 146),
),

                  ),
                ),
                if (_isDeleteMode)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteProductGroup(groupId),
                  ),
              ],
            ),

           children: itemsByGroup[groupId]!.asMap().entries.map((entry) {
  final index = entry.key;
  final item = entry.value;

  return Column(
    children: [
      Row(
        children: [
          Padding(
            /////hierrrr
            padding: const EdgeInsets.only(left: 15.0),
            child: Transform.scale(
              scale: 1.4,
              child: Checkbox(
                value: item['isDone'] ?? false,
                onChanged: _isDeleteMode
                    ? null
                    : (bool? value) {
                        if (value != null) {
                          toggleItemDone(groupId, index);
                        }
                      },
                side: const BorderSide(
                  width: 1,
                  color: Color(0xFFB0B0B0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child:ListTile(
  //dense: true,
  contentPadding: EdgeInsets.symmetric(horizontal: 0), // oder left: 0, right: 0
              title: Text(
                item['name'],
                style: TextStyle(
                  fontSize: 18,
                     fontWeight: FontWeight.w500, 
                  decoration: item['isDone'] == true
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: item['isDone'] == true ? Colors.grey : Colors.black,
                ),
              ),
            ),
          ),
          if (_isDeleteMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => deleteItem(groupId, item['name']),
            ),
        ],
      ),
   if (index < itemsByGroup[groupId]!.length - 1)
  const Padding(
    padding: EdgeInsets.symmetric(horizontal: 22.0),
    child: Divider(
      color: Color(0xFFE0E0E0),
      height: 1,
      thickness: 1.5,
    ),
  ),


    ],
  );
}).toList(),

          );
        },
      ),
      //ADD ARTIKEL BUTTON
   floatingActionButton: !_isDeleteMode
    ? Padding(
        padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
        child: SizedBox(
          height: 74, // etwas kleiner als vorher
          width: 74,
          child: FloatingActionButton(
            onPressed: _showAddItemDialog,
            backgroundColor: const Color.fromARGB(255, 239, 141, 37),
            foregroundColor: Colors.white,
            elevation: 4, // schöner, aber nicht übertrieben
             child: const Icon(Icons.add, size: 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
        ),
      )
    : null,

    );
  }
}
