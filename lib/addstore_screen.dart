import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'itemslist_screen.dart';
import 'addstoreonly_screen.dart';



class StoreScreen extends StatefulWidget {
  final String listId;
  final String listName;

  StoreScreen({required this.listId, required this.listName});

  @override
  _StoreScreenState createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String? _selectedStoreId;
  List<DropdownMenuItem<String>> _storeItems = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  void _loadStores() async {
    var snapshot = await _firestore.collection('stores').get();
    var stores = snapshot.docs.map((doc) => DropdownMenuItem<String>(
      value: doc.id,
      child: Text(doc.data()['name'] as String),
    )).toList();

    setState(() {
      _storeItems = stores;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Einkaufsladen zuordnen"),
      ),
      body: Column(
        children: <Widget>[
          DropdownButton<String>(
            value: _selectedStoreId,
            onChanged: (value) {
              setState(() {
                _selectedStoreId = value;
              });
            },
            items: _storeItems,
            hint: Text('Einkaufsladen auswählen'),
            isExpanded: true,
          ),
          ElevatedButton(
            onPressed: _selectedStoreId != null ? () {
              _firestore.collection('shopping_lists').doc(widget.listId).update({
                'ladenId': _selectedStoreId
              });
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ItemListScreen(listName: widget.listName, shoppingListsId: widget.listId)),
              );
            } : null,
            child: Text('Laden zu Liste hinzufügen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddStoreScreen()),
              ).then((_) => _loadStores()); 
            },
            child: Text('Neuen Laden erstellen'),
          ),
        ],
      ),
    );
  }
}
