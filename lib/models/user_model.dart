class UserModel {
  final String uid;
  final String name;
  final String email;
  final String roomNumber;
  final String hostelBlock;
  final String role; // 'student' or 'admin'
  final String? profileImageUrl;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.roomNumber,
    required this.hostelBlock,
    required this.role,
    this.profileImageUrl,
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
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
