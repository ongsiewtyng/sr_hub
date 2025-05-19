// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/library/library_map_screen.dart';
import 'screens/bookstore/bookstore_homepage_screen.dart';
import 'screens/resources/resources_search_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: StudyResourceHubApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/library',
      builder: (context, state) => const LibraryMapScreen(),
    ),
    GoRoute(
      path: '/bookstore',
      builder: (context, state) => const BookstoreHomepageScreen(),
    ),
    GoRoute(
      path: '/resources',
      builder: (context, state) => const ResourceSearchScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
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