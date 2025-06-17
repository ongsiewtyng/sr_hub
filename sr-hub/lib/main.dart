// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:sr_hub/screens/auth/register_screen.dart';
import 'package:sr_hub/screens/debug/open_library_test_screen.dart';
import 'package:sr_hub/screens/library/my_reservations_screen.dart';
import 'package:sr_hub/screens/library/room_reservation_screen.dart';
import 'package:sr_hub/screens/profile/edit_profile_screen.dart';
import 'package:sr_hub/screens/resources/resources_search_screen.dart';
import 'screens/home_screen.dart';
import 'screens/library/library_map_screen.dart';
import 'screens/bookstore/bookstore_homepage_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      child: StudyResourceHubApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // Add authentication check here
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/library',
      builder: (context, state) => const RoomReservationScreen(),
    ),
    GoRoute(
        path:'/my-reservations',
        builder: (context, state) => const MyReservationsScreen(),
    ),
    GoRoute(
      path: '/bookstore',
      builder: (context, state) => const BookstoreHomepageScreen(),
    ),
    GoRoute(
      path: '/open-library-test',
      builder: (context, state) => const OpenLibraryTestScreen(),
    ),
    GoRoute(
      path: '/resources',
      builder: (context, state) => const ResourceSearchScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
  ],
);

class StudyResourceHubApp extends StatelessWidget {
  const StudyResourceHubApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Study Resource Hub',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}