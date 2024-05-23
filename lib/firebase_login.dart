import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_auth.dart';
import 'homepage.dart';
import 'nickname.dart';
import 'firebase_register.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Login"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              User? user = await _authService.signInWithEmailAndPassword(
                _emailController.text,
                _passwordController.text,
              );
              if (user != null) {
                bool hasNick = await _authService.hasNickname(user.uid);
                if (!hasNick) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NicknameEntryScreen()));
                } else {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomePage(uid: user.uid)));
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Login fehlgeschlagen!')));
              }
            },
            child: Text('Login'),
          ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (_emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Bitte geben Sie eine E-Mail-Adresse ein.'),
                  backgroundColor: Colors.red,
                ));
              } else {
                _authService.resetPassword(_emailController.text).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Passwort-Reset Mail gesendet!')));
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Fehler beim Senden der E-Mail.')));
                });
              }
            },
            child: Text('Passwort vergessen?'),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterScreen()),
              );
            },
            child: Text("Noch keinen Account? Registrieren"),
          ),
        ],
      ),
    );
  }
}
