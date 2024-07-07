class Einkaufsliste {
  String id;
  String name;
  String ladenId;
  String items;
  String userId;

  Einkaufsliste({required this.id, required this.name, required this.ladenId, required this.items, required this.userId});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ladenId': ladenId,
    'items': items,
    'userId': userId
  };

  static Einkaufsliste fromJson(Map<String, dynamic> json) => Einkaufsliste(
    id: json['id'],
    name: json['name'],
    ladenId: json['ladenId'],
    items: json['items'],
    userId: json['userId']
  );
}
