// lib/models/user_model.dart
class User {
  final String id;
  final String name;
  final String email;
  final String? profilePictureUrl;
  final String? studentId;
  final String? department;
  final String? role; // 'student', 'faculty', 'staff', etc.
  final DateTime? memberSince;
  final bool isVerified;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePictureUrl,
    this.studentId,
    this.department,
    this.role = 'student',
    this.memberSince,
    this.isVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePictureUrl: json['profilePictureUrl'],
      studentId: json['studentId'],
      department: json['department'],
      role: json['role'] ?? 'student',
      memberSince: json['memberSince'] != null
          ? DateTime.parse(json['memberSince'])
          : null,
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'studentId': studentId,
      'department': department,
      'role': role,
      'memberSince': memberSince?.toIso8601String(),
      'isVerified': isVerified,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePictureUrl,
    String? studentId,
    String? department,
    String? role,
    DateTime? memberSince,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      role: role ?? this.role,
      memberSince: memberSince ?? this.memberSince,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}