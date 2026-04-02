class StaffModel {
  final String id;
  final String name;
  final String role;
  final String category; // Electricity, Water Problem, Mess Food, etc.
  final bool isAvailable;
  final int activeIssuesCount; // For load balancing

  StaffModel({
    required this.id,
    required this.name,
    required this.role,
    required this.category,
    required this.isAvailable,
    this.activeIssuesCount = 0,
  });

  factory StaffModel.fromMap(Map<String, dynamic> map, String docId) {
    return StaffModel(
      id: docId,
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      category: map['category'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      activeIssuesCount: map['activeIssuesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'category': category,
      'isAvailable': isAvailable,
      'activeIssuesCount': activeIssuesCount,
    };
  }
}
