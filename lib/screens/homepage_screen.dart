import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart/objects/shop.dart';
import 'package:smart/objects/template.dart';
import 'package:smart/screens/shop_screen.dart';
import '../objects/itemlist.dart';
import 'addlist_screen.dart';
import 'choosestore_screen.dart';
import 'currencyconverter_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utilities/notificationmanager.dart';
import 'itemslist_screen.dart';
import 'addshop_screen.dart';

class HomePage extends StatefulWidget {
  final Isar isar;

  HomePage({required this.isar});

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


  Future<void> _fetchTopShops() async {
    setState(() {
      _loadingShops = true; // Show loading indicator while fetching
    });

    final allItemLists = await widget.isar.itemlists.where().findAll();
    Map<int, int> shopUsage = {};
    for (var list in allItemLists) {
      final groupId = list.groupId;
      if (groupId != null && int.tryParse(groupId) != null) {
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
        backgroundColor: Color(0xFF334B46),
        title: Text(
          'Hallo xxxx!',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add_alert, color: Colors.white),
            onPressed: () => showNotificationDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.attach_money, color: Colors.white),
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
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Füge deine Einstellungsfunktion hinzu
            },
          ),
        ],
      ),
      backgroundColor: Color(0xFF334B46),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                      return CircularProgressIndicator();
                    }
                  },
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Meine Lieblingseinkaufsläden',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            _loadingShops
                ? Center(child: CircularProgressIndicator())
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
                icon: Icon(Icons.add),
                label: Text("Neue Einkaufsliste erstellen"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF587A6F),
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
                icon: Icon(Icons.add_business),
                label: Text("Neuen Laden erstellen"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF587A6F),
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
    lists.sort((a, b) => b.creationDate.compareTo(a.creationDate));
    return lists.take(5).toList(); // Nur die neuesten fünf Listen anzeigen
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
                  style: TextStyle(fontSize: 20, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildTag('${items.length} Artikel'),
                    SizedBox(width: 5),
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
                    Spacer(),
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.white),
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
      ],
      icon: Icon(Icons.more_vert, color: Colors.white),
    );
  }

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
    TextEditingController _nameController =
        TextEditingController(text: itemlist.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Listennamen ändern'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(hintText: 'Neuer Listennamen eingeben'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Abbrechen'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Speichern'),
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  itemlist.name = _nameController.text.trim();
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

      // Check if any other list uses the same shop
      final remainingLists = await widget.isar.itemlists
          .filter()
          .groupIdEqualTo(itemlist.groupId)
          .findAll();

      // If no other lists are using this shop, delete the shop
      if (remainingLists.isEmpty && itemlist.groupId != null) {
        final parsedGroupId = int.tryParse(itemlist.groupId!);
        if (parsedGroupId != null) {
          await widget.isar.einkaufsladens.delete(parsedGroupId);
        }
      }
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
      storeId: itemlist.groupId!,
    );

    await widget.isar.writeTxn(() async {
      await widget.isar.templates.put(newTemplate);
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
              title: Text("Titel eingeben"),
              content: TextField(
                controller: titleController,
                decoration: InputDecoration(hintText: "Titel"),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text("Abbrechen"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text("Benachrichtigung planen"),
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
