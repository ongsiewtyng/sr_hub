// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final String department;
  final String role;
  final DateTime? memberSince;
  final bool isVerified;
  final String? profileImageUrl;
  final String? phoneNumber;
  final String? address;
  final DateTime? dateOfBirth;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.department,
    this.role = 'student',
    this.memberSince,
    this.isVerified = false,
    this.profileImageUrl,
    this.phoneNumber,
    this.address,
    this.dateOfBirth,
    this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'studentId': studentId,
      'department': department,
      'role': role,
      'memberSince': memberSince != null ? Timestamp.fromDate(memberSince!) : null,
      'isVerified': isVerified,
      'profileImageUrl': profileImageUrl ?? '',
      'phoneNumber': phoneNumber ?? '',
      'address': address ?? '',
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore Map
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      studentId: map['studentId'] ?? '',
      department: map['department'] ?? '',
      role: map['role'] ?? 'student',
      memberSince: map['memberSince'] != null
          ? (map['memberSince'] as Timestamp).toDate()
          : null,
      isVerified: map['isVerified'] ?? false,
      profileImageUrl: map['profileImageUrl'],
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      dateOfBirth: map['dateOfBirth'] != null
          ? (map['dateOfBirth'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Copy with method for updates
  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? studentId,
    String? department,
    String? role,
    DateTime? memberSince,
    bool? isVerified,
    String? profileImageUrl,
    String? phoneNumber,
    String? address,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      role: role ?? this.role,
      memberSince: memberSince ?? this.memberSince,
      isVerified: isVerified ?? this.isVerified,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AppUser(id: $id, name: $name, email: $email, studentId: $studentId, department: $department)';
  }
}