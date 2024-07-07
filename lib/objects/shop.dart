class Einkaufsladen {
  String id;
  String name;
  String userId;  

  Einkaufsladen({required this.id, required this.name, required this.userId});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'userId': userId  
  };

  static Einkaufsladen fromJson(Map<String, dynamic> json) => Einkaufsladen(
    id: json['id'],
    name: json['name'],
    userId: json['userId']  
  );
}
