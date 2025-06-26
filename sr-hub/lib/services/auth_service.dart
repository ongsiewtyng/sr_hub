// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password - Fixed for type casting issue
  Future<User?> signInWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      print('Attempting to sign in with email: $email');

      // Primary attempt using UserCredential
      try {
        UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('Sign in successful via UserCredential');
        return result.user;
      } catch (e) {
        print('UserCredential sign in failed: $e');

        // Check if this is the type casting error
        if (e.toString().contains('type') && e.toString().contains('subtype')) {
          print('Type casting error detected, trying workaround...');

          // Workaround: Wait for auth state to update and get current user
          await Future.delayed(const Duration(milliseconds: 1500));

          final User? currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.email == email) {
            print('Workaround successful: Retrieved user from auth state');
            return currentUser;
          } else {
            print('Workaround failed: Current user is null or email mismatch');
            throw Exception('Authentication failed due to plugin issue. Please restart the app and try again.');
          }
        } else {
          // Re-throw other types of errors
          rethrow;
        }
      }
    } catch (e) {
      print('General sign in error: $e');
      rethrow;
    }
  }

  // Register with email and password - Enhanced error handling
  Future<User?> registerWithEmailAndPassword(
      String email,
      String password,
      String name,
      String studentId,
      String department,
      ) async {
    User? user;

    try {
      print('Starting registration process...');

      // Create user account with enhanced error handling
      try {
        UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = result.user;
        print('Firebase Auth user created via UserCredential: ${user?.uid}');
      } catch (e) {
        print('UserCredential creation failed: $e');

        // Handle the type casting issue during registration
        if (e.toString().contains('type') && e.toString().contains('subtype')) {
          print('Type casting error during registration, trying workaround...');

          // Wait longer for auth state to update during registration
          await Future.delayed(const Duration(milliseconds: 2000));

          // Get current user from auth state
          user = _auth.currentUser;

          if (user != null && user.email == email) {
            print('Registration workaround successful: Retrieved user from auth state: ${user.uid}');
          } else {
            print('Registration workaround failed: User is null or email mismatch');
            throw Exception('Account creation failed due to plugin issue. Please restart the app and try again.');
          }
        } else {
          // Handle other Firebase Auth errors
          if (e.toString().contains('email-already-in-use')) {
            throw Exception('An account with this email already exists');
          } else if (e.toString().contains('weak-password')) {
            throw Exception('Password is too weak. Please choose a stronger password');
          } else if (e.toString().contains('invalid-email')) {
            throw Exception('Please enter a valid email address');
          } else {
            rethrow;
          }
        }
      }

      if (user == null) {
        throw Exception('User creation failed - user is null');
      }

      print('User created with ID: ${user.uid}');

      // Update display name
      try {
        await user.updateDisplayName(name);
        print('Display name updated successfully');
      } catch (e) {
        print('Failed to update display name: $e');
        // Continue anyway, this is not critical
      }

      // Create user document in Firestore
      await _createUserDocument(user, name, studentId, department);
      print('User document created successfully');

      return user;
    } catch (e) {
      print('Registration error: $e');

      // If user was created but document creation failed, clean up
      if (user != null) {
        try {
          await user.delete();
          print('Cleaned up user account due to registration failure');
        } catch (cleanupError) {
          print('Failed to cleanup user account: $cleanupError');
        }
      }

      rethrow;
    }
  }

  // Generate DiceBear profile image URL
  String _generateProfileImageUrl(String seed) {
    return 'https://api.dicebear.com/9.x/open-peeps/svg?seed=$seed';
  }


  // Create user document in Firestore with enhanced error handling
  Future<void> _createUserDocument(
      User user,
      String name,
      String studentId,
      String department,
      ) async {
    try {
      print('Creating user document for: ${user.uid}');

      final profileImageUrl = _generateProfileImageUrl(user.uid); // ✅ NEW

      final userData = {
        'id': user.uid,
        'name': name.trim(),
        'email': user.email ?? '',
        'studentId': studentId.trim(),
        'department': department,
        'role': 'student',
        'memberSince': FieldValue.serverTimestamp(),
        'profileImageUrl': profileImageUrl, // ✅ NEW
        'phoneNumber': '',
        'address': '',
        'dateOfBirth': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final statsData = {
        'userId': user.uid,
        'totalReservations': 0,
        'totalBooksRead': 0,
        'totalResourcesAccessed': 0,
        'favoriteBooks': [],
        'favoriteResources': [],
        'joinDate': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final batch = _firestore.batch();
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final statsDocRef = _firestore.collection('user_stats').doc(user.uid);

      batch.set(userDocRef, userData);
      batch.set(statsDocRef, statsData);

      await batch.commit();

      print('User document and stats created successfully with batch write');

    } catch (e) {
      print('Error creating user document: $e');
      rethrow;
    }
  }

  // Get user data from Firestore with better error handling
  Future<AppUser?> getUserData(String uid) async {
    try {
      print('Fetching user data for: $uid');
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        print('User data retrieved successfully');
        return AppUser.fromMap(data);
      } else {
        print('User document does not exist for uid: $uid');
        return null;
      }
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(data);
      print('User profile updated successfully');
    } catch (e) {
      print('Update user profile error: $e');
      rethrow;
    }
  }

  // Sign out with error handling
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to: $email');
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Use batch delete for consistency
        final batch = _firestore.batch();
        batch.delete(_firestore.collection('users').doc(user.uid));
        batch.delete(_firestore.collection('user_stats').doc(user.uid));
        await batch.commit();

        // Delete user account
        await user.delete();
        print('User account deleted successfully');
      }
    } catch (e) {
      print('Delete account error: $e');
      rethrow;
    }
  }

  // Helper method to check if current error is the type casting issue
  bool _isTypeCastingError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('type') &&
        errorString.contains('subtype') &&
        (errorString.contains('pigeonuserdetails') ||
            errorString.contains('list<object?>'));
  }
}