import 'package:flutter/material.dart';
import '../objects/productgroup.dart';
import 'package:smart/services/productgroup_service.dart';
import 'package:smart/services/shop_service.dart';
import 'package:smart/services/itemlist_service.dart';
import 'package:provider/provider.dart';
import 'package:smart/font_scaling.dart';
import 'package:flutter/services.dart';

class EditStoreScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final bool isNewStore;
  final ProductGroupService productGroupService;
  final ShopService shopService;
  final ItemListService itemListService;
  final String excludedItems;

  const EditStoreScreen(
      {super.key,
      required this.storeId,
      required this.storeName,
      this.isNewStore = false,
      required this.productGroupService,
      required this.shopService,
      required this.itemListService,
      required this.excludedItems});

  @override
  _EditStoreScreenState createState() => _EditStoreScreenState();
}

class CommaSeparatedFormatter extends TextInputFormatter {
  final RegExp allowed = RegExp(r'[a-zA-Z0-9, ]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buffer = StringBuffer();
    int selectionIndex = newValue.selection.baseOffset;
    int removedCount = 0;

    for (int i = 0; i < newValue.text.length; i++) {
      final char = newValue.text[i];
      if (allowed.hasMatch(char)) {
        buffer.write(char);
      } else {
        if (i < selectionIndex) removedCount++;
      }
    }

    final filtered = buffer.toString();
    final newSelection = selectionIndex - removedCount;

    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(
        offset: newSelection.clamp(0, filtered.length),
      ),
    );
  }
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  List<Productgroup> _productGroups = [];
  bool _isLoading = true;
  bool _isEditMode = false;
  late TextEditingController _storeNameController;
  late String storename;
  String _excludedItems = '';

  @override
  void initState() {
    super.initState();
    _storeNameController = TextEditingController(text: widget.storeName);
    storename = widget.storeName;
    _fetchProductGroups();
    _loadExcludedItems();
    _debugLogFullShop();

    if (widget.isNewStore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptAddDefaultProductGroups();
      });
    }
  }

  Future<void> _loadExcludedItems() async {
    final excluded = await widget.shopService
        .getExcludedItemsById(int.parse(widget.storeId));
    setState(() {
      _excludedItems = excluded ?? '';
    });
  }

  Future<void> _fetchProductGroups() async {
    final productGroups = await widget.productGroupService
        .fetchProductGroupsByStoreIdSorted(widget.storeId);
    setState(() {
      _productGroups = productGroups;
      _isLoading = false;
    });
  }

  Future<void> _debugLogFullShop() async {
    final shop =
        await widget.shopService.fetchShopById(int.parse(widget.storeId));
    if (shop != null) {
      print("🔎 FULL SHOP DEBUG:");
      print("ID: ${shop.id}");
      print("Name: ${shop.name}");
      print("ImagePath: ${shop.imagePath}");
      print("ExcludedItems: ${shop.excludedItems}");
    } else {
      print("❌ SHOP NOT FOUND");
    }
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

    final existingGroups = await widget.productGroupService
        .fetchProductGroupsByStoreIdSorted(widget.storeId);
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
        final scaling = context.watch<FontScaling>().factor;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360, minWidth: 300),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Standard-Warengruppen hinzufügen?',
                      style: TextStyle(
                        fontSize: 20 * scaling,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Möchtest du die Standard-Warengruppen dieser Filiale hinzufügen?',
                      style: TextStyle(
                        fontSize: 16 * scaling,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFE2E2E2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Überspringen',
                            style: TextStyle(
                              color: const Color(0xFF5F5F5F),
                              fontSize: 14 * scaling,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFEF8D25),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Hinzufügen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14 * scaling,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _addDefaultProductGroups();
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

    final shop =
        await widget.shopService.fetchShopById(int.parse(widget.storeId));
    if (shop != null) {
      shop.name = newStoreName;
      storename = newStoreName;
      await widget.shopService.updateShop(shop);
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

  Future<void> _updateProductGroupOrder() async {
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
        final scaling = context.watch<FontScaling>().factor;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360, minWidth: 300),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Warengruppe hinzufügen',
                      style: TextStyle(
                        fontSize: 20 * scaling,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: groupNameController,
                      decoration: InputDecoration(
                        labelText: 'Bezeichnung',
                        labelStyle: TextStyle(
                          color: Colors.black.withOpacity(0.5),
                          fontSize: 16 * scaling,
                          fontWeight: FontWeight.w400,
                        ),
                        floatingLabelStyle: TextStyle(
                          color: const Color(0xFF7D9205),
                          fontSize: 16 * scaling,
                          fontWeight: FontWeight.w500,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Color(0xFF7D9205)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: TextStyle(
                        fontSize: 16 * scaling,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFE2E2E2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Abbrechen',
                            style: TextStyle(
                              color: const Color(0xFF5F5F5F),
                              fontSize: 14 * scaling,
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFEF8D25),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Hinzufügen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14 * scaling,
                            ),
                          ),
                          onPressed: () {
                            if (groupNameController.text.trim().isNotEmpty) {
                              _addProductGroupIfNotExists(
                                  groupNameController.text.trim());
                              Navigator.of(context).pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bitte Bezeichnung eingeben.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showExcludedItemsDialog() async {
    final scaling = context.read<FontScaling>().factor;
    final currentExcluded = await widget.shopService
            .getExcludedItemsById(int.parse(widget.storeId)) ??
        '';

    final controller = TextEditingController(text: currentExcluded);

    String? errorMessage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360, minWidth: 300),
                child: Material(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nicht verfügbare Artikel',
                          style: TextStyle(
                            fontSize: 20 * scaling,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: controller,
                          inputFormatters: [CommaSeparatedFormatter()],
                          decoration: InputDecoration(
                            hintText: 'Artikel kommasepariert eingeben',
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Color(0xFF7D9205)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            errorText: errorMessage,
                          ),
                          style: TextStyle(
                            fontSize: 16 * scaling,
                            color: Colors.black87,
                          ),
                          maxLines: null,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFE2E2E2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Abbrechen',
                                style: TextStyle(
                                  color: const Color(0xFF5F5F5F),
                                  fontSize: 14 * scaling,
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFEF8D25),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Speichern',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14 * scaling,
                                ),
                              ),
                              onPressed: () async {
                                final rawText = controller.text.trim();

                                if (rawText.endsWith(',')) {
                                  setState(() {
                                    errorMessage = 'Bitte kein Komma am Ende.';
                                  });
                                  return;
                                }

                                final cleaned = rawText
                                    .split(',')
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .join(', ');

                                final currentRaw = currentExcluded.trim();

                                if (rawText == currentRaw) {
                                  Navigator.pop(context);
                                  return;
                                }

                                await widget.shopService
                                    .updateExcludedItemsById(
                                  int.parse(widget.storeId),
                                  cleaned,
                                );

                                Navigator.pop(
                                    context, true);

                                await _loadExcludedItems();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Nicht verfügbare Artikel gespeichert')),
                                );
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
      },
    );
  }

  Future<void> _addProductGroupIfNotExists(String name) async {
    final existingGroup = await widget.productGroupService
        .fetchByNameAndShop(name, widget.storeId);

    if (existingGroup == null) {
      final newOrder = _productGroups.length;
      final productGroup = Productgroup(
        name: name,
        storeId: widget.storeId,
        order: newOrder,
      );
      final newGroupId =
          await widget.productGroupService.addProductGroup(productGroup);
      productGroup.id = newGroupId;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Warengruppe hinzugefügt.'),
        backgroundColor: Colors.green,
      ));

      setState(() {
        _productGroups.add(productGroup);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Warengruppe existiert bereits.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _deleteProductGroup(Productgroup group) async {
    final itemLists = await widget.itemListService.fetchAllItemLists();
    final listsUsingGroup = itemLists.where((list) {
      final items = list.getItems();
      return items.any((item) => item['groupId'] == group.id.toString());
    }).toList();

    if (listsUsingGroup.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Warengruppe löschen?'),
          content: Text(
            'Die Warengruppe "${group.name}" wird in ${listsUsingGroup.length} Einkaufsliste(n) verwendet.\n'
            'Möchtest du diese wirklich löschen?',
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

      for (final list in listsUsingGroup) {
        final updatedItems = list
            .getItems()
            .where((item) => item['groupId'] != group.id.toString())
            .toList();
        list.setItems(updatedItems);
        await widget.itemListService.updateItemList(list);
      }
    }

    await widget.productGroupService.deleteProductGroup(group.id);

    setState(() {
      _productGroups.removeWhere((g) => g.id == group.id);
    });
    await _updateProductGroupOrder();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Warengruppe gelöscht. Reihenfolge aktualisiert.'),
      backgroundColor: Colors.green,
    ));
  }

  Future<void> _deleteStore() async {
    final storeId = widget.storeId;

    final assignedLists =
        await widget.itemListService.fetchItemListsByShopId(storeId);

    if (assignedLists.isNotEmpty) {
      final confirmDelete = await showDialog<bool>(
        context: context,
        builder: (context) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360, minWidth: 300),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alles löschen?',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Dieser Laden ist mit ${assignedLists.length} Einkaufsliste(n) verknüpft. Möchtest du den Laden und alle zugehörigen Listen wirklich löschen?",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFE2E2E2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Behalten',
                            style: TextStyle(
                                color: Color(0xFF5F5F5F), fontSize: 14),
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFEF8D25),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Alles löschen',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
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
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, minWidth: 300),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laden löschen?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bist du sicher, dass du diesen Laden löschen möchtest?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFE2E2E2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Behalten',
                          style:
                              TextStyle(color: Color(0xFF5F5F5F), fontSize: 14),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEF8D25),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Löschen',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
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
    final scaling = context.watch<FontScaling>().factor;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _isEditMode
                ? TextField(
                    controller: _storeNameController,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 26 * scaling,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Ladenname bearbeiten",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _toggleEditMode(),
                  )
                : Text(
                    storename,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 26 * scaling,
                    ),
                  ),
            if (_excludedItems.trim().isNotEmpty)
              SizedBox(
                height: 20,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'N/A: ',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12 * scaling,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _excludedItems,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12 * scaling,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.block, color: Color.fromARGB(255, 30, 30, 30)),
            onPressed: _showExcludedItemsDialog,
          ),
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
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 35.0, vertical: 4),
                                title: Text(
                                  group.name,
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 31, 31, 31),
                                    fontSize: 20 * scaling,
                                  ),
                                ),
                                trailing: SizedBox(
                                  width: 30,
                                  height: 40,
                                  child: Center(
                                    child: _isEditMode
                                        ? IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Color.fromARGB(
                                                    255, 239, 141, 37)),
                                            onPressed: () =>
                                                _deleteProductGroup(group),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          )
                                        : ReorderableDragStartListener(
                                            index:
                                                _productGroups.indexOf(group),
                                            child: const Icon(Icons.reorder,
                                                color: Color.fromARGB(
                                                    255, 239, 141, 37)),
                                          ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20.0, bottom: 20.0),
                  child: _isEditMode
                      ? Center(
                          child: ElevatedButton.icon(
                            onPressed: _deleteStore,
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: Text(
                              "Laden löschen",
                              style: TextStyle(
                                fontSize: 17 * scaling,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        )
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: SizedBox(
                            width: 74,
                            height: 74,
                            child: FloatingActionButton(
                              onPressed: _showAddProductGroupDialog,
                              backgroundColor:
                                  const Color.fromARGB(255, 239, 141, 37),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                              tooltip: 'Warengruppe hinzufügen',
                              child: const Icon(Icons.add, size: 50),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
