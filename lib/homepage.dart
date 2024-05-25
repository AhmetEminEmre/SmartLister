import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_auth.dart';
import 'firebase_login.dart';
import 'einkaufsliste_screen.dart';

class HomePage extends StatelessWidget {
  final String uid;
  final AuthService _authService = AuthService();

  HomePage({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: FutureBuilder<String>(
          future: getUsername(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Text('Hallo ${snapshot.data}!');
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut(); 
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen())
              );
            },
          ),
        ],
      ),
       body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateListScreen()),
            );
          },
          child: Text("Neue Einkaufsliste erstellen"),
        ),
      ),
    );
  }

  Future<String> getUsername() async {
    var doc = await FirebaseFirestore.instance.collection('userinfos').doc(uid).get();
    return doc.data()?['nickname'] ?? 'not found';
  }
}
