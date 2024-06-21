import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart/addstoreonly_screen.dart';
import 'homepage.dart';
import 'storeproductgroups_screen.dart';

class AddStoreScreen extends StatefulWidget {
  @override
  _AddStoreScreenState createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends State<AddStoreScreen> {
  final TextEditingController _storeNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Neuen Laden hinzufügen"),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _storeNameController,
              decoration: InputDecoration(
                labelText: 'Name des Ladens',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addStore, 
              child: Text('Laden hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }


  void _addStore() async {
    if (_storeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Der Name des Einkaufsladens darf nicht leer sein.'), 
          backgroundColor: Colors.red,)
      );
      return;
    }

    var storeRef = _firestore.collection('stores').doc();
    await storeRef.set({
      'name': _storeNameController.text.trim(),
      'id': storeRef.id,
      'userId': FirebaseAuth.instance.currentUser?.uid, 
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EditStoreScreen(
          storeId: storeRef.id,
          storeName: _storeNameController.text.trim(),
          isNewStore: true
        )
      )
    );
  }
}
