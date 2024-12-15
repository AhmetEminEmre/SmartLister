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
  String _username = 'default'; //hier in zukunft namen setzen

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF334B46),
        title: const Text(
          'Hallo xxxx!',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_alert, color: Colors.white),
            onPressed: () => showNotificationDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.attach_money, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CurrencyConverterScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // settings here in future
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF334B46),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Meine Listen',
                style: TextStyle(fontSize: 18, color: Colors.white),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Meine Lieblingseinkaufsläden',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            _loadingShops
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal, // Horizontal Scrollbar
                    child: Row(
                      children: _topShops.map((shop) {
                        return GestureDetector(
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
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Chip(
                              label: Text(shop.name),
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: ElevatedButton.icon(
                onPressed: () => _createListDialog(context),
                icon: const Icon(Icons.add),
                label: const Text("Neue Einkaufsliste erstellen"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF587A6F),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                label: const Text("Neuen Laden erstellen"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF587A6F),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
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

  Widget _buildListCard(Itemlist itemlist) {
    String imagePath = itemlist.imagePath ?? 'lib/img/default_image.png';

    List<Map<String, dynamic>> items = itemlist.getItems();

    return InkWell(
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4), BlendMode.darken),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemlist.name,
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTag('${items.length} Artikel'),
                    const SizedBox(width: 5),
                    FutureBuilder<String>(
                      future: getShopName(itemlist.shopId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          return _buildTag(snapshot.data!);
                        } else {
                          return _buildTag("Unbekannt");
                        }
                      },
                    ),
                    const Spacer(),
                    _buildOptionsMenu(itemlist),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white),
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
      directory =
          Directory(newPath);
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
      directory = Directory(
          '${directory.path}/Downloads');
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
