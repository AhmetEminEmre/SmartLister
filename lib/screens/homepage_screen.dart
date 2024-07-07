import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/firebase_auth.dart';
import '../database/firebase_login.dart';
import 'addlist_screen.dart';
import 'itemslist_screen.dart';
import 'addstore_screen.dart';
import 'shop_screen.dart';
import 'currencyconverter_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../utilities/notificationmanager.dart';

class HomePage extends StatelessWidget {
  final String uid;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationManager _notificationManager = NotificationManager();
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  HomePage({required this.uid}) {
    _notificationManager.initNotification();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: FutureBuilder<String>(
          future: getUsername(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Text('Hallo ${snapshot.data}!');
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add_alert),
            onPressed: () => showNotificationDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.attach_money),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CurrencyConverterScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => LoginScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<List<Widget>>(
              stream: _buildListTiles(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active &&
                    snapshot.hasData) {
                  return Column(children: snapshot.data!);
                } else if (snapshot.hasError) {
                  return Text("error");
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateListScreen()),
                );
              },
              child: Text("Neue Einkaufsliste erstellen"),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: getTopStoresStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (snapshot.data != null &&
                      snapshot.data!.isNotEmpty) {
                    return Column(
                      children: snapshot.data!
                          .map((store) => ListTile(
                                title: Text(store['name']),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => EditStoreScreen(
                                              storeId: store['id'],
                                              storeName: store['name'])));
                                },
                              ))
                          .toList(),
                    );
                  } else {
                    return Text("No stores found.");
                  }
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddStoreScreen()),
                );
              },
              child: Text("Neuen Laden erstellen"),
            ),
          ],
        ),
      ),
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
              title: Text("Benachrichtigungstitel eingeben"),
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
                          ? "Geplante Benachrichtigung"
                          : titleController.text,
                      "Dies ist eine geplante Benachrichtigung",
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

  void _pickDateTime(
      BuildContext dialogContext, TextEditingController titleController) async {
    DateTime? pickedDate = await showDatePicker(
      context: dialogContext,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: dialogContext,
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

        await _notificationManager.scheduleNotification(
          0,
          titleController.text.isEmpty
              ? "Geplante Benachrichtigung"
              : titleController.text,
          "Dies ist eine geplante Benachrichtigung",
          scheduledDateTime,
        );
        titleController.clear();
      }
    }
  }

  Future<void> scheduleNotification(
      int id, String title, String body, DateTime scheduledTime) async {
    var androidDetails = AndroidNotificationDetails(
      'scheduled_channel_id',
      'scheduled_channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    var iOSDetails = DarwinNotificationDetails();
    var platformDetails =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime,
          tz.local), 
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Stream<List<Widget>> _buildListTiles(BuildContext context) {
    return _firestore
        .collection('shopping_lists')
        .where('userId', isEqualTo: uid)
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snapshot) {
      var useablelists = snapshot.docs.where((doc) {
        return doc.data().containsKey('ladenId') &&
            doc.data()['ladenId'] != null;
      }).toList();

      useablelists =
          useablelists.length > 5 ? useablelists.sublist(0, 5) : useablelists;

      return useablelists.map((doc) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>;
        Future<DocumentSnapshot> storeSnapshot =
            _firestore.collection('stores').doc(data['ladenId']).get();
        return FutureBuilder<DocumentSnapshot>(
          future: storeSnapshot,
          builder: (context, storeSnapshot) {
            if (storeSnapshot.connectionState == ConnectionState.done &&
                storeSnapshot.hasData &&
                storeSnapshot.data!.exists) {
              Map<String, dynamic>? storeData =
                  storeSnapshot.data?.data() as Map<String, dynamic>;

              String imagePath =
                  data['imagePath'] ?? 'lib/img/default_image.png';
              print(imagePath);

              return ListTile(
                title: Text(data['name']),
                subtitle: Text(
                    'Artikel: ${data['items'].length}, Laden: ${storeData['name']}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemListScreen(
                        listName: data['name'],
                        shoppingListsId: doc.id,
                      ),
                    ),
                  );
                },
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteShoppingList(doc.id, context);
                    } else if (value == 'rename') {
                      _renameShoppingList(doc.id, data['name'], context);
                    } else if (value == 'saveAsTemplate') {
                      _saveListAsTemplate(doc.id, data['name'], data['ladenId'],
                          imagePath, data['items'], context);
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
                    const PopupMenuItem<String>(
                      value: 'saveAsTemplate',
                      child: Text('Liste als Vorlage speichern'),
                    ),
                  ],
                ),
                tileColor: Colors.transparent,
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(imagePath),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              );
            } else {
              return SizedBox.shrink();
            }
          },
        );
      }).toList();
    });
  }

  void _deleteShoppingList(String listId, BuildContext context) async {
    try {
      await _firestore.collection('shopping_lists').doc(listId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Einkaufsliste gelöscht'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fehler beim Löschen der Liste'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _renameShoppingList(
      String listId, String currentName, BuildContext context) async {
    TextEditingController _nameController =
        TextEditingController(text: currentName);
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
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Speichern'),
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  await _firestore
                      .collection('shopping_lists')
                      .doc(listId)
                      .update({'name': _nameController.text.trim()});
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Listennamen aktualisiert'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _saveListAsTemplate(String listId, String name, String storeId,
      String imagePath, List<dynamic> items, BuildContext context) async {
    var templateRef = _firestore.collection('list_templates').doc();
    await templateRef.set({
      'id': templateRef.id,
      'name': name,
      'ladenId': storeId,
      'items': items,
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'imagePath': imagePath,
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Liste als Vorlage gespeichert!'),
        backgroundColor: Colors.green));
  }

  Future<String> getUsername() async {
    var doc = await _firestore.collection('userinfos').doc(uid).get();
    return doc.data()?['nickname'] ?? 'not found';
  }

  Stream<List<Map<String, dynamic>>> getTopStoresStream() {
    return _firestore
        .collection('shopping_lists')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      var storeCounts = <String, int>{};
      for (var doc in snapshot.docs) {
        var ladenId = doc.data()['ladenId'];
        if (ladenId != null) {
          storeCounts[ladenId] = (storeCounts[ladenId] ?? 0) + 1;
        }
      }
      var sortedStores = storeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      sortedStores = sortedStores.take(3).toList();

      return sortedStores;
    }).asyncMap((sortedStores) async {
      List<Map<String, dynamic>> topStores = [];
      for (var entry in sortedStores) {
        var storeDoc =
            await _firestore.collection('stores').doc(entry.key).get();
        if (storeDoc.exists) {
          topStores.add({
            'id': storeDoc.id,
            'name': storeDoc.data()?['name'],
          });
        }
      }
      return topStores;
    });
  }
}
