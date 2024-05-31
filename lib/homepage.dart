import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_auth.dart';
import 'firebase_login.dart';
import 'einkaufsliste_screen.dart';
import 'itemslist_screen.dart';
import 'addstoreonly_screen.dart';
import 'storeproductgroups_screen.dart';

class HomePage extends StatelessWidget {
  final String uid;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  HomePage({required this.uid});

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
            FutureBuilder<List<Map<String, dynamic>>>(
              future: getTopStores(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
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
                                        storeName: store['name']),
                                  ),
                                );
                              },
                            ))
                        .toList(),
                  );
                } else if (snapshot.hasError) {
                  return Text("Fehler beim Laden der Läden");
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

  Stream<List<Widget>> _buildListTiles(BuildContext context) {
  return _firestore
      .collection('shopping_lists')
      .where('userId', isEqualTo: uid)
      .orderBy('createdDate', descending: true)
      .limit(5)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?; 
      if (data == null) {
        return SizedBox(); 
      }
      Future<DocumentSnapshot> storeSnapshot = _firestore.collection('stores').doc(data['ladenId']).get();
      return FutureBuilder<DocumentSnapshot>(
        future: storeSnapshot,
        builder: (context, storeSnapshot) {
          if (storeSnapshot.connectionState == ConnectionState.done && storeSnapshot.hasData) {
            Map<String, dynamic>? storeData = storeSnapshot.data?.data() as Map<String, dynamic>?;
            if (storeData == null) {
              return Text("Store data not found.");
            }
            return ListTile(
              title: Text(data['name']),
              subtitle: Text('Artikel: ${data['items'].length}, Laden: ${storeData['name']}'),
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
                ],
              ),
            );
          } else {
            return SizedBox(); 
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
        backgroundColor: Colors.red,
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

  Future<String> getUsername() async {
    var doc = await _firestore.collection('userinfos').doc(uid).get();
    return doc.data()?['nickname'] ?? 'not found';
  }

  Future<List<Map<String, dynamic>>> getTopStores() async {
    var stores = await _firestore.collection('stores').get();
    var storeCounts = <String, int>{};

    for (var store in stores.docs) {
      var storeId = store.id;
      var countSnapshot = await _firestore
          .collection('shopping_lists')
          .where('ladenId', isEqualTo: storeId)
          .count()
          .get();

      storeCounts[storeId] = countSnapshot.count!;
    }

    var sortedStores = storeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Map<String, dynamic>> topStores = [];
    for (var i = 0; i < 3 && i < sortedStores.length; i++) {
      var storeSnapshot =
          await _firestore.collection('stores').doc(sortedStores[i].key).get();
      var storeData = storeSnapshot.data() as Map<String, dynamic>;
      topStores.add({'id': sortedStores[i].key, 'name': storeData['name']});
    }

    return topStores;
  }
}
