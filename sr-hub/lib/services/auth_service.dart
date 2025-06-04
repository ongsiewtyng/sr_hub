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

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Register with email and password - Updated to handle the type casting issue
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

      // Create user account with error handling for the type casting issue
      try {
        UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = result.user;
        print('Firebase Auth user created via UserCredential: ${user?.uid}');
      } catch (e) {
        print('UserCredential creation failed: $e');

        // If UserCredential fails due to type casting, try to get user from auth state
        if (e.toString().contains('type') && e.toString().contains('subtype')) {
          print('Attempting to get user from auth state...');

          // Wait a moment for auth state to update
          await Future.delayed(const Duration(milliseconds: 1000));

          // Get current user from auth state
          user = _auth.currentUser;

          if (user != null && user.email == email) {
            print('Successfully retrieved user from auth state: ${user.uid}');
          } else {
            print('Failed to retrieve user from auth state');
            rethrow;
          }
        } else {
          rethrow;
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

  // Create user document in Firestore with better error handling
  Future<void> _createUserDocument(
      User user,
      String name,
      String studentId,
      String department,
      ) async {
    try {
      print('Creating user document for: ${user.uid}');

      // Use a transaction to ensure both documents are created atomically
      await _firestore.runTransaction((transaction) async {
        final userDocRef = _firestore.collection('users').doc(user.uid);
        final statsDocRef = _firestore.collection('user_stats').doc(user.uid);

        // Create user data
        final userData = {
          'id': user.uid,
          'name': name,
          'email': user.email ?? '',
          'studentId': studentId,
          'department': department,
          'role': 'student',
          'memberSince': FieldValue.serverTimestamp(),
          'isVerified': false,
          'profileImageUrl': '',
          'phoneNumber': '',
          'address': '',
          'dateOfBirth': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Create user stats data
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

        // Set both documents in the transaction
        transaction.set(userDocRef, userData);
        transaction.set(statsDocRef, statsData);
      });

      print('User document and stats created successfully in transaction');

    } catch (e) {
      print('Error creating user document: $e');
      rethrow;
    }
  }

  // Verify user registration - for testing purposes
  Future<Map<String, dynamic>> verifyUserRegistration(String email, String password) async {
    try {
      print('🔍 VERIFICATION: Starting registration verification');

      // Step 1: Check if user can sign in
      print('🔍 VERIFICATION: Attempting to sign in with credentials');
      User? user;

      try {
        UserCredential userCred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = userCred.user;
        print('✅ VERIFICATION: Sign-in successful with uid: ${user?.uid}');
      } catch (e) {
        print('❌ VERIFICATION: Sign-in failed: $e');
        return {'success': false, 'stage': 'auth', 'error': e.toString()};
      }

      if (user == null) {
        print('❌ VERIFICATION: User is null after sign-in');
        return {'success': false, 'stage': 'auth', 'error': 'User is null after sign-in'};
      }

      final uid = user.uid;

      // Step 2: Check if user document exists in Firestore
      print('🔍 VERIFICATION: Checking user document in Firestore');
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        print('❌ VERIFICATION: User document does not exist in Firestore');
        return {'success': false, 'stage': 'firestore_user', 'error': 'User document not found'};
      }

      print('✅ VERIFICATION: User document exists in Firestore');
      final userData = userDoc.data() as Map<String, dynamic>;
      print('📄 VERIFICATION: User data: ${userData.toString()}');

      // Step 3: Check if user stats document exists
      print('🔍 VERIFICATION: Checking user stats document');
      final statsDoc = await _firestore.collection('user_stats').doc(uid).get();

      if (!statsDoc.exists) {
        print('❌ VERIFICATION: User stats document does not exist');
        return {
          'success': false,
          'stage': 'firestore_stats',
          'error': 'User stats not found',
          'user_data': userData
        };
      }

      print('✅ VERIFICATION: User stats document exists');
      final statsData = statsDoc.data() as Map<String, dynamic>;
      print('📄 VERIFICATION: User stats: ${statsData.toString()}');

      // All checks passed
      print('✅ VERIFICATION: All verification checks passed successfully!');
      return {
        'success': true,
        'user_id': uid,
        'user_data': userData,
        'stats_data': statsData
      };
    } catch (e) {
      print('❌ VERIFICATION: Verification process failed with error: $e');
      return {'success': false, 'stage': 'unknown', 'error': e.toString()};
    }
  }

  // Get user data from Firestore
  Future<AppUser?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return AppUser.fromMap(data);
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
      data['updatedAt'] = FieldValue.serverTimestamp();
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
        // Delete user documents from Firestore
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