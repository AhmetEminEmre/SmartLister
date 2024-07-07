import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart/database/firebase_login.dart';
import 'firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registrieren"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Passwort'),
            ),
            ElevatedButton(
              onPressed: () async {
                User? user = await _authService.registerWithEmailAndPassword(
                    _emailController.text, _passwordController.text);
                if (user != null) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => LoginScreen()));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Registrierung erfolgreich! Bitte loggen Sie sich ein.'),
                    backgroundColor: Colors.green,
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Registrierung fehlgeschlagen!'),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              child: Text('Registrieren'),
            ),
          ],
        ),
      ),
    );
  }
}
