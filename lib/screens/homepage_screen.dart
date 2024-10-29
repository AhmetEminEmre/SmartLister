import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart/objects/shop.dart';
import 'package:smart/objects/template.dart';
import 'package:smart/screens/shop_screen.dart';
import 'package:smart/objects/productgroup.dart';
import '../objects/itemlist.dart';
import 'addlist_screen.dart';
import 'choosestore_screen.dart';
import 'currencyconverter_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utilities/notificationmanager.dart';
import 'itemslist_screen.dart';
import 'addshop_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
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

  List<Einkaufsladen> _topShops = []; // Cached top shops
  bool _loadingShops = true; // Loading state for shops

  @override
  void initState() {
    super.initState();
    requestPermissions(); // Request storage permission at startup
    _notificationManager.initNotification();
    _setupWatchers(); // Set up the watchers for real-time updates
    _fetchTopShops(); // Initial load for top shops
  }

  void _setupWatchers() {
    // Convert streams to broadcast streams to avoid the "Stream has already been listened to" error
    _itemListStream = widget.isar.itemlists.watchLazy().asBroadcastStream();
    _shopStream = widget.isar.einkaufsladens.watchLazy().asBroadcastStream();

    // Listen for item list changes and reload shops
    _itemListStream.listen((_) {
      _fetchLatestItemLists();
      _fetchTopShops(); // Reload top shops when item list changes
    });

    // Listen for shop changes and reload shops
    _shopStream.listen((_) {
      _fetchTopShops();
    });
  }


  Future<void> requestPermissions() async {
    final permissions = [
      Permission.storage,
      Permission.manageExternalStorage,
    ];

    for (var permission in permissions) {
      if (await permission.isDenied) {
        final status = await permission.request();
        if (status.isPermanentlyDenied) {
          openAppSettings();
        }
      }
    }
  }

  Future<void> _fetchTopShops() async {
    setState(() {
      _loadingShops = true; // Show loading indicator while fetching
    });

    final allItemLists = await widget.isar.itemlists.where().findAll();
    Map<int, int> shopUsage = {};
    for (var list in allItemLists) {
      final groupId = list.groupId;
      if (int.tryParse(groupId) != null) {
        final int id = int.parse(groupId);
        shopUsage[id] = (shopUsage[id] ?? 0) + 1;
      }
    }

    final sortedGroupIds = shopUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topGroupIds = sortedGroupIds.take(3).map((e) => e.key).toList();

    List<Einkaufsladen> topShops = [];
    for (var groupId in topGroupIds) {
      final shop = await widget.isar.einkaufsladens
          .filter()
          .idEqualTo(groupId)
          .findFirst();
      if (shop != null) {
        topShops.add(shop);
      }
    }

    setState(() {
      _topShops = topShops; // Update the top shops
      _loadingShops = false; // Hide loading indicator
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
                  builder: (context) => CurrencyConverterScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Füge deine Einstellungsfunktion hinzu
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
              stream:
                  _itemListStream, // Listen to the itemlist collection changes
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
                : Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _topShops.map((shop) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditStoreScreen(
                                storeId: shop.id.toString(),
                                storeName: shop.name,
                                isar: widget
                                    .isar, // Passing Isar instance to EditStoreScreen
                              ),
                            ),
                          );
                        },
                        child: Chip(
                          label: Text(shop.name),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }).toList(),
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
    // Alle Listen abrufen
    final lists = await widget.isar.itemlists.where().findAll();

    // Filtere Listen, die eine gültige groupId haben
    final validLists = lists.where((list) => list.groupId.isNotEmpty).toList();

    // Sortiere die Listen nach Erstellungsdatum
    validLists.sort((a, b) => b.creationDate.compareTo(a.creationDate));

    // Nur die neuesten fünf Listen anzeigen
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
              initialStoreId: itemlist.groupId,
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
                      future: getShopName(itemlist.groupId),
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
            exportCsvWithFilePicker(itemlist); // Neue Option hinzufügen
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
          child: Text('Liste exportieren'), // Neue Exportoption
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
      newPath = newPath + "/Download";
      directory = Directory(newPath);
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    return directory;
  }

Future<void> exportCsv(String fileName, List<Map<String, dynamic>> items) async {
  StringBuffer csvBuffer = StringBuffer();

  // Build header and debug it
  csvBuffer.write('name;');
  final productGroups = items.map((item) => item['productGroup']).toSet().toList();
  csvBuffer.writeAll(productGroups, ';');
  csvBuffer.write(';\n');
  print('CSV Header: name;${productGroups.join(";")};'); // Debug the header line

  // Add each item with its group, name, and status
  for (var productGroup in productGroups) {
    final groupItems = items.where((item) => item['productGroup'] == productGroup).toList();
    for (var item in groupItems) {
      final line = '${item['productGroup']};${item['itemName']};${item['status']}';
      csvBuffer.writeln(line);
      print('CSV Line: $line');  // Debug each line
    }
  }

  // Write CSV content to file and save
  final directory = await _getDownloadDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  await file.writeAsString(csvBuffer.toString());
  _showSnackBar('Datei erfolgreich im Downloads-Ordner gespeichert.');
}



   Future<void> _requestPermission(Permission permission) async {
    if (await permission.isDenied) {
      await permission.request();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

Future<void> exportCsvWithFilePicker(Itemlist itemlist) async {
  StringBuffer csvBuffer = StringBuffer();

  final List<dynamic> items = json.decode(itemlist.itemsJson);
  
  final productGroups = items.map((item) => item['groupId']).toSet().toList();
  final headerLine = '${itemlist.name};${productGroups.join(";")};';
  csvBuffer.writeln(headerLine);
  print('Exported line 1: $headerLine'); // Debug header line

  for (var item in items) {
    final line = '${item['groupId']};${item['name']};${item['isDone']}';
    csvBuffer.writeln(line);
    print('Exported line: $line');  // Debug each item line
  }

  final fileName = '${itemlist.name}.csv';
  final bytes = Uint8List.fromList(csvBuffer.toString().codeUnits);
  final result = await saveFileToDownloads(fileName, bytes);

  if (result) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datei erfolgreich im Downloads-Ordner gespeichert.'))
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fehler beim Speichern der Datei.'), backgroundColor: Colors.red)
    );
  }
}






  Future<bool> saveFileToDownloads(String fileName, Uint8List bytes) async {
    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        print('Download directory not available');
        return false;
      }
      final filePath = p.join(directory.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      print('File saved to: $filePath');  // Debugging output
      return true;
    } on Exception catch (e) {
      print('Error saving file to downloads: $e');
      return false;
    }
  }

  Future<Directory?> getDownloadsDirectory() async {
    Directory? directory;
    try {
      if (Platform.isAndroid) {
        directory = (await getExternalStorageDirectory())!;
        String newPath = "";
        List<String> folders = directory.path.split("/");
        for (int x = 1; x < folders.length; x++) {
          String folder = folders[x];
          if (folder != "Android") {
            newPath += "/$folder";
          } else {
            break;
          }
        }
        newPath = newPath + "/Download";
        directory = Directory(newPath);
      } else {
        return null;
      }
      print('Downloads directory: ${directory.path}');  // Debugging output
      return directory;
    } on PlatformException catch (e) {
      print('Failed to get downloads directory: $e');
      return null;
    }
  }

  Future<String?> _findDownloadsDirectory() async {
    final directories = await getExternalStorageDirectories(type: StorageDirectory.downloads);
    return directories?.first.path;
  }

  Future<void> exportFile(Itemlist itemlist) async {
  if (await Permission.manageExternalStorage.isGranted) {
    exportCsvWithFilePicker(itemlist);
    print('Datei wird exportiert.');
  } else {
    print('Speicherberechtigung nicht erteilt. Export wird abgebrochen.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Speicherberechtigung abgelehnt. Bitte Berechtigung in den Einstellungen aktivieren.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}



  Future<void> copyFilePath(String path) async {
    await Clipboard.setData(ClipboardData(text: path));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Dateipfad kopiert!'),
      backgroundColor: Colors.green,
    ));
  }

// final path = '${directory.path}/${itemlist.name}_export.csv';
// await copyFilePath(path);

  Future<String> getShopName(String groupId) async {
    if (groupId.isEmpty) {
      return "Unbekannt"; // Default value for empty group ID
    }

    final parsedGroupId = int.tryParse(groupId);
    if (parsedGroupId == null) {
      return "Unbekannt"; // Return "Unbekannt" if ID is not an integer
    }

    final shop = await widget.isar.einkaufsladens
        .filter()
        .idEqualTo(parsedGroupId)
        .findFirst();
    if (shop != null) {
      return shop.name; // Return shop name if found
    } else {
      return "Unbekannt"; // Return "Unbekannt" if no shop is found
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
                    _fetchLatestItemLists(); // Reload the lists after renaming
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

      // // Check if any other list uses the same shop
      // final remainingLists = await widget.isar.itemlists
      //     .filter()
      //     .groupIdEqualTo(itemlist.groupId)
      //     .findAll();

      // // If no other lists are using this shop, delete the shop
      // if (remainingLists.isEmpty && itemlist.groupId != null) {
      //   final parsedGroupId = int.tryParse(itemlist.groupId!);
      //   if (parsedGroupId != null) {
      //     await widget.isar.einkaufsladens.delete(parsedGroupId);
      //   }
      // }
    });

    setState(() {
      _fetchLatestItemLists(); // Reload the lists after deletion
      _fetchTopShops(); // Reload the top shops after a list deletion
    });
  }

  void _saveListAsTemplate(Itemlist itemlist) async {
    final newTemplate = Template(
      name: itemlist.name,
      items: itemlist.getItems(),
      imagePath: itemlist.imagePath!,
      storeId: itemlist.groupId,
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

    // Prüfe, ob eine neue Liste erstellt wurde, und aktualisiere dann
    if (result == true) {
      setState(() {
        _fetchLatestItemLists(); // Aktualisiere die Itemlisten
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
