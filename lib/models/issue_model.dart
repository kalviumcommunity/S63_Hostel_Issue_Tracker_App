class IssueModel {
  final String id;
  final String title;
  final String description;
  final String category; // e.g. 'Plumbing', 'Electrical', 'Furniture', etc.
  final String priority; // 'low', 'medium', 'high'
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final String reportedBy; // user uid
  final String reporterName;
  final String roomNumber;
  final String hostelBlock;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? assignedTo; // admin/staff uid
  final String? resolutionNote;

  IssueModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.reportedBy,
    required this.reporterName,
    required this.roomNumber,
    required this.hostelBlock,
    required this.imageUrls,
    required this.createdAt,
    this.updatedAt,
    this.assignedTo,
    this.resolutionNote,
  });

  factory IssueModel.fromMap(Map<String, dynamic> map, String docId) {
    return IssueModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'open',
      reportedBy: map['reportedBy'] ?? '',
      reporterName: map['reporterName'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      hostelBlock: map['hostelBlock'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      assignedTo: map['assignedTo'],
      resolutionNote: map['resolutionNote'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'reportedBy': reportedBy,
      'reporterName': reporterName,
      'roomNumber': roomNumber,
      'hostelBlock': hostelBlock,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'assignedTo': assignedTo,
      'resolutionNote': resolutionNote,
    };
  }

  IssueModel copyWith({
    String? status,
    String? assignedTo,
    String? resolutionNote,
    DateTime? updatedAt,
  }) {
    return IssueModel(
      id: id,
      title: title,
      description: description,
      category: category,
      priority: priority,
      status: status ?? this.status,
      reportedBy: reportedBy,
      reporterName: reporterName,
      roomNumber: roomNumber,
      hostelBlock: hostelBlock,
      imageUrls: imageUrls,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      resolutionNote: resolutionNote ?? this.resolutionNote,
    );
  }
}

// Issue categories
const List<String> issueCategories = [
  'Plumbing',
  'Electrical',
  'Furniture',
  'Internet / WiFi',
  'Cleaning',
  'Security',
  'Pest Control',
  'HVAC / Fan / AC',
  'Laundry',
  'Other',
];
