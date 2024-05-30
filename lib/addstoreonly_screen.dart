import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart';

class AddStoreOnlyScreen extends StatefulWidget {
  @override
  _AddStoreOnlyScreenState createState() => _AddStoreOnlyScreenState();
}

class _AddStoreOnlyScreenState extends State<AddStoreOnlyScreen> {
  final TextEditingController _storeNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _addStore() async {
    if (_storeNameController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Der Name des Einkaufsladens muss mindestens 3 Zeichen lang sein.'))
      );
      return; 
    }

    var newStoreRef = _firestore.collection('stores').doc();
    await newStoreRef.set({
      'id': newStoreRef.id,
      'name': _storeNameController.text.trim()
    });

    _storeNameController.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage(uid: FirebaseAuth.instance.currentUser!.uid)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Neuen Einkaufsladen hinzufügen"),
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage(uid: FirebaseAuth.instance.currentUser!.uid)),
            );
          },
        ),
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
              child: Text('Einkaufsladen hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
