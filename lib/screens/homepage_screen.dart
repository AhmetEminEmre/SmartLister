import 'package:flutter/material.dart';
import 'package:smart/screens/addlist_screen.dart';
import 'package:smart/screens/itemslist_screen.dart';
import 'package:smart/screens/addshop_screen.dart';
import 'package:smart/screens/nickname_screen.dart';
import 'package:smart/screens/shop_screen.dart';
import 'package:smart/services/itemlist_service.dart';
import 'package:smart/services/shop_service.dart';
import 'package:smart/services/userinfo_service.dart';
import 'package:smart/services/productgroup_service.dart';
import 'package:smart/services/template_service.dart';
import 'package:smart/objects/itemlist.dart';
import 'package:smart/objects/shop.dart';
import 'package:smart/objects/template.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:smart/screens/settings_screen.dart';

import 'package:provider/provider.dart';
import 'package:smart/font_scaling.dart';


class HomePage extends StatefulWidget {
  final ItemListService itemListService;
  final ShopService shopService;
  final NicknameService userinfoService;
  final ProductGroupService productGroupService;
  final TemplateService templateService;

  const HomePage({
    super.key,
    required this.itemListService,
    required this.shopService,
    required this.userinfoService,
    required this.productGroupService,
    required this.templateService,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stream<void> _itemListStream;
  late Stream<void> _shopStream;

  List<Einkaufsladen> _topShops = [];
  bool _loadingShops = true;
  String _nickname = ''; //hier in zukunft namen setzen

  @override
  void initState() {
    super.initState();
    _setupWatchers();
    _fetchTopShops();
    _checkNickname();
  }

  void _setupWatchers() {
    //boardacast as streams caused error "Stream has already been listened to" error
    _itemListStream = widget.itemListService.watchItemLists();
    _shopStream = widget.shopService.watchShops();

    _itemListStream.listen((_) {
      _fetchLatestItemLists();
      _fetchTopShops();
    });

    _shopStream.listen((_) {
      _fetchTopShops();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkNickname();
  }

  Future<void> _checkNickname() async {
    final username = await widget.userinfoService.getNickname();
    if (username == null || username.isEmpty) {
      _navigateToNicknameScreen();
    } else {
      setState(() {
        _nickname = username;
      });
    }
  }

  void _navigateToNicknameScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NicknameScreen(
            nicknameService: widget.userinfoService,
            productGroupService: widget.productGroupService,
            shopService: widget.shopService,
            itemListService: widget.itemListService,
            templateService: widget.templateService,
          ),
        ),
      );
    });
  }

  Future<void> _fetchTopShops() async {
    setState(() => _loadingShops = true);
    final shops = await widget.shopService.fetchShops();
    setState(() {
      _topShops = shops;
      _loadingShops = false;
    });
  }

  Future<List<Itemlist>> _fetchLatestItemLists() async {
    final lists = await widget.itemListService.fetchAllItemLists();
    final valid = lists.where((l) => l.shopId.isNotEmpty).toList();
    valid.sort((a, b) => b.creationDate.compareTo(a.creationDate));
    return valid.take(5).toList();
  }

  void _renameList(Itemlist itemlist) {
    TextEditingController nameController =
        TextEditingController(text: itemlist.name);
    showDialog(
      context: context,
      builder: (context) {
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
            const Text(
              'Listennamen ändern',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Listenname',
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
                  borderSide: const BorderSide(color: Color(0xFF7D9205)),
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
              style: const TextStyle(
                fontSize: 16,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Abbrechen',
                    style: TextStyle(color: Color(0xFF5F5F5F), fontSize: 14),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFEF8D25),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Speichern',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) {
                      itemlist.name = nameController.text.trim();
                      final navigator = Navigator.of(context);
                      await widget.itemListService.updateItemList(itemlist);
                      if (!mounted) return;
                      navigator.pop();
                      setState(() {
                        _fetchLatestItemLists();
                      });
                    }
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

  void _deleteList(Itemlist itemlist) async {
    await widget.itemListService.deleteItemList(itemlist.id);
    setState(() {
      _fetchLatestItemLists();
      _fetchTopShops();
    });
  }

  Future<List<String>> getAllProductGroups(String shopId) async {
    final groups = await widget.productGroupService.fetchProductGroups(shopId);
    return groups.map((group) => group.name.trim()).toList();
  }

  Future<String> getGroupName(String groupId) async {
    final group =
        await widget.productGroupService.fetchGroupById(int.parse(groupId));
    return group?.name ?? "Unbekannt";
  }

  Future<String> getShopName(String groupId) async {
    if (groupId.isEmpty) return "Unbekannt";

    final parsedId = int.tryParse(groupId);
    if (parsedId == null) return "Unbekannt";

    final shop = await widget.shopService.fetchShopById(parsedId);
    return shop?.name ?? "Unbekannt";
  }

  void _saveListAsTemplate(Itemlist itemlist) async {
    final newTemplate = Template(
      name: itemlist.name,
      items: itemlist.getItems(),
      imagePath: itemlist.imagePath!,
      storeId: itemlist.shopId,
    );

    await widget.templateService.addTemplate(newTemplate);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Liste als Vorlage gespeichert!'),
    ));
  }

  void _createListDialog(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateListScreen(
            itemListService: widget.itemListService,
            shopService: widget.shopService,
            productGroupService: widget.productGroupService,
            templateService: widget.templateService),
      ),
    );

    if (result == true) {
      setState(() {
        _fetchLatestItemLists();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaling = context.watch<FontScaling>().factor;

    return Scaffold(
    appBar: AppBar(
  automaticallyImplyLeading: false,
  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
  title: Row(
    children: [
      Expanded(
        child: Text(
          _nickname.isNotEmpty ? 'Guten Tag $_nickname!' : 'Loading...',
          style: const TextStyle(
            fontSize: 30,
            color: Color(0xFF222222),
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
      ),
    ],
  ),
  actions: <Widget>[
    IconButton(
      icon: const Icon(Icons.settings, color: Color(0xFF222222)),
      iconSize: 30,
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsScreen(
              nicknameService: widget.userinfoService,
            ),
          ),
        );
        _checkNickname();
      },
    ),
  ],
),

      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
             Padding(
              padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 1.0,
                  bottom: 2.0), // Abstand unten verringern
              child: Text(
                'Meine Listen',
                style: TextStyle(
          fontSize: 23 * scaling,
                    color: Color(0xFF222222),
                    fontWeight: FontWeight.w500),
              ),
            ),
            StreamBuilder<void>(
              stream: _itemListStream,
              builder: (context, snapshot) {
                return FutureBuilder<List<Itemlist>>(
                  future: _fetchLatestItemLists(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.center, // Karten zentrieren
                        children: snapshot.data!
                            .map((itemlist) => _buildListCard(itemlist))
                            .toList(),
                      );
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                );
              },
            ),

            // BUTTON NEUE LISTE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SizedBox(
                width: double.infinity, // Button über die gesamte Breite
                child: ElevatedButton.icon(
                  onPressed: () => _createListDialog(context),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text(
                    "Neue Einkaufsliste",
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFEDF2D0), // Farbe des Buttons
                    foregroundColor: const Color(0xFF94A047), // Textfarbe
                    padding: const EdgeInsets.symmetric(
                        vertical: 16), // Vertikale Höhe
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12), // Abgerundete Ecken
                    ),
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Meine Lieblingseinkaufsläden',
                style: TextStyle(
                  fontSize: 23,
                  color: Color(0xFF222222),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _loadingShops
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal, // Horizontal Scrollbar
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16), // Abstand links und rechts
                      child: Row(
                        children: _topShops
                            .map((shop) => _buildShopCard(shop))
                            .toList(),
                      ),
                    ),
                  ),

            // BUTTON NEUER LADEN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: SizedBox(
                width: double.infinity, // Button über die gesamte Breite
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddStoreScreen(
                          shopService: widget.shopService,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_business),
                  label: const Text(
                    "Neuer Einkaufsladen",
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFEDF2D0), // Farbe des Buttons
                    foregroundColor: const Color(0xFF94A047), // Textfarbe
                    padding: const EdgeInsets.symmetric(
                        vertical: 16), // Vertikale Höhe
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12), // Abgerundete Ecken
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(Einkaufsladen shop) {
    String imagePath = shop.imagePath ?? 'lib/img/default_image.png';

    print(
        'Shop: ${shop.name}, Image Path beim Aufrufen: $imagePath'); // Debugging-Print

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditStoreScreen(
                  storeId: shop.id.toString(),
                  storeName: shop.name,
                  shopService: widget.shopService,
                  itemListService: widget.itemListService,
                  productGroupService: widget.productGroupService),
            ),
          );
        },
        child: Container(
          width: 110, // Fixe Breite
          height: 140, // Höhere Box
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 10), // Padding innerhalb der Box
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12), // Abgerundete Ecken
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              onError: (exception, stackTrace) {
                print('Error loading image: $exception'); // Fehler-Handling
              },
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0), BlendMode.darken),
            ),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              shop.name,
              style: const TextStyle(
                color: Color.fromARGB(255, 64, 63, 63),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2, // Maximal 2 Zeilen
              overflow:
                  TextOverflow.ellipsis, // Text abschneiden oder umbrechen
            ),
          ),
        ),
      ),
    );
  }

// LISTEN CARDS
  Widget _buildListCard(Itemlist itemlist) {
    String imagePath = itemlist.imagePath ?? 'lib/img/default_image.png';

    List<Map<String, dynamic>> items = itemlist.getItems();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 12.0, vertical: 4.0), // Gleiche Padding wie Buttons
      child: Center(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemListScreen(
                  listName: itemlist.name,
                  shoppingListId: itemlist.id.toString(),
                  items: [itemlist],
                  initialStoreId: itemlist.shopId,
                  itemListService: widget.itemListService,
                  productGroupService: widget.productGroupService,
                  shopService: widget.shopService,
                ),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              // Dynamische Breite: 90% der Bildschirmbreite
              width: double.infinity,
              height: 150, // Höhe der Card hier festlegen
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.04), BlendMode.darken),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titel der Liste
                        Text(
                          itemlist.name,
                          style: GoogleFonts.poppins(
                            fontSize: 33,
                            color: Colors.white,
                            fontWeight: FontWeight.w500, // SemiBold Gewichtung
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Artikel-Tag mit den definierten Farben
                            _buildTag(
                              '${items.length} Artikel',
                              const Color(0xFFF9F2BF), // Hintergrundfarbe
                              const Color.fromARGB(
                                  255, 144, 133, 54), // Textfarbe
                            ),
                            const SizedBox(width: 5),
                            // Shop-Tag mit den definierten Farben
                            FutureBuilder<String>(
                              future: getShopName(itemlist.shopId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.done &&
                                    snapshot.hasData) {
                                  return _buildTag(
                                    snapshot.data!,
                                    const Color(0xFFF2E4D9), // Hintergrundfarbe
                                    const Color(0xFF986224), // Textfarbe
                                  );
                                } else {
                                  return _buildTag(
                                    "Unbekannt",
                                    const Color(0xFFF2E4D9), // Hintergrundfarbe
                                    const Color(0xFF986224), // Textfarbe
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Drei Punkte: Etwas weiter rechts und höher positionieren
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            bottom: 2.0, right: 1.0), // Etwas weiter rechts
                        child: GestureDetector(
                          behavior: HitTestBehavior
                              .translucent, // Klickverhalten verbessern
                          child: _buildOptionsMenu(itemlist), // Optionen-Menü
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

// TAG-WIDGET: Dynamische Farben und Schriftart
  Widget _buildTag(String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor, // Dynamische Hintergrundfarbe
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: textColor, // Dynamische Textfarbe
          fontSize: 18, // Größerer Text
          fontWeight: FontWeight.w600, // SemiBold Gewichtung
        ),
      ),
    );
  }

 Widget _buildOptionsMenu(Itemlist itemlist) {
  return PopupMenuButton<String>(
    onSelected: (value) {
      switch (value) {
        case 'rename':
          _renameList(itemlist);
          break;
        case 'delete':
          _deleteList(itemlist);
          break;
        case 'saveAsTemplate':
          _saveListAsTemplate(itemlist);
          break;
        case 'exportCsv':
          exportCsvWithFilePicker(itemlist);
          break;
      }
    },
    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(
        value: 'rename',
        child: Text('Liste umbenennen'),
      ),
      const PopupMenuItem<String>(
        value: 'delete',
        child: Text('Liste löschen'),
      ),
      const PopupMenuItem<String>(
        value: 'saveAsTemplate',
        child: Text('Liste als Vorlage speichern'),
      ),
      const PopupMenuItem<String>(
        value: 'exportCsv',
        child: Text('Liste exportieren'),
      ),
    ],
    icon: const Icon(Icons.more_vert, color: Colors.white),
    offset: const Offset(0, 40), // nach unten verschoben
    color: Colors.white, // 👈 Hintergrundfarbe weiß
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16), // runde Ecken
    ),
  );
}

  Future<Directory> _getDownloadDirectory() async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
      String newPath = "";
      List<String> folders = directory!.path.split("/");
      for (int x = 1; x < folders.length; x++) {
        String folder = folders[x];
        if (folder != "Android") {
          newPath += "/$folder";
        } else {
          break;
        }
      }
      newPath = "$newPath/Download";
      directory = Directory(newPath);
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
      directory = Directory('${directory.path}/Downloads');
    }

    return directory!;
  }

  Future<void> exportCsv(
      String fileName, List<Map<String, dynamic>> items) async {
    StringBuffer csvBuffer = StringBuffer();

    csvBuffer.write('name;');
    final productGroups =
        items.map((item) => item['productGroup']).toSet().toList();
    csvBuffer.writeAll(productGroups, ';');
    csvBuffer.write(';\n');
    print('CSV Header: name;${productGroups.join(";")};');

    for (var productGroup in productGroups) {
      final groupItems =
          items.where((item) => item['productGroup'] == productGroup).toList();
      for (var item in groupItems) {
        final line =
            '${item['productGroup']};${item['itemName']};${item['status']}';
        csvBuffer.writeln(line);
        print('CSV Line: $line');
      }
    }

    final directory = await _getDownloadDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(csvBuffer.toString());
    _showSnackBar('Datei erfolgreich im Downloads-Ordner gespeichert.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  Future<void> exportCsvWithFilePicker(Itemlist itemlist) async {
    StringBuffer csvBuffer = StringBuffer();

    String escapeCsvString(String input) {
      return utf8.decode(utf8.encode(input.trim()));
    }

    String shopName = escapeCsvString(await getShopName(itemlist.shopId));
    List<String> productGroupNames =
        (await getAllProductGroups(itemlist.shopId))
            .map((groupName) => escapeCsvString(groupName))
            .toList();

    final listname = itemlist.name;
    final imagePath = itemlist.imagePath;
    csvBuffer.writeln(
        '$listname;$imagePath;$shopName;${productGroupNames.join(";")};');

    final List<dynamic> items = json.decode(itemlist.itemsJson);
    for (var item in items) {
      String groupName = escapeCsvString(await getGroupName(item['groupId']));
      String itemName = escapeCsvString(item['name']);
      String itemStatus = escapeCsvString(item['isDone'].toString());

      final line = '$groupName;$itemName;$itemStatus';
      print(line);
      csvBuffer.writeln(line);
    }

    final fileName = '${itemlist.name}.csv';
    final directory = await _getDownloadDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    await file.writeAsBytes(utf8.encode(csvBuffer.toString()), flush: true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Datei erfolgreich im Downloads-Ordner gespeichert.')),
    );
  }
}
