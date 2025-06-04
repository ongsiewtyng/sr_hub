// lib/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'auth_provider.dart';

// Current user data provider
final currentUserProvider = StreamProvider<AppUser?>((ref) async* {
  final authService = ref.watch(authServiceProvider);

  await for (final user in authService.authStateChanges) {
    if (user != null) {
      try {
        final userData = await authService.getUserData(user.uid);
        yield userData;
      } catch (e) {
        print('Error fetching user data: $e');
        yield null;
      }
    } else {
      yield null;
    }
  }
});

// User profile notifier for managing profile updates
class UserProfileNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  UserProfileNotifier(this._authService) : super(const AsyncValue.loading());

  final AuthService _authService;

  Future<void> loadUserProfile() async {
    try {
      state = const AsyncValue.loading();
      final currentUser = _authService.currentUser;

      if (currentUser != null) {
        final userData = await _authService.getUserData(currentUser.uid);
        state = AsyncValue.data(userData);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      // Update in Firestore
      await _authService.updateUserProfile(currentUser.uid, updates);

      // Reload profile data
      await loadUserProfile();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateProfileImage(String imageUrl) async {
    await updateProfile({'profileImageUrl': imageUrl});
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<AppUser?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return UserProfileNotifier(authService);
});