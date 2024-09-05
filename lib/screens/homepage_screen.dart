import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../utilities/notificationmanager.dart';
import '../objects/itemlist.dart';
import '../objects/shop.dart';

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

  @override
  void initState() {
    super.initState();
    _notificationManager.initNotification();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF334B46),
        title: Text(
          'Hallo!',
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
              // Andere Screens hier öffnen, z.B. Währungsrechner
            },
          ),
        ],
      ),
      backgroundColor: Color(0xFF334B46),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FutureBuilder<List<Itemlist>>(
              future:
                  widget.isar.itemlists.where().findAll(), 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Meine Listen",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                      ...snapshot.data!.map((itemlist) {
                        return ListTile(
                          title: Text(itemlist.name),
                          subtitle:
                              Text(itemlist.isDone ? "Erledigt" : "Offen"),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteItemlist(itemlist);
                              } else if (value == 'rename') {
                                _renameItemlist(itemlist, context);
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'rename',
                                child: Text('Liste umbenennen'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Liste löschen'),
                              ),
                            ],
                            icon: Icon(Icons.more_vert),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () => _createListDialog(context),
                icon: Icon(Icons.add),
                label: Text("Neue Einkaufsliste erstellen"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF587A6F), 
                  foregroundColor: Colors.white, //
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                "Meine Lieblingseinkaufsläden",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
            FutureBuilder<List<Einkaufsladen>>(
              future: widget.isar.einkaufsladens
                  .where()
                  .findAll(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 11.0,
                        mainAxisSpacing: 5.0,
                        childAspectRatio: 3,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        var store = snapshot.data![index];
                        return GestureDetector(
                          onTap: () {
                            // Navigiere zum edit
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              padding: EdgeInsets.all(2),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF567760),
                                    Color(0xFFB2DCE1)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Text(
                                store.name,
                                style: TextStyle(
                                    fontSize: 20, color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () => _addShopDialog(context),
                icon: Icon(Icons.add),
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

  Future<void> _createListDialog(BuildContext context) async {
    TextEditingController listNameController = TextEditingController();
    final TextEditingController groupIdController =
        TextEditingController(); 

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Neue Liste erstellen"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: listNameController,
                decoration: InputDecoration(hintText: "Listenname"),
              ),
              TextField(
                controller: groupIdController,
                decoration: InputDecoration(hintText: "Gruppen-ID"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Abbrechen"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Erstellen"),
              onPressed: () async {
                if (listNameController.text.isNotEmpty &&
                    groupIdController.text.isNotEmpty) {
                  final newList = Itemlist(
                    name: listNameController.text,
                    isDone: false,
                    groupId: groupIdController.text,
                  );

                  await widget.isar.writeTxn(() async {
                    await widget.isar.itemlists.put(newList);
                  });
                  setState(() {});
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addShopDialog(BuildContext context) async {
    TextEditingController shopNameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Neuen Laden hinzufügen"),
          content: TextField(
            controller: shopNameController,
            decoration: InputDecoration(hintText: "Ladenname"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Abbrechen"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Hinzufügen"),
              onPressed: () async {
                if (shopNameController.text.isNotEmpty) {
                  final newShop = Einkaufsladen(
                    name: shopNameController.text, 
                    userId: 'someUserId',
                  );

                  await widget.isar.writeTxn(() async {
                    await widget.isar.einkaufsladens.put(newShop);
                  });
                  setState(() {});
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItemlist(Itemlist itemlist) async {
    await widget.isar.writeTxn(() async {
      await widget.isar.itemlists.delete(itemlist.id);
    });
    setState(() {});
  }

  Future<void> _renameItemlist(Itemlist itemlist, BuildContext context) async {
    TextEditingController nameController =
        TextEditingController(text: itemlist.name);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Liste umbenennen"),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(hintText: "Neuer Name"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Abbrechen"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Speichern"),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await widget.isar.writeTxn(() async {
                    itemlist.name = nameController.text;
                    await widget.isar.itemlists.put(itemlist);
                  });
                  setState(() {});
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
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
                      0,
                      titleController.text.isEmpty
                          ? "Standardtitel"
                          : titleController.text,
                      "Benachrichtigungstext",
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
