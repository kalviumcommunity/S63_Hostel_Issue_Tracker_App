import 'package:cloud_firestore/cloud_firestore.dart';

// Issue status values
const String statusPending = 'pending';
const String statusAssigned = 'assigned';
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

  // Added SLA specific fields
  final String priority; // High | Medium | Low
  final DateTime deadline;
  final bool isDelayed;
  
  // Assignment Fields
  final String? assignedStaffId;
  final String? assignedStaffName;

  // Timeline Timestamps
  final DateTime? assignedAt;
  final DateTime? startedAt;
  final DateTime? resolvedAt;

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
    required this.priority,
    required this.deadline,
    required this.isDelayed,
    this.assignedStaffId,
    this.assignedStaffName,
    this.assignedAt,
    this.startedAt,
    this.resolvedAt,
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
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt'], isNullable: true),
      adminComment: map['adminComment'],
      priority: map['priority'] ?? 'Low',
      deadline: _parseDateTime(map['deadline']) ?? DateTime.now().add(const Duration(hours: 72)),
      isDelayed: map['isDelayed'] ?? false,
      assignedStaffId: map['assignedStaffId'],
      assignedStaffName: map['assignedStaffName'],
      assignedAt: _parseDateTime(map['assignedAt'], isNullable: true),
      startedAt: _parseDateTime(map['startedAt'], isNullable: true),
      resolvedAt: _parseDateTime(map['resolvedAt'], isNullable: true),
    );
  }

  static DateTime? _parseDateTime(dynamic value, {bool isNullable = false}) {
    if (value == null) return isNullable ? null : DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? (isNullable ? null : DateTime.now());
    return isNullable ? null : DateTime.now();
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
      'priority': priority,
      'deadline': deadline.toIso8601String(),
      'isDelayed': isDelayed,
      'assignedStaffId': assignedStaffId,
      'assignedStaffName': assignedStaffName,
      'assignedAt': assignedAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  IssueModel copyWith({
    String? status,
    String? adminComment,
    DateTime? updatedAt,
    bool? isDelayed,
    String? assignedStaffId,
    String? assignedStaffName,
    DateTime? assignedAt,
    DateTime? startedAt,
    DateTime? resolvedAt,
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
      priority: priority,
      deadline: deadline,
      isDelayed: isDelayed ?? this.isDelayed,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      assignedAt: assignedAt ?? this.assignedAt,
      startedAt: startedAt ?? this.startedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
