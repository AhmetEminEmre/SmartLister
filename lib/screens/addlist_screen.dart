import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'choosestore_screen.dart';
import '../objects/template.dart';

class CreateListScreen extends StatefulWidget {
  @override
  _CreateListScreenState createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final _listNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<DropdownMenuItem<String>> _templateItems = [];
  String? _selectedTemplateId;
  List<TemplateList> _items = [];
  String? _selectedStoreId;
  String? _selectedImagePath;

  final Map<String, String> imageNameToPath = {
    'Apfel': 'lib/img/bild1.png',
    'Birne': 'lib/img/bild2.png',
    'Banane': 'lib/img/bild3.png',
    'Kiwi': 'lib/img/bild4.png',
    'Ananas': 'lib/img/bild5.png',
  };

  final Map<String, String> imagePathToName = {
    'lib/img/bild1.png': 'Apfel',
    'lib/img/bild2.png': 'Birne',
    'lib/img/bild3.png': 'Banane',
    'lib/img/bild4.png': 'Kiwi',
    'lib/img/bild5.png': 'Ananas',
  };

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  void _loadTemplates() async {
    var snapshot = await _firestore
        .collection('list_templates')
        .where('userId', isEqualTo: currentUser?.uid)
        .get();
    var templates = snapshot.docs
        .map((doc) => DropdownMenuItem<String>(
              value: doc.id,
              child: GestureDetector(
                onLongPress: () =>
                    _confirmDeleteTemplate(doc.id, doc.data()?['name'] ?? ''),
                child: Text(doc.data()?['name'] ?? 'Unbenannte Vorlage'),
              ),
            ))
        .toList();

    setState(() {
      _templateItems = templates;
    });
  }

  void _applyTemplate(String templateId) async {
    var doc =
        await _firestore.collection('list_templates').doc(templateId).get();
    if (doc.exists) {
      var data = doc.data()!;
      _listNameController.text = data['name'];
      _selectedStoreId = data['ladenId'];
      _selectedImagePath = data['imagePath'];

      var groupNames = await _fetchGroupNames();

      var items = List.from(data['items'] as List).map((item) {
        var groupId = item['groupId'];
        var groupName = groupNames[groupId] ?? 'idk2';
        return TemplateList.fromJson({
          'name': item['name'],
          'groupId': groupId,
          'groupName': groupName,
          'isDone': item['isDone'],
          'imagePath': data['imagePath'],
        });
      }).toList();

      setState(() {
        _selectedTemplateId = templateId;
        _items = items;
        _selectedImagePath = data['imagePath'];
      });
    }
  }

//?? gruppennamen krieg ich sonst irgendwie nicht hin
  Future<Map<String, String>> _fetchGroupNames() async {
    var snapshot = await _firestore.collection('product_groups').get();
    var names = <String, String>{};
    for (var doc in snapshot.docs) {
      names[doc.id] = doc.data()['name'] as String;
    }
    return names;
  }

  void _confirmDeleteTemplate(String templateId, String templateName) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Vorlage löschen"),
            content: Text(
                "Möchten Sie die Vorlage '$templateName' wirklich löschen?"),
            actions: <Widget>[
              TextButton(
                child: Text('Abbrechen'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                  child: Text('Löschen'),
                  onPressed: () {
                    _deleteTemplate(templateId);
                    Navigator.of(context).pop();
                  })
            ],
          );
        });
  }

  void _deleteTemplate(String templateId) async {
    await _firestore.collection('list_templates').doc(templateId).delete();
    _loadTemplates();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Vorlage gelöscht'),
      backgroundColor: Colors.green,
    ));
    if (_selectedTemplateId == templateId) {
      setState(() {
        _selectedTemplateId = null;
        _items = [];
        _listNameController.text = '';
      });
    }
  }

  void _createList() async {
    if (_listNameController.text.trim().isEmpty ||
        _listNameController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Der Name der Einkaufsliste muss mindestens 3 Zeichen lang sein.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    var newListRef = _firestore.collection('shopping_lists').doc();
    await newListRef.set({
      'id': newListRef.id,
      'name': _listNameController.text.trim(),
      'userId': currentUser?.uid,
      'items': _items
          .map((item) => {
                'name': item.name,
                'groupId': item.groupId,
                'isDone': item.isDone
              })
          .toList(),
      'createdDate': FieldValue.serverTimestamp(),
      'imagePath': _selectedImagePath
    });

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => StoreScreen(
                listId: newListRef.id,
                listName: _listNameController.text.trim(),
                selectedStoreId: _selectedStoreId,
                items: _items,
                onStoreSelected: (selectedStoreId) {
                  _saveStoreIdToList(newListRef.id, selectedStoreId);
                })));
  }

  void _saveStoreIdToList(String listId, String storeId) async {
    await _firestore
        .collection('shopping_lists')
        .doc(listId)
        .update({'ladenId': storeId});
    if (mounted) {
      Navigator.popUntil(context, ModalRoute.withName('/home'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Neue Einkaufsliste erstellen")),
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
            DropdownButton<String>(
              value: _selectedTemplateId,
              onChanged: (value) {
                if (value != null) _applyTemplate(value);
              },
              items: _templateItems,
              hint: Text('Vorlage auswählen'),
              isExpanded: true,
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedImagePath != null
                  ? imagePathToName[_selectedImagePath]
                  : null,
              onChanged: (value) {
                setState(() {
                  _selectedImagePath = imageNameToPath[value!]!;
                });
              },
              items: imageNameToPath.keys.map((String name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(name),
                );
              }).toList(),
              hint: Text('Bild auswählen'),
              isExpanded: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createList,
              child: Text('Weiter zum Laden zuordnen'),
            ),
          ],
        ),
      ),
    );
  }
}
