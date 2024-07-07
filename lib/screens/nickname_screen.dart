import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/firebase_auth.dart';
import 'homepage_screen.dart';

class NicknameScreen extends StatelessWidget {
  final TextEditingController _nicknameController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text("Nickname"),
        backgroundColor: Color(0xFF334B46),
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
      ),
      backgroundColor: Color(0xFF334B46),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 10),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: 'Nickname eingeben',
                labelStyle: TextStyle(color: Colors.white),
                filled: true,
                fillColor: Color(0xFF587A6F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF587A6F)),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  var user = FirebaseAuth.instance.currentUser;
                  if (user != null && _nicknameController.text.isNotEmpty) {
                    await _authService.saveUserNickname(
                        user.uid, _nicknameController.text);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Nickname gespeichert!'),
                      backgroundColor: Colors.green,
                    ));
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => HomePage(uid: user.uid)));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Bitte geben Sie einen Nickname ein.'),
                      backgroundColor: Colors.red,
                    ));
                  }
                },
                icon: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF334B46),
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.save, size: 16, color: Colors.white),
                ),
                label: Text('Save Nickname', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF587A6F),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
}
