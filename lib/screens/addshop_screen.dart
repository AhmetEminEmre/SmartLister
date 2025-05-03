import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../objects/shop.dart';
import '../services/shop_service.dart';

class AddStoreScreen extends StatefulWidget {
  final ShopService shopService;

  const AddStoreScreen({
    super.key,
    required this.shopService,
  });

  @override
  _AddStoreScreenState createState() => _AddStoreScreenState();
}


class _AddStoreScreenState extends State<AddStoreScreen> {
  final TextEditingController _storeNameController = TextEditingController();
  String? _selectedImagePath;

  // Map für die Bilder in img2
  final Map<String, String> imageNameToPath = {
    'Bild 1': 'lib/img2/Img1.png',
    'Bild 2': 'lib/img2/Img2.png',
    'Bild 3': 'lib/img2/Img3.png',
    'Bild 4': 'lib/img2/Img4.png',
    'Bild 5': 'lib/img2/Img5.png',
    'Bild 6': 'lib/img2/Img6.png',
    'Bild 7': 'lib/img2/Img7.png',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Neuen Einkaufsladen erstellen",
          style: TextStyle(color: Color.fromARGB(255, 38, 38, 38)),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 40, 40, 40)),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Textfeld für den Namen
            TextField(
              controller: _storeNameController,
              cursorColor: const Color.fromARGB(255, 37, 37, 37),
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                label: RichText(
                  text: TextSpan(
                    text: 'Name',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 46, 46, 46),
                      fontSize: 16,
                    ),
                    children: const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFBDBDBD),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFBDBDBD),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5A462),
                    width: 2,
                  ),
                ),
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 26, 26, 26),
              ),
            ),

            // Dropdown für die Bildauswahl
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedImagePath,
              onChanged: (value) {
                setState(() {
                  _selectedImagePath = value;
                  print('Selected Image Path DROPDOWN: $_selectedImagePath');
                });
              },
              items: imageNameToPath.keys.map((name) {
                return DropdownMenuItem<String>(
                  value: imageNameToPath[name],
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFF212121),
                    ),
                  ),
                );
              }).toList(),
              decoration: InputDecoration(
                label: RichText(
                  text: TextSpan(
                    text: 'Bild auswählen',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 52, 52, 52),
                      fontSize: 16,
                    ),
                    children: const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFBDBDBD),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFBDBDBD),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5A462),
                    width: 2,
                  ),
                ),
              ),
              dropdownColor: Colors.white,
              style: const TextStyle(
                color: Color(0xFF212121),
              ),
            ),

            // BUTTON LADEN HINZUFÜGEN
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_storeNameController.text.isNotEmpty &&
                        _selectedImagePath != null)
                    ? _addStore
                    : null,
                child: const Text(
                  'Laden hinzufügen',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return const Color(0xFFFFD9B3);
                      }
                      return const Color.fromARGB(255, 239, 141, 37);
                    },
                  ),
                  foregroundColor:
                      MaterialStateProperty.all(Colors.white), // Textfarbe
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 16),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  minimumSize: MaterialStateProperty.all(
                    const Size.fromHeight(56),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _addStore() async {
  if (_storeNameController.text.isEmpty || _selectedImagePath == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bitte geben Sie den Namen und ein Bild ein.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final newShop = Einkaufsladen(
    name: _storeNameController.text.trim(),
    imagePath: _selectedImagePath!,
  );

  await widget.shopService.addShop(newShop);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Laden erfolgreich hinzugefügt!'),
      backgroundColor: Colors.green,
    ),
  );

  Navigator.pop(context);
}

}