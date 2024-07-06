import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_auth.dart';
import 'firebase_login.dart';
import 'einkaufsliste_screen.dart';
import 'itemslist_screen.dart';
import 'addstoreonly_screen.dart';
import 'storeproductgroups_screen.dart';
import 'currencyconverter.dart';  

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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CurrencyConverterScreen()), 
                );
              },
              child: Text("Währungsrechner öffnen"),
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
        .snapshots()
        .map((snapshot) {
      var useablelists = snapshot.docs.where((doc) {
        return doc.data().containsKey('ladenId') && doc.data()['ladenId'] != null; 
      }).toList();

      useablelists = useablelists.length > 5 ? useablelists.sublist(0, 5) : useablelists;

      return useablelists.map((doc) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>;
        Future<DocumentSnapshot> storeSnapshot =
            _firestore.collection('stores').doc(data['ladenId']).get();
        return FutureBuilder<DocumentSnapshot>(
          future: storeSnapshot,
          builder: (context, storeSnapshot) {
            if (storeSnapshot.connectionState == ConnectionState.done &&
                storeSnapshot.hasData && storeSnapshot.data!.exists) {
              Map<String, dynamic>? storeData =
                  storeSnapshot.data?.data() as Map<String, dynamic>;
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
                          data['items'], context);
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

  void _saveListAsTemplate(String listId, String name, String storeId, List<dynamic> items, BuildContext context) async {
    var templateRef = _firestore.collection('list_templates').doc();
    await templateRef.set({
      'id': templateRef.id,
      'name': name,
      'ladenId': storeId,
      'items': items,
      'userId': FirebaseAuth.instance.currentUser?.uid,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Liste als Vorlage gespeichert!'), 
      backgroundColor: Colors.green)
    );
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
