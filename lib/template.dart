class TemplateList {
  final String name;
  final String groupId;
  final String groupName;
  final bool isDone;
  final String imagePath;

  TemplateList({
    required this.name,
    required this.groupId,
    required this.groupName,
    this.isDone = false,
    required this.imagePath,
  });

  factory TemplateList.fromJson(Map<String, dynamic> json) {
    return TemplateList(
      name: json['name'] as String,
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String? ?? 'idk',
      isDone: json['isDone'] as bool? ?? false,
      imagePath: json['imagePath'] as String,
    );
  }
}
