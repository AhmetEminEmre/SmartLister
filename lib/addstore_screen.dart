import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'itemslist_screen.dart';

class AddStoreScreen extends StatefulWidget {
  final String listId;
  final String listName;

  AddStoreScreen({required this.listId, required this.listName});

  @override
  _AddStoreScreenState createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends State<AddStoreScreen> {
  String? _selectedStoreId;
  List<DropdownMenuItem<String>> _storeItems = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _storeNameController = TextEditingController();

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

  _loadStores();
  _storeNameController.clear();
}

  void _assignStoreToList() async {
    if (_selectedStoreId != null) {
      await _firestore.collection('shopping_lists').doc(widget.listId).update({
        'ladenId': _selectedStoreId
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ItemListScreen(listName: widget.listName, shoppingListsId: widget.listId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Einkaufsladen zuordnen"),
      ),
      body: Column(
        children: <Widget>[
          TextField(
            controller: _storeNameController,
            decoration: InputDecoration(
              labelText: 'Neuen Laden hinzufügen',
              suffixIcon: IconButton(
                icon: Icon(Icons.add),
                onPressed: _addStore,
              )
            ),
          ),
          DropdownButton<String>(
            value: _selectedStoreId,
            items: _storeItems,
            onChanged: (value) {
              setState(() {
                _selectedStoreId = value;
              });
            },
            hint: Text('Einkaufsladen auswählen'),
          ),
          ElevatedButton(
            onPressed: _assignStoreToList,
            child: Text('Laden zu Liste hinzufügen'),
          ),
        ],
      ),
    );
  }
}
