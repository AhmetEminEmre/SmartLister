import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart/screens/itemslist_screen.dart';
import '../objects/itemlist.dart'; // Your Isar model for Itemlist
import '../objects/template.dart'; // Your Isar model for Template
import 'choosestore_screen.dart'; // Screen to choose stores

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
  List<Map<String, dynamic>> _items = [];
  String? _selectedStoreId;
  String? _selectedImagePath;

  final Map<String, String> imageNameToPath = {
    'Fahrrad': 'lib/img/bild1.png',
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

  // Load templates from Isar database
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

  // Apply the selected template
  Future<void> _applyTemplate(String templateId) async {
    final template = await widget.isar.templates
        .where()
        .idEqualTo(int.parse(templateId))
        .findFirst();

    if (template != null) {
      _listNameController.text = template.name;
      _selectedImagePath = template.imagePath;

      setState(() {
        _items = template.getItems();
        _selectedTemplateId = templateId;
        _selectedStoreId =
            template.storeId; // Ensure storeId is set from template
      });
    }
  }

  Future<void> _createList() async {
    if (_listNameController.text.trim().isEmpty ||
        _listNameController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Der Name der Einkaufsliste muss mindestens 3 Zeichen lang sein.'),
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

    try {
      // Erstelle neue Liste ohne `groupId`
      final newList = Itemlist(
        name: _listNameController.text.trim(),
        groupId: "", // `groupId` wird später festgelegt
        imagePath: _selectedImagePath!,
      );

      await widget.isar.writeTxn(() async {
        await widget.isar.itemlists.put(newList);
      });

      // Speichere die ID der neuen Liste
      final listId = newList.id.toString();

      // Navigiere zum StoreScreen, um einen Store auszuwählen
      final selectedStoreId = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => StoreScreen(
            listId: listId,
            listName: newList.name,
            isar: widget.isar,
            onStoreSelected: (storeId) {
              return storeId; // Store ID zurückgeben
            },
          ),
        ),
      );

      // Prüfe, ob ein Store ausgewählt wurde
      if (selectedStoreId != null) {
        // Aktualisiere die `groupId` der Liste mit dem ausgewählten Store
        newList.groupId = selectedStoreId;

        await widget.isar.writeTxn(() async {
          await widget.isar.itemlists.put(newList); // Liste aktualisieren
        });

        // Navigiere zur ItemListScreen mit der aktualisierten Liste
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ItemListScreen(
              listName: newList.name,
              shoppingListId: listId,
              items: [newList],
              initialStoreId: selectedStoreId,
              isar: widget.isar,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error creating the list: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fehler beim Erstellen der Liste.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Neue Einkaufsliste erstellen"),
        backgroundColor: Color(0xFF334B46),
      ),
      backgroundColor: Color(0xFF334B46),
      body: Padding(
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
              dropdownColor: Color(0xFF4A6963),
              onChanged: (value) {
                if (value != null) _applyTemplate(value);
              },
              items: _templateItems,
              hint: Text('Vorlage auswählen',
                  style: TextStyle(color: Colors.white)),
              isExpanded: true,
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedImagePath != null
                  ? imagePathToName[_selectedImagePath]
                  : null,
              dropdownColor: Color(0xFF4A6963),
              onChanged: (value) {
                setState(() {
                  _selectedImagePath = imageNameToPath[value!]!;
                });
              },
              items: imageNameToPath.keys.map((name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(name, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              hint:
                  Text('Bild auswählen', style: TextStyle(color: Colors.white)),
              isExpanded: true,
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
