class Einkaufsladen {
  String id;
  String name;

  Einkaufsladen({required this.id, required this.name});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name
  };

  static Einkaufsladen fromJson(Map<String, dynamic> json) => Einkaufsladen(
    id: json['id'],
    name: json['name']
  );
}