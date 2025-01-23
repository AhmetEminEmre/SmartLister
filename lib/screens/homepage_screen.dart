import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart/objects/shop.dart';
import 'package:smart/objects/template.dart';
import 'package:smart/screens/shop_screen.dart';
import 'package:smart/objects/productgroup.dart';
import '../objects/itemlist.dart';
import 'addlist_screen.dart';
import 'currencyconverter_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utilities/notificationmanager.dart';
import 'itemslist_screen.dart';
import 'addshop_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'showAllList.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  final Isar isar;

  const HomePage({super.key, required this.isar});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NotificationManager _notificationManager = NotificationManager();
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late Stream<void> _itemListStream;
  late Stream<void> _shopStream;

  List<Einkaufsladen> _topShops = [];
  bool _loadingShops = true;
  final String _username = 'default'; //hier in zukunft namen setzen

  @override
  @override
  void initState() {
    super.initState();
    _notificationManager.initNotification();
    _setupWatchers();
    _fetchTopShops();
  }

  void _setupWatchers() {
    //boardacast as streams caused error "Stream has already been listened to" error
    _itemListStream = widget.isar.itemlists.watchLazy().asBroadcastStream();
    _shopStream = widget.isar.einkaufsladens.watchLazy().asBroadcastStream();

    _itemListStream.listen((_) {
      _fetchLatestItemLists();
      _fetchTopShops();
    });

    _shopStream.listen((_) {
      _fetchTopShops();
    });
  }

  Future<void> _fetchTopShops() async {
    setState(() {
      _loadingShops = true;
    });

    final allShops = await widget.isar.einkaufsladens.where().findAll();

    setState(() {
      _topShops = allShops;
      _loadingShops = false;
    });
  }

  @override
 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      title: const Padding(
        padding: EdgeInsets.only(right: 100.0), // Linkes Padding für den Titel
        child: Text(
          'Guten Tag Herbert!',
          style: TextStyle(
            fontSize: 33,
            color: Color(0xFF222222),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      actions: <Widget>[
          //   IconButton(
          //    icon: const Icon(Icons.add_alert, color: Color(0xFF222222)),
          //    onPressed: () => showNotificationDialog(context),
          //    ),
          //    IconButton(
          //    icon: const Icon(Icons.attach_money, color: Color(0xFF222222)),
          //     onPressed: () {
          //        Navigator.push(
          //          context,
          //          MaterialPageRoute(
          //           builder: (context) => const CurrencyConverterScreen(),
          //           ),
          //      );
          //     },
          //   ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF222222)),
            onPressed: () {
              // settings here in future
            },
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: 2.0), // Abstand unten verringern
              child: Text(
                'Meine Listen',
                style: TextStyle(
                    fontSize: 23,
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
                  icon: const Icon(Icons.add),
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

            //BUTTON ALLE LISTEN ANZEIGEN
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            //   child: ElevatedButton.icon(
            //     onPressed: () {
            //       Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //           builder: (context) => AllListsScreen(isar: widget.isar),
            //         ),
            //       );
            //     },
            //     icon: const Icon(Icons.list),
            //     label: const Text("Alle Listen anzeigen"),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: const Color(0xFF587A6F),
            //       foregroundColor: Colors.white,
            //     ),
            //   ),
            // ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16), // Abstand links und rechts
          child: Row(
            children: _topShops.map((shop) => _buildShopCard(shop)).toList(),
          ),
        ),
      ),

            // BUTTON NEUER LADEN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SizedBox(
                width: double.infinity, // Button über die gesamte Breite
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddStoreScreen(isar: widget.isar),
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
  String imagePath = shop.imagePath ??  'lib/img/default_image.png';
 
  print('Shop: ${shop.name}, Image Path beim Aufrufen: $imagePath'); // Debugging-Print

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
              isar: widget.isar,
            ),
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
                Colors.black.withOpacity(0.3), BlendMode.darken),
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            shop.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2, // Maximal 2 Zeilen
            overflow: TextOverflow.ellipsis, // Text abschneiden oder umbrechen
          ),
        ),
      ),
    ),
  );
}


  Future<List<Itemlist>> _fetchLatestItemLists() async {
    final lists = await widget.isar.itemlists.where().findAll();
    final validLists = lists.where((list) => list.shopId.isNotEmpty).toList();
    validLists.sort((a, b) => b.creationDate.compareTo(a.creationDate));
    return validLists.take(5).toList();
  }

// LISTEN CARDS
  Widget _buildListCard(Itemlist itemlist) {
    String imagePath = itemlist.imagePath ?? 'lib/img/default_image.png';

    List<Map<String, dynamic>> items = itemlist.getItems();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 12.0, vertical: 8.0), // Gleiche Padding wie Buttons
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
                  isar: widget.isar,
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
                      Colors.black.withOpacity(0.1), BlendMode.darken),
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
                              Color.fromARGB(255, 144, 133, 54), // Textfarbe
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

  Future<List<String>> getAllProductGroups(String shopId) async {
    final productGroups = await widget.isar.productgroups
        .filter()
        .storeIdEqualTo(shopId)
        .sortByOrder()
        .findAll();

    return productGroups.map((group) => group.name.trim()).toList();
  }

  Future<String> getGroupName(String groupId) async {
    final productGroup = await widget.isar.productgroups
        .filter()
        .idEqualTo(int.parse(groupId))
        .findFirst();
    return productGroup?.name ?? "Unbekannt";
  }

  Future<String> getShopName(String groupId) async {
    if (groupId.isEmpty) {
      return "Unbekannt";
    }

    final parsedGroupId = int.tryParse(groupId);
    if (parsedGroupId == null) {
      return "Unbekannt";
    }

    final shop = await widget.isar.einkaufsladens
        .filter()
        .idEqualTo(parsedGroupId)
        .findFirst();
    if (shop != null) {
      return shop.name;
    } else {
      return "Unbekannt";
    }
  }

  void _renameList(Itemlist itemlist) {
    TextEditingController nameController =
        TextEditingController(text: itemlist.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Listennamen ändern'),
          content: TextField(
            controller: nameController,
            decoration:
                const InputDecoration(hintText: 'Neuer Listennamen eingeben'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Speichern'),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  itemlist.name = nameController.text.trim();
                  await widget.isar.writeTxn(() async {
                    await widget.isar.itemlists.put(itemlist);
                  });
                  Navigator.of(context).pop();
                  setState(() {
                    _fetchLatestItemLists();
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteList(Itemlist itemlist) async {
    await widget.isar.writeTxn(() async {
      await widget.isar.itemlists.delete(itemlist.id);
    });

    setState(() {
      _fetchLatestItemLists();
      _fetchTopShops();
    });
  }

  void _saveListAsTemplate(Itemlist itemlist) async {
    final newTemplate = Template(
      name: itemlist.name,
      items: itemlist.getItems(),
      imagePath: itemlist.imagePath!,
      storeId: itemlist.shopId,
    );

    await widget.isar.writeTxn(() async {
      await widget.isar.templates.put(newTemplate);
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Liste als Vorlage gespeichert!'),
    ));
  }

  void _createListDialog(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateListScreen(isar: widget.isar),
      ),
    );

    if (result == true) {
      setState(() {
        _fetchLatestItemLists();
      });
    }
  }

  Future<void> showNotificationDialog(BuildContext context) async {
    TextEditingController titleController = TextEditingController();

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        DateTime scheduledDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Titel eingeben"),
              content: TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: "Titel"),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Abbrechen"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text("Benachrichtigung planen"),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _notificationManager.scheduleNotification(
                      0, //id
                      titleController.text.isEmpty
                          ? "nothing entered notification"
                          : titleController.text,
                      "notification", //body
                      scheduledDateTime,
                    );
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }
}
