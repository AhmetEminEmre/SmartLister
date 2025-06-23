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
import 'package:smart/screens/shop_screen.dart';

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
  Set<String> expandedGroups = {};
  String? _lastSelectedGroupId;
  String _excludedItemsRaw = '';
  Set<String> _excludedItemsSet = {};

  String? _editingItemName;
  String? _editingGroupName;
  final TextEditingController _editController = TextEditingController();

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Warengruppe löschen?'),
        content: Text(
          'Möchtest du die Warengruppe "$groupName" und alle enthaltenen Artikel wirklich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Artikel löschen?'),
        content: Text(
          'Möchtest du den Artikel "$itemName" wirklich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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

    final productGroups = await widget.productGroupService
        .fetchProductGroupsByStoreIdSorted(_selectedShopId!);

    final savedList = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));
    final savedItems = savedList?.getItems() ?? [];

    Map<String, List<Map<String, dynamic>>> groupedItems = {};
    for (var item in savedItems) {
      final groupName = productGroups
          .firstWhere(
            (g) => g.id.toString() == item['groupId'],
            orElse: () =>
                Productgroup(name: 'Unbekannt', storeId: 'x', order: 0),
          )
          .name;
      groupedItems.putIfAbsent(groupName, () => []).add(item);
    }

    Map<String, List<Map<String, dynamic>>> orderedGroupedItems = {};
    for (var group in productGroups) {
      if (groupedItems.containsKey(group.name)) {
        orderedGroupedItems[group.name] = groupedItems[group.name]!;
      }
    }

    final oldExpanded = Set<String>.from(expandedGroups);

    setState(() {
      itemsByGroup = orderedGroupedItems;
      expandedGroups =
          oldExpanded.intersection(orderedGroupedItems.keys.toSet());
    });
  }

  Future<void> loadExcludedItems() async {
    if (_selectedShopId == null) return;

    final shop =
        await widget.shopService.fetchShopById(int.parse(_selectedShopId!));
    final raw = shop?.excludedItems ?? '';

    setState(() {
      _excludedItemsRaw = raw;
      _excludedItemsSet = raw
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet();
    });
  }

  Future<void> loadShops() async {
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
    await loadExcludedItems();
  }

  void _updateShop(String newShopId) async {
    final newShop = _availableShops.firstWhere(
      (shop) => shop.id.toString() == newShopId,
    );

    final list = await widget.itemListService
        .fetchItemListById(int.parse(widget.shoppingListId));
    if (list == null) return;

    final currentItems = list.getItems();

    final allGroups =
        await widget.productGroupService.fetchAllProductGroupsSorted();
    List<Productgroup> targetGroups = await widget.productGroupService
        .fetchProductGroupsByStoreIdSorted(newShopId);

    final nameToGroup = {for (var g in targetGroups) g.name: g};

    final usedGroupNames = currentItems.map((item) {
      final originalName = allGroups
          .firstWhere(
            (g) => g.id.toString() == item['groupId'],
            orElse: () =>
                Productgroup(name: 'Unbekannt', storeId: 'x', order: 0),
          )
          .name;
      return originalName;
    }).toSet();

    int maxOrder = targetGroups.isEmpty
        ? 0
        : targetGroups.map((g) => g.order).reduce((a, b) => a > b ? a : b);
    for (var name in usedGroupNames) {
      if (!nameToGroup.containsKey(name)) {
        final newGroup = Productgroup(
          name: name,
          storeId: newShopId,
          order: ++maxOrder,
        );
        final newId =
            await widget.productGroupService.addProductGroup(newGroup);
        newGroup.id = newId;
      }
    }
    targetGroups = await widget.productGroupService
        .fetchProductGroupsByStoreIdSorted(newShopId);

    nameToGroup.clear();
    for (var g in targetGroups) {
      nameToGroup[g.name] = g;
    }

    final excludedRaw = newShop.excludedItems ?? '';
    final excludedSet = excludedRaw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    List<Map<String, dynamic>> acceptedItems = [];
    List<String> skippedItemNames = [];

    for (var item in currentItems) {
      final itemName = item['name'].toString().toLowerCase();
      if (excludedSet.contains(itemName)) {
        skippedItemNames.add(item['name']);
        continue;
      }

      final originalName = allGroups
          .firstWhere(
            (g) => g.id.toString() == item['groupId'],
            orElse: () =>
                Productgroup(name: 'Unbekannt', storeId: 'x', order: 0),
          )
          .name;
      item['groupId'] = nameToGroup[originalName]!.id.toString();
      acceptedItems.add(item);
    }

    list.setItems(acceptedItems);
    list.shopId = newShopId;
    await widget.itemListService.updateItemList(list);

    setState(() {
      _selectedShopId = newShopId;
      _selectedShopName = newShop.name;
      _lastSelectedGroupId = null;
    });

    await loadItems();
    await loadExcludedItems();

    if (skippedItemNames.isNotEmpty) {
      final msg = skippedItemNames.length == 1
          ? 'Der Artikel "${skippedItemNames.first}" wurde nicht übernommen, da er in diesem Laden nicht verfügbar ist.'
          : '${skippedItemNames.length} Artikel wurden nicht übernommen, da sie in diesem Laden nicht verfügbar sind.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
    }
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

    final groupName = (await widget.productGroupService
            .fetchProductGroupsByStoreIdSorted(_selectedShopId!))
        .firstWhere((g) => g.id.toString() == groupId,
            orElse: () =>
                Productgroup(name: 'Unbekannt', storeId: '0', order: 0))
        .name;

    setState(() {
      expandedGroups.add(groupName);
    });

    await loadItems();
  }

  void _showAddItemDialog() async {
    TextEditingController itemNameController = TextEditingController();
    String? selectedGroupId = _lastSelectedGroupId;
    String? errorMessage;

    final productGroups = await widget.productGroupService
        .fetchProductGroupsByStoreIdSorted(_selectedShopId!);

    List<DropdownMenuItem<String>> groupItems = productGroups.map((group) {
      return DropdownMenuItem<String>(
        value: group.id.toString(),
        child: Text(group.name),
      );
    }).toList();

    if (selectedGroupId != null &&
        !productGroups.any((g) => g.id.toString() == selectedGroupId)) {
      selectedGroupId = null;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Artikel hinzufügen',
              style: TextStyle(
                  color: Color(0xFF161616),
                  fontSize: 20,
                  fontWeight: FontWeight.w500),
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
                        borderSide: const BorderSide(
                            color: Color(0xFF7D9205), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.grey.shade400, width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                    ),
                    style: const TextStyle(color: Colors.black87),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: selectedGroupId,
                    onChanged: (newValue) {
                      setState(() {
                        selectedGroupId = newValue;
                        _lastSelectedGroupId = newValue;
                      });
                    },
                    items: groupItems,
                    isExpanded: true,
                    //   icon: const SizedBox.shrink(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.grey.shade400, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF7D9205), width: 2),
                      ),
                    ),
                    dropdownColor: Colors.white,
                    style:
                        const TextStyle(color: Color(0xFF212121), fontSize: 16),
                    hint: const Text(
                      'Warengruppe wählen',
                      style: TextStyle(color: Color(0xFF363636), fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () async {
                        final selectedShop = await widget.shopService
                            .fetchShopById(int.parse(_selectedShopId!));

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditStoreScreen(
                              storeId: selectedShop!.id.toString(),
                              storeName: selectedShop.name,
                              excludedItems: selectedShop.excludedItems ?? '',
                              productGroupService: widget.productGroupService,
                              shopService: widget.shopService,
                              itemListService: widget.itemListService,
                            ),
                          ),
                        );
                        
                        await loadShops();
                        await loadItems();
                        await loadExcludedItems();

                        if (result is Productgroup) {
                          _availableShops =
                              await widget.shopService.fetchShops();
                          final aktualisierteProductGroups = await widget
                              .productGroupService
                              .fetchProductGroupsByStoreIdSorted(
                                  _selectedShopId!);

                          setState(() {
                            groupItems =
                                aktualisierteProductGroups.map((group) {
                              return DropdownMenuItem<String>(
                                value: group.id.toString(),
                                child: Text(group.name),
                              );
                            }).toList();

                            selectedGroupId = result.id.toString();
                            _lastSelectedGroupId = result.id.toString();
                          });

                          await loadItems();
                          await loadExcludedItems();
                        }
                      },
                      child: const Text(
                        '+ Neue Warengruppe hinzufügen',
                        style: TextStyle(
                          color: Color(0xFF7D9205),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF7D9205),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFE2E2E2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Abbrechen',
                          style:
                              TextStyle(color: Color(0xFF5F5F5F), fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEF8D25),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (itemNameController.text.isNotEmpty &&
                              selectedGroupId != null) {
                            final newItemName =
                                itemNameController.text.trim().toLowerCase();

                            if (_excludedItemsSet.contains(newItemName)) {
                              setState(() {
                                errorMessage =
                                    'Der Artikel "$newItemName" ist in diesem Laden nicht verfügbar.';
                              });
                              return;
                            }

                            _addItemToList(newItemName, selectedGroupId!);
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
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
              ),
              title: Transform.translate(
                offset: const Offset(
                    -12, 0), // 👈 verschiebt nur den Titel nach links
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
                  icon: const Icon(Icons.print,
                      color: Color.fromARGB(255, 28, 27, 27)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              const Icon(Icons.arrow_drop_down,
                                  color: Color(0xFF986224)),
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
                  key: ValueKey('groupTile_$groupId'), // wichtig für Rebuild
                  initiallyExpanded: expandedGroups
                      .contains(groupId), // Zustand aus deinem Set
                  onExpansionChanged: (bool expanded) {
                    setState(() {
                      if (expanded) {
                        expandedGroups.add(groupId);
                      } else {
                        expandedGroups.remove(groupId);
                      }
                    });
                  },
                  tilePadding: const EdgeInsets.only(left: 22, right: 24),
                  childrenPadding: EdgeInsets.zero,

                  collapsedShape: const RoundedRectangleBorder(
                    side: BorderSide.none,
                    borderRadius: BorderRadius.zero,
                  ),
                  shape: const RoundedRectangleBorder(
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
                            fontSize: 16,
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
                        Padding(
                          padding: EdgeInsets.only(
                            left: 16.0,
                            right: 16.0,
                            top: index == 0
                                ? 0.0
                                : 12.0, // 👈 hier steuerst du den Abstand zum Gruppen-Titel
                            bottom: 3.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Transform.scale(
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _editingItemName = item['name'];
                                      _editingGroupName = groupId;
                                      _editController.text = item['name'];
                                    });
                                  },
                                  child: _editingItemName == item['name'] &&
                                          _editingGroupName == groupId
                                      ? TextField(
                                          controller: _editController,
                                          autofocus: true,
                                          cursorColor: Color(0xFF7D9205),
                                          style: const TextStyle(fontSize: 18),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onSubmitted: (value) async {
                                            final list = await widget
                                                .itemListService
                                                .fetchItemListById(int.parse(
                                                    widget.shoppingListId));
                                            if (list != null) {
                                              final items = list.getItems();
                                              final current = items.firstWhere(
                                                (e) =>
                                                    e['name'] ==
                                                        _editingItemName &&
                                                    e['groupId'] ==
                                                        (itemsByGroup[groupId]
                                                            ?.first['groupId']),
                                                orElse: () => {},
                                              );
                                              if (current.isNotEmpty) {
                                                current['name'] = value;
                                                list.setItems(items);
                                                await widget.itemListService
                                                    .updateItemList(list);
                                              }
                                            }
                                            setState(() {
                                              _editingItemName = null;
                                              _editingGroupName = null;
                                            });
                                            await loadItems();
                                          },
                                        )
                                      : Text(
                                          item['name'],
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            decoration: item['isDone'] == true
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                            color: item['isDone'] == true
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                ),
                              ),
                              if (_isDeleteMode)
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      deleteItem(groupId, item['name']),
                                ),
                            ],
                          ),
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
