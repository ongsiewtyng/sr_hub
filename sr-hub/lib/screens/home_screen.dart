// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/sample_data.dart';
import '../widgets/book_card.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_display.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/rating_widget.dart';
import '../widgets/reservation_card.dart';
import '../widgets/resource_card.dart';
import '../widgets/search_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Study Resource Hub',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _buildDashboard(),
          _buildLibraryTab(),
          _buildBookstoreTab(),
          _buildResourcesTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        },
        items: [
          CustomBottomNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Home',
          ),
          CustomBottomNavItem(
            icon: Icons.event_seat_outlined,
            activeIcon: Icons.event_seat,
            label: 'Library',
          ),
          CustomBottomNavItem(
            icon: Icons.book_outlined,
            activeIcon: Icons.book,
            label: 'Bookstore',
          ),
          CustomBottomNavItem(
            icon: Icons.file_copy_outlined,
            activeIcon: Icons.file_copy,
            label: 'Resources',
          ),
          CustomBottomNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final books = SampleData.getBooks();
    final resources = SampleData.getResources();
    final reservations = SampleData.getReservations();
    final user = SampleData.getUser();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(user.profilePictureUrl!),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const CustomSearchBar(
                  hintText: 'Search for books, resources, or seats',
                  showFilterButton: true,
                  margin: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // Quick actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickAction(
                      context,
                      icon: Icons.event_seat,
                      label: 'Reserve Seat',
                      onTap: () => context.push('/library'),
                      color: Colors.blue,
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.book,
                      label: 'Browse Books',
                      onTap: () => context.push('/bookstore'),
                      color: Colors.green,
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.file_copy,
                      label: 'Resources',
                      onTap: () => context.push('/resources'),
                      color: Colors.purple,
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.history,
                      label: 'History',
                      onTap: () {},
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Upcoming reservations
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upcoming Reservations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                reservations.isEmpty
                    ? const EmptyState(
                  message: 'You have no upcoming reservations',
                  icon: Icons.event_busy,
                  actionText: 'Reserve a Seat',
                )
                    : Column(
                  children: reservations
                      .where((r) => r.isUpcoming)
                      .take(2)
                      .map((reservation) => ReservationCard(
                    reservation: reservation,
                    onTap: () {},
                    onCancel: () {},
                    onNavigate: () {},
                  ))
                      .toList(),
                ),
              ],
            ),
          ),

          // Featured books
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Featured Books',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/bookstore'),
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: books.where((b) => b.isFeatured).length,
                    itemBuilder: (context, index) {
                      final book = books.where((b) => b.isFeatured).toList()[index];
                      return SizedBox(
                        width: 160,
                        child: BookCard(
                          book: book,
                          onTap: () {},
                          onFavorite: () {},
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Recent resources
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Resources',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/resources'),
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: resources
                      .take(3)
                      .map((resource) => ResourceCard(
                    resource: resource,
                    onTap: () {},
                    onSave: () {},
                  ))
                      .toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
        required Color color,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTab() {
    return Center(
      child: ElevatedButton(
        onPressed: () => context.push('/library'),
        child: const Text('Go to Library'),
      ),
    );
  }

  Widget _buildBookstoreTab() {
    return Center(
      child: ElevatedButton(
        onPressed: () => context.push('/bookstore'),
        child: const Text('Go to Bookstore'),
      ),
    );
  }

  Widget _buildResourcesTab() {
    return Center(
      child: ElevatedButton(
        onPressed: () => context.push('/resources'),
        child: const Text('Go to Resources'),
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: ElevatedButton(
        onPressed: () => context.push('/profile'),
        child: const Text('Go to Profile'),
      ),
    );
  }
}