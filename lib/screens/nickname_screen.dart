import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/firebase_auth.dart';
import 'homepage_screen.dart';

class NicknameEntryScreen extends StatelessWidget {
  final TextEditingController _nicknameController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Nicknameeingabe"),
      ),
      body: Column(
        children: <Widget>[
          TextField(
            controller: _nicknameController,
            decoration: InputDecoration(labelText: "Nickname eingeben"),
          ),
          ElevatedButton(
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
            child: Text("Save Nickname"),
          ),
        ],
      ),
    );
  }
}
