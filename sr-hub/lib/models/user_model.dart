// lib/models/user_model.dart
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? profilePictureUrl;
  final String? studentId;
  final String? department;
  final String role;
  final DateTime memberSince;
  final bool isVerified;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.profilePictureUrl,
    this.studentId,
    this.department,
    required this.role,
    required this.memberSince,
    this.isVerified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'studentId': studentId,
      'department': department,
      'role': role,
      'memberSince': memberSince.toIso8601String(),
      'isVerified': isVerified,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      studentId: map['studentId'],
      department: map['department'],
      role: map['role'] ?? 'student',
      memberSince: DateTime.parse(map['memberSince']),
      isVerified: map['isVerified'] ?? false,
    );
  }
}