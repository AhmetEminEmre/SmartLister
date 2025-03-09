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
      appBar: AppBar(
        title: const Text("Nickname eingeben"),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Wie möchtest du genannt werden?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                hintText: "Dein Nickname",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveNickname,
                child: const Text("Speichern"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
