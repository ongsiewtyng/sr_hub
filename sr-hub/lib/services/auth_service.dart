import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Custom typed exception for safer error handling.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current signed-in user.
  User? get currentUser => _auth.currentUser;

  /// Auth state changes stream.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// ✅ Sign in with email & password, with fallback for known type cast issues.
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
      final err = e.toString().toLowerCase();
      if (err.contains('type') && err.contains('subtype')) {
        // ✅ Known cast bug workaround
        await Future.delayed(const Duration(milliseconds: 1500));
        final fallbackUser = _auth.currentUser;
        if (fallbackUser != null && fallbackUser.email == email) {
          return fallbackUser;
        }
      }
      rethrow;
    }
  }

  /// ✅ Register user with fallback for type casting issue.
  Future<User?> registerWithEmailAndPassword(
      String email,
      String password,
      String name,
      String studentId,
      String department,
      ) async {
    User? user;
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = result.user;
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains('type') && err.contains('subtype')) {
        await Future.delayed(const Duration(milliseconds: 2000));
        user = _auth.currentUser;
        if (user == null || user.email != email) {
          throw AuthException('Account creation failed due to plugin issue.');
        }
      } else if (err.contains('email-already-in-use')) {
        throw AuthException('An account with this email already exists.');
      } else if (err.contains('weak-password')) {
        throw AuthException('Password is too weak. Please choose a stronger password.');
      } else if (err.contains('invalid-email')) {
        throw AuthException('Please enter a valid email address.');
      } else {
        rethrow;
      }
    }

    if (user == null) {
      throw AuthException('User creation failed.');
    }

    try {
      await user.updateDisplayName(name);
    } catch (_) {}

    await _createUserDocument(user, name, studentId, department);
    return user;
  }

  /// ✅ Robust reauthenticate helper.
  Future<void> reauthenticate({
    required String email,
    required String currentPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('User is not logged in.');

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw AuthException('Incorrect current password.');
      } else {
        throw AuthException('Reauthentication failed: ${e.message}');
      }
    }
  }

  /// ✅ Change password with robust flow.
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('User is not logged in.');

    try {
      await reauthenticate(email: email, currentPassword: currentPassword);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw AuthException('The new password is too weak.');
      } else if (e.code == 'requires-recent-login') {
        throw AuthException('Please reauthenticate and try again.');
      } else {
        throw AuthException('Password update failed: ${e.message}');
      }
    } catch (e) {
      throw AuthException('An unknown error occurred: $e');
    }
  }

  /// ✅ Get user Firestore doc.
  Future<AppUser?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// ✅ Update user Firestore doc.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(uid).update(data);
  }

  /// ✅ Create user doc.
  Future<void> _createUserDocument(
      User user,
      String name,
      String studentId,
      String department,
      ) async {
    final userData = {
      'id': user.uid,
      'name': name.trim(),
      'email': user.email ?? '',
      'studentId': studentId.trim(),
      'department': department,
      'role': 'student',
      'profileImageUrl': _generateProfileImageUrl(user.uid),
      'phoneNumber': '',
      'address': '',
      'dateOfBirth': null,
      'memberSince': FieldValue.serverTimestamp(),
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
    batch.set(_firestore.collection('users').doc(user.uid), userData);
    batch.set(_firestore.collection('user_stats').doc(user.uid), statsData);

    await batch.commit();
  }

  /// ✅ Generates avatar.
  String _generateProfileImageUrl(String seed) {
    return 'https://api.dicebear.com/9.x/open-peeps/svg?seed=$seed';
  }

  /// ✅ Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// ✅ Send password reset email.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// ✅ Delete account + Firestore docs.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    batch.delete(_firestore.collection('users').doc(user.uid));
    batch.delete(_firestore.collection('user_stats').doc(user.uid));

    await batch.commit();
    await user.delete();
  }
}
