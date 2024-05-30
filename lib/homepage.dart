import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart/addstoreonly_screen.dart';
import 'firebase_auth.dart';
import 'firebase_login.dart';
import 'einkaufsliste_screen.dart';
import 'addstore_screen.dart';

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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen())
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            FutureBuilder<List<Widget>>(
              future: _buildListTiles(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
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
            FutureBuilder<List<String>>(
              future: getTopStores(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  return Column(
                    children: snapshot.data!.map((storeName) => Text(storeName)).toList(),
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
                  MaterialPageRoute(builder: (context) => AddStoreOnlyScreen()),
                );
              },
              child: Text("Neuen Laden erstellen"),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Widget>> _buildListTiles(BuildContext context) async {
    var querySnapshot = await _firestore.collection('shopping_lists')
                        .where('userId', isEqualTo: uid)
                        .orderBy('createdDate', descending: true)
                        .limit(5)
                        .get();
    
    List<Widget> tiles = [];
    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      var storeSnapshot = await _firestore.collection('stores').doc(data['ladenId']).get();
      var storeData = storeSnapshot.data() as Map<String, dynamic>;
      tiles.add(
        ListTile(
          title: Text(data['name']),
          subtitle: Text('Artikel: ${data['items'].length}, Laden: ${storeData['name']}'), // Ladenname anzeigen
        ),
      );
    }
    return tiles;
  }
    
  Future<String> getUsername() async {
    var doc = await _firestore.collection('userinfos').doc(uid).get();
    return doc.data()?['nickname'] ?? 'not found';
  }

  Future<List<String>> getTopStores() async {
    var stores = await _firestore.collection('stores').get();
    var storeCounts = <String, int>{};

    for (var store in stores.docs) {
      var storeId = store.id;
      var countSnapshot = await _firestore.collection('shopping_lists')
        .where('ladenId', isEqualTo: storeId)
        .count()
        .get();
      
      storeCounts[storeId] = countSnapshot.count!;
    }

    var sortedStores = storeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<String> topStoreNames = [];
    for (var i = 0; i < 3 && i < sortedStores.length; i++) {
      var storeSnapshot = await _firestore.collection('stores').doc(sortedStores[i].key).get();
      var storeData = storeSnapshot.data() as Map<String, dynamic>;
      topStoreNames.add(storeData['name']);
    }

    return topStoreNames;
  }
}
