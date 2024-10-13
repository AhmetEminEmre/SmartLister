import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart/screens/choosestore_screen.dart'; // Stelle sicher, dass der korrekte Pfad verwendet wird
import 'package:smart/screens/itemslist_screen.dart'; // Verwende diesen Screen nach der Store-Auswahl
import '../objects/itemlist.dart'; // Dein Isar-Modell für Itemlist
import '../objects/template.dart'; // Dein Isar-Modell für Template

class CreateListScreen extends StatefulWidget {
  final Isar isar;

  CreateListScreen({required this.isar});

  @override
  _CreateListScreenState createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final TextEditingController _listNameController = TextEditingController();
  List<DropdownMenuItem<String>> _templateItems = [];
  String? _selectedTemplateId;
  String? _selectedStoreId;
  String? _selectedImagePath;
  List<Map<String, dynamic>> _items = [];

final Map<String, String> imageNameToPath = {
    'Fahrrad ': 'lib/img/bild1.png',
    'Einkaufswagerl': 'lib/img/bild2.png',
    'Fleisch/Fisch': 'lib/img/bild3.png',
    'Euro': 'lib/img/bild4.png',
    'Kaffee': 'lib/img/bild5.png',
  };

  final Map<String, String> imagePathToName = {
    'lib/img/bild1.png': 'Fahrrad',
    'lib/img/bild2.png': 'Einkaufswagerl',
    'lib/img/bild3.png': 'Fleisch/Fisch',
    'lib/img/bild4.png': 'Euro',
    'lib/img/bild5.png': 'Kaffee',
  };

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await widget.isar.templates.where().findAll();
    setState(() {
      _templateItems = templates.map((template) {
        return DropdownMenuItem<String>(
          value: template.id.toString(),
          child: Text(template.name),
        );
      }).toList();
    });
  }

  Future<void> _applyTemplate(String templateId) async {
    final template = await widget.isar.templates
        .where()
        .idEqualTo(int.parse(templateId))
        .findFirst();

    if (template != null) {
      _listNameController.text = template.name;
      _selectedImagePath = template.imagePath;
      _items = template.getItems();

      setState(() {
        _selectedTemplateId = templateId;
      });
    }
  }

  Future<void> _createList() async {
    if (_listNameController.text.trim().isEmpty ||
        _listNameController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Der Name der Einkaufsliste muss mindestens 3 Zeichen lang sein.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (_selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bitte wählen Sie ein Bild aus.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final newList = Itemlist(
      name: _listNameController.text.trim(),
      groupId: '', // `groupId` wird später festgelegt
      imagePath: _selectedImagePath!,
      items: _items,
    );

    await widget.isar.writeTxn(() async {
      await widget.isar.itemlists.put(newList);
    });

    // Weiterleitung zum ChooseStoreScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreScreen(
          listId: newList.id.toString(),
          listName: newList.name,
          isar: widget.isar,
          onStoreSelected: (selectedStoreId) {
            newList.groupId = selectedStoreId; // Setze den Store
            widget.isar.writeTxn(() async {
              await widget.isar.itemlists.put(newList);
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ItemListScreen(
                  listName: newList.name,
                  shoppingListId: newList.id.toString(),
                  items: [newList],
                  initialStoreId: selectedStoreId,
                  isar: widget.isar,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Neue Einkaufsliste erstellen"),
        backgroundColor: Color(0xFF334B46),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _listNameController,
              decoration: InputDecoration(
                labelText: 'Name der Einkaufsliste',
                filled: true,
                fillColor: Color(0xFF4A6963),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedTemplateId,
              onChanged: (value) {
                if (value != null) _applyTemplate(value);
              },
              items: _templateItems,
              hint: Text('Vorlage auswählen', style: TextStyle(color: Colors.white)),
              isExpanded: true,
              dropdownColor: Color(0xFF4A6963),
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedImagePath,
              onChanged: (value) {
                setState(() {
                  _selectedImagePath = value;
                });
              },
              items: imageNameToPath.keys.map((name) {
                return DropdownMenuItem<String>(
                  value: imageNameToPath[name],
                  child: Text(name, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              hint: Text('Bild auswählen', style: TextStyle(color: Colors.white)),
              isExpanded: true,
              dropdownColor: Color(0xFF4A6963),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _createList,
              icon: Icon(Icons.add),
              label: Text('Neue Einkaufsliste erstellen'),
              
            ),
          ],
        ),
      ),
    );
  }
}
