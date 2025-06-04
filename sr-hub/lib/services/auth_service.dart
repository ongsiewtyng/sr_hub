// lib/services/auth_service.dart (Update the registration method)
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

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
      String email,
      String password,
      String name,
      String studentId,
      String department,
      ) async {
    try {
      // Create user account
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await result.user?.updateDisplayName(name);

      // Create user document in Firestore
      if (result.user != null) {
        await _createUserDocument(
          result.user!,
          name,
          studentId,
          department,
        );
      }

      return result;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
      User user,
      String name,
      String studentId,
      String department,
      ) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);

      final userData = AppUser(
        id: user.uid,
        name: name,
        email: user.email!,
        studentId: studentId,
        department: department,
        role: 'student',
        memberSince: DateTime.now(),
        isVerified: false,
      );

      await userDoc.set(userData.toMap());

      // Also create initial user stats
      await _firestore.collection('user_stats').doc(user.uid).set({
        'userId': user.uid,
        'totalReservations': 0,
        'totalBooksRead': 0,
        'totalResourcesAccessed': 0,
        'joinDate': DateTime.now().toIso8601String(),
        'lastActive': DateTime.now().toIso8601String(),
      });

      print('User document created successfully for ${user.uid}');
    } catch (e) {
      print('Error creating user document: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<AppUser?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Update user profile error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
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
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        await _firestore.collection('user_stats').doc(user.uid).delete();

        // Delete user account
        await user.delete();
      }
    } catch (e) {
      print('Delete account error: $e');
      rethrow;
    }
  }
}