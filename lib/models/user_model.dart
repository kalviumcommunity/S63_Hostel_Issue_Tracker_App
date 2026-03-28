class UserModel {
  final String uid;
  final String name;
  final String email;
  final String roomNumber;
  final String hostelBlock;
  final String role; // 'student', 'admin', 'staff'
  final String? profileImageUrl;
  final String? fcmToken;
  final String? staffCategory; // Only for staff
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.roomNumber,
    required this.hostelBlock,
    required this.role,
    this.profileImageUrl,
    this.fcmToken,
    this.staffCategory,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      hostelBlock: map['hostelBlock'] ?? '',
      role: map['role'] ?? 'student',
      profileImageUrl: map['profileImageUrl'],
      fcmToken: map['fcmToken'],
      staffCategory: map['staffCategory'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'roomNumber': roomNumber,
      'hostelBlock': hostelBlock,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'fcmToken': fcmToken,
      'staffCategory': staffCategory,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
