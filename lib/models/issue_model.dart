// Issue status values
const String statusPending = 'pending';
const String statusInProgress = 'in_progress';
const String statusResolved = 'resolved';

// Issue categories aligned with hostel problems
const List<String> issueCategories = [
  'Mess Food',
  'Water Problem',
  'Electricity',
  'Room Maintenance',
  'Cleanliness',
  'Internet / WiFi',
  'Security',
  'Other',
];

class IssueModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status; // pending | in_progress | resolved
  final String createdBy; // user uid
  final String createdByName;
  final String location; // room number + block
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminComment;

  IssueModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.createdBy,
    required this.createdByName,
    required this.location,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.adminComment,
  });

  factory IssueModel.fromMap(Map<String, dynamic> map, String docId) {
    return IssueModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      status: map['status'] ?? statusPending,
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      adminComment: map['adminComment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'location': location,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'adminComment': adminComment,
    };
  }

  IssueModel copyWith({
    String? status,
    String? adminComment,
    DateTime? updatedAt,
  }) {
    return IssueModel(
      id: id,
      title: title,
      description: description,
      category: category,
      status: status ?? this.status,
      createdBy: createdBy,
      createdByName: createdByName,
      location: location,
      imageUrl: imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminComment: adminComment ?? this.adminComment,
    );
  }
}
