// lib/models/user_model.dart
class User {
  final String id;
  final String name;
  final String email;
  final String? profilePictureUrl;
  final String? studentId;
  final String? department;
  final String role;
  final DateTime memberSince;
  final bool isVerified;

  User({
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
}