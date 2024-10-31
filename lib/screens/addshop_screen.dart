import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../objects/shop.dart';
import 'shop_screen.dart';

class AddStoreScreen extends StatefulWidget {
  final Isar isar;

  const AddStoreScreen({super.key, required this.isar});

  @override
  _AddStoreScreenState createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends State<AddStoreScreen> {
  final TextEditingController _storeNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Neuen Laden hinzufügen",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF334B46),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF334B46),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _storeNameController,
              decoration: InputDecoration(
                labelText: 'Name des Ladens',
                labelStyle: const TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: const Color(0xFF4A6963),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addStore,
                icon: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF334B46),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
                label: const Text('Laden hinzufügen', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF587A6F),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addStore() async {
    if (_storeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Der Name des Einkaufsladens darf nicht leer sein.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final newStore = Einkaufsladen(
      name: _storeNameController.text.trim(),
    );

    await widget.isar.writeTxn(() async {
      await widget.isar.einkaufsladens.put(newStore);
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EditStoreScreen(
          storeId: newStore.id.toString(),
          storeName: newStore.name,
          isNewStore: true,
          isar: widget.isar,
        ),
      ),
    );
  }
}
