import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'addstore_screen.dart';
import 'itemslist_screen.dart';

class CreateListScreen extends StatefulWidget {
  @override
  _CreateListScreenState createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final _listNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  void _createList() async {
    if (_listNameController.text.trim().isEmpty || _listNameController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Der Name der Einkaufsliste muss mindestens 3 Zeichen lang sein.'))
      );
      return;
    }

    var newListRef = _firestore.collection('shopping_lists').doc();
    await newListRef.set({
      'id': newListRef.id,
      'name': _listNameController.text.trim(),
      'userId': currentUser?.uid,
      'items': [],
      'createdDate': FieldValue.serverTimestamp()
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => StoreScreen(listId: newListRef.id, listName: _listNameController.text.trim())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Neue Einkaufsliste erstellen"),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _listNameController,
              decoration: InputDecoration(
                labelText: 'Name der Einkaufsliste',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createList,
              child: Text('Einkaufsliste erstellen und Laden zuordnen'),
            ),
          ],
        ),
      ),
    );
  }
}