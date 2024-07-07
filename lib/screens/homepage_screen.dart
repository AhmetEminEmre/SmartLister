import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/firebase_auth.dart';
import 'login_screen.dart';
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
        backgroundColor: Color(0xFF334B46),
        title: FutureBuilder<String>(
          future: getUsername(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Text(
                'Hallo ${snapshot.data}!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            } else {
              return CircularProgressIndicator();
            }
          },
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
                    builder: (context) => CurrencyConverterScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Color(0xFF334B46),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StreamBuilder<List<Widget>>(
              stream: _buildListTiles(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active &&
                    snapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Meine Listen",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ...snapshot.data!
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Text("error");
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreateListScreen()),
                    );
                  },
                  icon: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF334B46),
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                  label: Text('Neue Einkaufsliste erstellen',
                      style: TextStyle(fontSize: 20)),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFF587A6F),
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: getTopStoresStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (snapshot.data != null &&
                      snapshot.data!.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditStoreScreen(
                                        storeId: store['id'],
                                        storeName: store['name'],
                                      ),
                                    ),
                                  );
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
                                          pastelColors[store.hashCode %
                                                  pastelColors.length]
                                              .withOpacity(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Text(
                                      store['name'],
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 8),
                      child: Text(
                        "derzeit keine Lieblingsläden",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddStoreScreen()),
                    );
                  },
                  icon: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF334B46),
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                  label: Text('Neuen Laden erstellen',
                      style: TextStyle(fontSize: 20)),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFF587A6F),
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

  // Liste von dunkleren Pastelfarben
  final List<Color> pastelColors = [
    Color(0xFFDFC7B5), // Dunkleres Pastellorange
    Color(0xFFB2DCE1), // Dunkleres Pastellblau
    Color(0xFFB2E7D1), // Dunkleres Pastellgrün
    Color(0xFFDAC3E1), // Dunkleres Pastelllila
    Color(0xFFF3C2C4), // Dunkleres Pastellrosa
  ];

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
      tz.TZDateTime.from(scheduledTime, tz.local),
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
      var usableLists = snapshot.docs.where((doc) {
        return doc.data().containsKey('ladenId') &&
            doc.data()['ladenId'] != null;
      }).toList();

      usableLists =
          usableLists.length > 5 ? usableLists.sublist(0, 5) : usableLists;

      return usableLists.map((doc) {
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
              String imagePath = data['imagePath'] ?? 'lib/img/default_image.png';

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemListScreen(
                        listName: data['name'],
                        shoppingListId: doc.id,
                      ),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: pastelColors[doc.id.hashCode % pastelColors.length],
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: AssetImage(imagePath),
                        fit: BoxFit.contain,
                        alignment: Alignment.centerRight,
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.2), BlendMode.darken),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'],
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.yellow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${data['items'].length} Artikel',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            SizedBox(width: 2),
                            Container(
                              //margin: EdgeInsets.only(top: 8),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                storeData['name'],
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteShoppingList(doc.id, context);
                              } else if (value == 'rename') {
                                _renameShoppingList(
                                    doc.id, data['name'], context);
                              } else if (value == 'saveAsTemplate') {
                                _saveListAsTemplate(
                                    doc.id,
                                    data['name'],
                                    data['ladenId'],
                                    imagePath,
                                    data['items'],
                                    context);
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
                        ),
                      ],
                    ),
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
//