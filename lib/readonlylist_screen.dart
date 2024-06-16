import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class ReadOnlyListScreen extends StatefulWidget {
  final String listId;

  ReadOnlyListScreen({Key? key, required this.listId}) : super(key: key);

  @override
  _ReadOnlyListScreenState createState() => _ReadOnlyListScreenState();
}

class _ReadOnlyListScreenState extends State<ReadOnlyListScreen> {
  late Future<Map<String, dynamic>> _listDataFuture;
  Map<String, String> _groupNames = {};
  String _userName = '';
  String _listName = '';

  @override
  void initState() {
    super.initState();
    _listDataFuture = loadListData();
  }

  Future<Map<String, dynamic>> loadListData() async {
    try {
      DocumentSnapshot listDoc = await FirebaseFirestore.instance
          .collection('shopping_lists')
          .doc(widget.listId)
          .get();

      if (listDoc.exists && listDoc.data() != null) {
        var data = listDoc.data() as Map<String, dynamic>;
        _listName = data['name'];
        var userDoc = await FirebaseFirestore.instance.collection('userinfos').doc(data['userId']).get();
        _userName = userDoc.data()?['nickname'] ?? 'Unknown User';

        var groupDocs = await FirebaseFirestore.instance.collection('product_groups').get();
        for (var doc in groupDocs.docs) {
          _groupNames[doc.id] = doc.data()['name'] as String;
        }

        return data;
      } else {
        throw Exception('No data found!');
      }
    } catch (e) {
      print('Error loading data: $e');
      throw e;
    }
  }

  void printList(Map<String, dynamic> listData) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            children: [
              pw.Text('Shared List: $_listName by $_userName', style: pw.TextStyle(fontSize: 18)),
              pw.Padding(padding: const pw.EdgeInsets.all(10)),
              ...listData['items'].map<pw.Widget>((item) {
                return pw.Text('${_groupNames[item['groupId']] ?? 'Other'}: ${item['name']} - ${item['isDone'] ? "Yes" : "No"}');
              }),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: _listDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              return Text('Shared List: $_listName by $_userName', style: TextStyle(fontSize: 16));
            }
            return Text('Loading...', style: TextStyle(fontSize: 16));
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () async {
              if (_listDataFuture != null) {
                Map<String, dynamic> listData = await _listDataFuture;
                printList(listData);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _listDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Fehler beim Laden der Daten'));
          }

          Map<String, List<Map<String, dynamic>>> groupedItems = {};
          for (var item in snapshot.data!['items']) {
            String groupName = _groupNames[item['groupId']] ?? 'Other';
            if (!groupedItems.containsKey(groupName)) {
              groupedItems[groupName] = [];
            }
            groupedItems[groupName]!.add(item);
          }

          List<Widget> groupWidgets = [];
          groupedItems.forEach((groupName, items) {
            groupWidgets.add(
              ExpansionTile(
                title: Text(groupName),
                children: items.map((item) => ListTile(
                  title: Text(item['name']),
                  trailing: Icon(item['isDone'] ? Icons.check_box : Icons.check_box_outline_blank),
                )).toList(),
              ),
            );
          });

          return ListView(
            children: groupWidgets,
          );
        },
      ),
    );
  }
}

