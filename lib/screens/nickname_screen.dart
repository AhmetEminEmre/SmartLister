import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../objects/userinfo.dart';
import 'homepage_screen.dart';

class NicknameScreen extends StatefulWidget {
  final Isar isar;

  const NicknameScreen({super.key, required this.isar});

  @override
  _NicknameScreenState createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  Future<void> _saveNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isNotEmpty) {
      final user = Userinfo(nickname: nickname);
      await widget.isar.writeTxn(() async {
        await widget.isar.userinfos.put(user);
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(isar: widget.isar)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: 500,
                child: Image.asset(
                  'lib/img3/NickNameScreen.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20), // Abstand zum Text
              //Text
              const Text(
                "SmartLister",
                style: TextStyle(fontSize: 44, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 7), //Abstand
              const Text(
                "Dein smarter Begleiter\nfür jeden Einkauf",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40), //Abstand

              // Textfield & Button in Padding für besseren Abstand
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        hintText: "Dein Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), //Abstand
                    SizedBox(
                      width: double.infinity, // Button auf volle Breite
                      child: ElevatedButton(
                        onPressed: _saveNickname,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Los geht's",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
