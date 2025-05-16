import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:sr_hub/core/theme/app_theme.dart';
import 'package:sr_hub/features/library_reservation/presentation/screens/library_map_screen.dart';
import 'package:sr_hub/features/bookstore/presentation/screens/bookstore_home_screen.dart';
import 'package:sr_hub/features/resource_management/presentation/screens/resource_search_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const MyApp());
}

void setupDependencies() {
  final getIt = GetIt.instance;
  // TODO: Register dependencies
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study and Resource Hub',
      theme: AppTheme.lightTheme,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const LibraryMapScreen(),
    const BookstoreHomeScreen(),
    const ResourceSearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Bookstore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Resources',
          ),
        ],
      ),
    );
  }
}
