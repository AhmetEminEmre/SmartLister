import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_auth.dart';
import 'main.dart';  // Stellen Sie sicher, dass dies auf die richtigen Dateien verweist
import 'firebase_register.dart';  // Importieren Sie den Registrierungsbildschirm

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
        title: Text("Login"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          SizedBox(height: 8),  // Abstand zwischen den Textfeldern
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          SizedBox(height: 20), // Abstand vor dem Button
          ElevatedButton(
            onPressed: () async {
              User? user = await _authService.signInWithEmailAndPassword(
                _emailController.text,
                _passwordController.text,
              );
              if (user != null) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage(title: 'Flutter Demo Home Page')));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login erfolgreich!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login fehlgeschlagen!')));
              }
            },
            child: Text('Login'),
          ),
          SizedBox(height: 12),  // Abstand nach dem Button
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterScreen()),  // Stellen Sie sicher, dass Sie RegisterScreen definiert haben
              );
            },
            child: Text("Noch keinen Account? Registrieren"),
          ),
        ],
      ),
    );
  }
}
