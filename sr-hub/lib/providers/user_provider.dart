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
  final AuthService _authService;

  UserProfileNotifier(this._authService) : super(const AsyncValue.loading()) {
    _loadUser(); // ✅ Load automatically on init
  }

  Future<void> _loadUser() async {
    try {
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

  Future<void> loadUserProfile() async {
    await _loadUser();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      await _authService.updateUserProfile(currentUser.uid, updates);
      await _loadUser();
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
