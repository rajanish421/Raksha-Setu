class FamilyGroupModel {
  final String id;
  final String name;
  final String createdBy;
  final List<String> members;
  final DateTime createdAt;

  FamilyGroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.members,
    required this.createdAt,
  });

  factory FamilyGroupModel.fromMap(String id, Map<String, dynamic> data) {
    return FamilyGroupModel(
      id: id,
      name: data['name'],
      createdBy: data['createdBy'],
      members: List<String>.from(data['members'] ?? []),
      createdAt: DateTime.parse(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdBy': createdBy,
      'members': members,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
