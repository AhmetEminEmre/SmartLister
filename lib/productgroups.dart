class ProductGroup {
  String id;
  String name;
  String storeId;

  ProductGroup({required this.id, required this.name, required this.storeId});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'storeId': storeId,
    };
  }

  static ProductGroup fromJson(Map<String, dynamic> json) {
    return ProductGroup(
      id: json['id'],
      name: json['name'],
      storeId: json['storeId'],
    );
  }
}
