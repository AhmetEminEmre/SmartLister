import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_auth.dart';
import 'firebase_login.dart';  // Stellen Sie sicher, dass der LoginScreen importiert wird

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
                  _emailController.text,
                  _passwordController.text,
                );
                if (user != null) {
                  // Registrierung erfolgreich, navigiere zurück zum Login-Screen
                  Navigator.pop(context);  // Entfernt den RegisterScreen vom Stack
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registrierung erfolgreich! Bitte loggen Sie sich ein.')));
                } else {
                  // Registrierung fehlgeschlagen
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registrierung fehlgeschlagen!')));
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
