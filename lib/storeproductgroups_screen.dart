import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart/addstoreonly_screen.dart';
import 'homepage.dart';

class EditStoreScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final bool isNewStore;

  EditStoreScreen(
      {required this.storeId,
      required this.storeName,
      this.isNewStore = false});

  @override
  _EditStoreScreenState createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, String>> defaultProductGroups = [
    {'name': 'Obst & Gemüse'},
    {'name': 'Säfte'},
    {'name': 'Fleisch'},
    {'name': 'Fischprodukte'}
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isNewStore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptAddDefaultProductGroups();
      });
    }
  }

  void _promptAddDefaultProductGroups() {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Standardwarengruppen"),
          content: Text(
              "Wollen Sie Standardwarengruppen zu diesem Laden hinzufügen?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addDefaultProductGroups();
              },
              child: Text('Ja'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Nein'),
            ),
          ],
        );
      },
    );
  }

  void _showAddProductGroupDialog() {
    TextEditingController groupNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Warengruppe hinzufügen'),
          content: TextField(
            controller: groupNameController,
            decoration: InputDecoration(hintText: 'Warengruppe Name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                if (groupNameController.text.isNotEmpty) {
                  _addProductGroup(groupNameController.text);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Hinzufügen'),
            ),
          ],
        );
      },
    );
  }

  void _addProductGroup(String name) {
    DocumentReference ref = _firestore
        .collection('product_groups')
        .doc(); 
    ref.set({
      'id': ref.id, 
      'name': name,
      'storeId': widget.storeId,
    });
  }

  void _addDefaultProductGroups() {
    for (var group in defaultProductGroups) {
      DocumentReference ref = _firestore
          .collection('product_groups')
          .doc(); 
      ref.set({
        'id': ref.id, 
        'name': group['name'],
        'storeId': widget.storeId,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName), 
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('product_groups')
                  .where('storeId', isEqualTo: widget.storeId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Something went wrong");
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                List<DocumentSnapshot> documents = snapshot.data!.docs;
                return ListView(
                  children: documents.map((doc) {
                    return ListTile(
                      title: Text(doc['name']),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductGroupDialog,
        child: Icon(Icons.add),
        tooltip: 'Warengruppe hinzufügen',
      ),
    );
  }
}
