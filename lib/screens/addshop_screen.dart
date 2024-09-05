// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'shop_screen.dart';

// class AddStoreScreen extends StatefulWidget {
//   @override
//   _AddStoreScreenState createState() => _AddStoreScreenState();
// }

// class _AddStoreScreenState extends State<AddStoreScreen> {
//   final TextEditingController _storeNameController = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Neuen Laden hinzufügen",
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Color(0xFF334B46),
//         iconTheme: IconThemeData(color: Colors.white),
//       ),
//       backgroundColor: Color(0xFF334B46),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment:
//               CrossAxisAlignment.start,
//           children: <Widget>[
//             TextField(
//               controller: _storeNameController,
//               decoration: InputDecoration(
//                 labelText: 'Name des Ladens',
//                 labelStyle: TextStyle(color: Colors.white),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 filled: true,
//                 fillColor:
//                     Color(0xFF4A6963),
//               ),
//               style:
//                   TextStyle(color: Colors.white),
//             ),
//             SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: _addStore,
//                 icon: Container(
//                   decoration: BoxDecoration(
//                     color: Color(0xFF334B46),
//                     shape: BoxShape.circle,
//                   ),
//                   padding: EdgeInsets.all(6),
//                   child: Icon(Icons.add,
//                       size: 16,
//                       color: Colors.white),
//                 ),
//                 label: Text('Laden hinzufügen',
//                     style: TextStyle(fontSize: 20)
//                     ),
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: Colors.white,
//                   backgroundColor:
//                       Color(0xFF587A6F),
//                   padding: EdgeInsets.symmetric(
//                       vertical: 10),
//                   shape: RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius.circular(16),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _addStore() async {
//     if (_storeNameController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Der Name des Einkaufsladens darf nicht leer sein.'),
//         backgroundColor: Colors.red,
//       ));
//       return;
//     }

//     var storeRef = _firestore.collection('stores').doc();
//     await storeRef.set({
//       'name': _storeNameController.text.trim(),
//       'id': storeRef.id,
//       'userId': FirebaseAuth.instance.currentUser?.uid,
//     });

//     Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//             builder: (context) => EditStoreScreen(
//                 storeId: storeRef.id,
//                 storeName: _storeNameController.text.trim(),
//                 isNewStore: true)));
//   }
// }
