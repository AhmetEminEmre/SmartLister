import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../objects/itemlist.dart';
import 'itemslist_screen.dart';

class AllListsScreen extends StatelessWidget {
  final Isar isar;

  const AllListsScreen({super.key, required this.isar});

  Future<List<Itemlist>> _fetchAllLists() async {
    final lists = await isar.itemlists.where().findAll();
    lists.sort((a, b) => b.creationDate.compareTo(a.creationDate));
    return lists;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alle Listen"),
        backgroundColor: const Color(0xFF334B46),
      ),
      backgroundColor: const Color(0xFF334B46),
      body: FutureBuilder<List<Itemlist>>(
        future: _fetchAllLists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Fehler: ${snapshot.error}"));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final lists = snapshot.data!;
            return ListView.builder(
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final itemlist = lists[index];
                return ListTile(
                  title: Text(
                    itemlist.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "Erstellt am: ${itemlist.creationDate}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemListScreen(
                            listName: itemlist.name,
                            shoppingListId: itemlist.id.toString(),
                            items: [itemlist],
                            initialStoreId: itemlist.shopId,
                            isar: isar,
                          ),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemListScreen(
                          listName: itemlist.name,
                          shoppingListId: itemlist.id.toString(),
                          items: [itemlist],
                          initialStoreId: itemlist.shopId,
                          isar: isar,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          } else {
            return const Center(
              child: Text(
                "Keine Listen gefunden",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
        },
      ),
    );
  }
}
