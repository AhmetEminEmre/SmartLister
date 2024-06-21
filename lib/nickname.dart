import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_auth.dart';
import 'homepage.dart';

class NicknameEntryScreen extends StatelessWidget {
  final TextEditingController _nicknameController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Set Your Nickname"),
      ),
      body: Column(
        children: <Widget>[
          TextField(
            controller: _nicknameController,
            decoration: InputDecoration(labelText: "Enter your nickname"),
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
