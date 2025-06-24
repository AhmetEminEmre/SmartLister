import 'package:flutter/material.dart';
import '../objects/shop.dart';
import '../services/shop_service.dart';
import 'package:provider/provider.dart';
import 'package:smart/font_scaling.dart';

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

  final Map<String, String> imageNameToPath = {
    'Obst & Gemüse': 'lib/img2/Img1.png',
    'Backwaren': 'lib/img2/Img2.png',
    'Tierbedarf': 'lib/img2/Img3.png',
    'Drogerie': 'lib/img2/Img4.png',
    'Haushalt': 'lib/img2/Img5.png',
    'Werkzeug': 'lib/img2/Img6.png',
    'Garten': 'lib/img2/Img7.png',
  };

  @override
  void initState() {
    super.initState();
    _selectedImagePath = imageNameToPath.values.first;
  }

  @override
  Widget build(BuildContext context) {
    final scaling = context.watch<FontScaling>().factor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Neuen Einkaufsladen erstellen",
          style: TextStyle(
            color: Color.fromARGB(255, 38, 38, 38),
            fontSize: 22 * scaling,
          ),
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
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                label: RichText(
                  text: TextSpan(
                    text: 'Name',
                    style: TextStyle(
                      color: Color.fromARGB(255, 46, 46, 46),
                      fontSize: 16 * scaling,
                    ),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16 * scaling,
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
              style: TextStyle(
                color: Color.fromARGB(255, 26, 26, 26),
                fontSize: 16 * scaling,
              ),
            ),

            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedImagePath,
              onChanged: (value) {
                setState(() {
                  _selectedImagePath = value;
                });
              },
              items: imageNameToPath.keys.map((name) {
                return DropdownMenuItem<String>(
                  value: imageNameToPath[name],
                  child: Text(
                    name,
                    style: TextStyle(
                      color: Color(0xFF212121),
                      fontSize: 16 * scaling,
                    ),
                  ),
                );
              }).toList(),
              decoration: InputDecoration(
                label: RichText(
                  text: TextSpan(
                    text: 'Bild auswählen',
                    style: TextStyle(
                      color: Color.fromARGB(255, 52, 52, 52),
                      fontSize: 16 * scaling,
                    ),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16 * scaling,
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
              style: TextStyle(
                color: Color(0xFF212121),
                fontSize: 16 * scaling,
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_storeNameController.text.isNotEmpty &&
                        _selectedImagePath != null)
                    ? _addStore
                    : null,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.disabled)) {
                        return const Color(0xFFFFD9B3);
                      }
                      return const Color.fromARGB(255, 239, 141, 37);
                    },
                  ),
                  foregroundColor:
                      WidgetStateProperty.all(Colors.white), // Textfarbe
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 16),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  minimumSize: WidgetStateProperty.all(
                    const Size.fromHeight(56),
                  ),
                ),
                child: const Text(
                  'Laden hinzufügen',
                  style: TextStyle(
                    fontSize: 23, // bleibt fix!
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

    final id = await widget.shopService.addShop(newShop);
    newShop.id = id;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laden erfolgreich hinzugefügt!'),
        backgroundColor: Colors.green,
      ),
    );

    if (mounted) {
      Navigator.pop(context, newShop);
    }
  }
}
