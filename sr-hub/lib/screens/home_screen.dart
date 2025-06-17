// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sr_hub/screens/library/room_reservation_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/firestore_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/book_card.dart';
import '../widgets/resource_card.dart';
import '../widgets/reservation_card.dart';
import '../widgets/rating_widget.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_display.dart';
import '../widgets/empty_state.dart';
import '../widgets/search_bar.dart';
import '../models/user_model.dart';
import '../models/book_model.dart';
import '../models/resource_model.dart';
import '../models/reservation_model.dart';
import 'library/library_map_screen.dart';
import 'bookstore/bookstore_homepage_screen.dart';
import 'resources/resources_search_screen.dart';
import 'profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (firebaseUser) {
        if (firebaseUser == null) {
          // Redirect to login if not authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const LoadingIndicator(fullScreen: true);
        }

        return _buildMainApp(firebaseUser.uid);
      },
      loading: () => const LoadingIndicator(fullScreen: true),
      error: (error, stack) => ErrorDisplay(
        message: 'Authentication error: $error',
        fullScreen: true,
        onRetry: () {
          ref.refresh(authStateProvider);
        },
      ),
    );
  }

  Widget _buildMainApp(String userId) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(userId),
          //const LibraryMapScreen(),
          const RoomReservationScreen(),
          const BookstoreHomepageScreen(),
          const ResourceSearchScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
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

  Widget _buildDashboard(String userId) {
    final currentUser = ref.watch(currentUserProvider);
    final featuredBooks = ref.watch(featuredBooksProvider);
    final resources = ref.watch(resourcesProvider);
    final reservations = ref.watch(userReservationsProvider(userId));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Study Resource Hub',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).signOut();
                if (mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sign out failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all data
          ref.refresh(currentUserProvider);
          ref.refresh(featuredBooksProvider);
          ref.refresh(resourcesProvider);
          ref.refresh(userReservationsProvider(userId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              currentUser.when(
                data: (user) => user != null ? _buildWelcomeSection(user) : _buildDefaultWelcomeSection(),
                loading: () => _buildLoadingWelcomeSection(),
                error: (error, stack) => _buildErrorWelcomeSection(),
              ),

              // Quick actions
              _buildQuickActions(),

              // Upcoming reservations
              reservations.when(
                data: (reservationList) => _buildReservationsSection(reservationList),
                loading: () => _buildLoadingSection('Loading reservations...', 200),
                error: (error, stack) => _buildErrorSection(
                  'Failed to load reservations',
                      () => ref.refresh(userReservationsProvider(userId)),
                ),
              ),

              // Featured books
              featuredBooks.when(
                data: (bookList) => _buildFeaturedBooksSection(bookList),
                loading: () => _buildLoadingSection('Loading featured books...', 300),
                error: (error, stack) => _buildErrorSection(
                  'Failed to load books',
                      () => ref.refresh(featuredBooksProvider),
                ),
              ),

              // Recent resources
              resources.when(
                data: (resourceList) => _buildResourcesSection(resourceList),
                loading: () => _buildLoadingSection('Loading resources...', 200),
                error: (error, stack) => _buildErrorSection(
                  'Failed to load resources',
                      () => ref.refresh(resourcesProvider),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(AppUser user) {
    return Container(
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
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: user.profileImageUrl == null
                    ? Text(
                  user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.department != null) ...[
                      Text(
                        user.department!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomSearchBar(
            hintText: 'Search for books, resources, or seats',
            showFilterButton: true,
            margin: EdgeInsets.zero,
            onSubmitted: (query) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Searching for: $query')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultWelcomeSection() {
    return Container(
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
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Study Resource Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomSearchBar(
            hintText: 'Search for books, resources, or seats',
            showFilterButton: true,
            margin: EdgeInsets.zero,
            onSubmitted: (query) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Searching for: $query')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWelcomeSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: const Center(
        child: LoadingIndicator(
          message: 'Loading user data...',
        ),
      ),
    );
  }

  Widget _buildErrorWelcomeSection() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade700,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load user data',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
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
                onTap: () => setState(() => _currentIndex = 1),
                color: Colors.blue,
              ),
              _buildQuickAction(
                context,
                icon: Icons.book,
                label: 'Browse Books',
                onTap: () => setState(() => _currentIndex = 2),
                color: Colors.green,
              ),
              _buildQuickAction(
                context,
                icon: Icons.file_copy,
                label: 'Resources',
                onTap: () => setState(() => _currentIndex = 3),
                color: Colors.purple,
              ),
              _buildQuickAction(
                context,
                icon: Icons.history,
                label: 'History',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('History feature coming soon!')),
                  );
                },
                color: Colors.orange,
              ),
            ],
          ),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsSection(List<Reservation> reservations) {
    final upcomingReservations = reservations.where((r) => r.isUpcoming).toList();

    return Padding(
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All reservations view coming soon!')),
                  );
                },
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          upcomingReservations.isEmpty
              ? EmptyState(
            message: 'You have no upcoming reservations',
            icon: Icons.event_busy,
            actionText: 'Reserve a Seat',
            onAction: () => setState(() => _currentIndex = 1),
          )
              : Column(
            children: upcomingReservations
                .take(2)
                .map((reservation) => ReservationCard(
              reservation: reservation,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Viewing ${reservation.resourceName}')),
                );
              },
              onCancel: () async {
                try {
                  await ref.read(firestoreServiceProvider).cancelReservation(reservation.id);
                  ref.refresh(userReservationsProvider(reservation.userId));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reservation cancelled successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to cancel reservation: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              onNavigate: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Navigating to ${reservation.resourceName}')),
                );
              },
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBooksSection(List<Book> books) {
    return Padding(
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
                onPressed: () => setState(() => _currentIndex = 2),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          books.isEmpty
              ? EmptyState(
            message: 'No featured books available',
            icon: Icons.book,
            actionText: 'Browse Books',
            onAction: () => setState(() => _currentIndex = 2),
          )
              : SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return SizedBox(
                  width: 160,
                  child: BookCard(
                    book: book,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Viewing ${book.title}')),
                      );
                    },
                    onFavorite: () async {
                      try {
                        final firebaseUser = ref.read(authStateProvider).value;
                        if (firebaseUser != null) {
                          await ref.read(firestoreServiceProvider).addToWishlist(firebaseUser.uid, book.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${book.title} added to wishlist')),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add to wishlist: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesSection(List<Resource> resources) {
    return Padding(
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
                onPressed: () => setState(() => _currentIndex = 3),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          resources.isEmpty
              ? EmptyState(
            message: 'No resources available',
            icon: Icons.file_copy,
            actionText: 'Browse Resources',
            onAction: () => setState(() => _currentIndex = 3),
          )
              : Column(
            children: resources
                .take(3)
                .map((resource) => ResourceCard(
              resource: resource,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Viewing ${resource.title}')),
                );
              },
              onSave: () async {
                try {
                  final firebaseUser = ref.read(authStateProvider).value;
                  if (firebaseUser != null) {
                    await ref.read(firestoreServiceProvider).saveResource(firebaseUser.uid, resource.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${resource.title} saved')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to save resource: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection(String message, double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: height,
        child: LoadingIndicator(message: message),
      ),
    );
  }

  Widget _buildErrorSection(String message, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 150,
        child: ErrorDisplay(
          message: message,
          onRetry: onRetry,
        ),
      ),
    );
  }
}