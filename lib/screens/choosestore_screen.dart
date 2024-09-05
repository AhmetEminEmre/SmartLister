// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'itemslist_screen.dart';
// import '../objects/template.dart';

// class StoreScreen extends StatefulWidget {
//   final String listId;
//   final String listName;
//   final String? selectedStoreId;
//   final List<TemplateList> items;
//   final Function(String storeId) onStoreSelected;

//   StoreScreen({
//     required this.listId,
//     required this.listName,
//     this.selectedStoreId,
//     required this.items,
//     required this.onStoreSelected,
//   });

//   @override
//   _StoreScreenState createState() => _StoreScreenState();
// }

// class _StoreScreenState extends State<StoreScreen> {
//   String? _selectedStoreId;
//   List<DropdownMenuItem<String>> _storeItems = [];
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   void initState() {
//     super.initState();
//     _selectedStoreId = widget.selectedStoreId;
//     _loadStores();
//   }

//   void _loadStores() async {
//     var snapshot = await _firestore.collection('stores')
//         .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
//         .get();
//     var stores = snapshot.docs.map((doc) => DropdownMenuItem<String>(
//       value: doc.id,
//       child: Text(doc.data()['name'] ?? 'idk laden'),
//     )).toList();

//     setState(() {
//       _storeItems = stores;
//     });
//   }

// @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Einkaufsladen zuordnen", style: TextStyle(color: Colors.white)),
//         backgroundColor: Color(0xFF334B46),
//         iconTheme: IconThemeData(color: Colors.white),
//       ),
//       backgroundColor: Color(0xFF334B46),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             DropdownButton<String>(
//               value: _selectedStoreId,
//               onChanged: (value) {
//                 setState(() {
//                   _selectedStoreId = value;
//                 });
//               },
//               items: _storeItems,
//               hint: Text('Einkaufsladen auswählen', style: TextStyle(color: Colors.white)),
//               dropdownColor: Color(0xFF4A6963),
//               isExpanded: true,
//               style: TextStyle(color: Colors.white),
//               iconEnabledColor: Colors.white,
//             ),
//             SizedBox(height: 20),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: _selectedStoreId != null
//                       ? () {
//                           widget.onStoreSelected(_selectedStoreId!);
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => ItemListScreen(
//                                 listName: widget.listName,
//                                 shoppingListId: widget.listId,
//                                 items: widget.items,
//                                 initialStoreId: _selectedStoreId,
//                               ),
//                             ),
//                           );
//                         }
//                       : null,
//                   icon: Container(
//                     decoration: BoxDecoration(
//                       color: Color(0xFF334B46),
//                       shape: BoxShape.circle,
//                     ),
//                     padding: EdgeInsets.all(6),
//                     child: Icon(Icons.add, size: 16, color: Colors.white),
//                   ),
//                   label: Text(
//                     "Laden zu Liste hinzufügen",
//                     style: TextStyle(fontSize: 20, color: Colors.white),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: Colors.white,
//                     backgroundColor: Color(0xFF587A6F),
//                     padding: EdgeInsets.symmetric(vertical: 10),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

