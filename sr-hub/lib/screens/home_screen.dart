import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sr_hub/screens/library/room_reservation_screen.dart';
import '../models/open_library_models.dart';
import '../providers/auth_provider.dart';
import '../providers/firestore_provider.dart';
import '../providers/open_library_provider.dart';
import '../providers/resource_providers.dart';
import '../providers/room_reservation_provider.dart';
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
import '../models/resource_models.dart';
import '../models/reservation_model.dart';
import '../models/library_models.dart';
import 'bookstore/open_library_book_details_screeen.dart';
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
    final roomReservations = ref.watch(upcomingRoomReservationsProvider);

    // New: Using API-backed providers
    final trendingBooks = ref.watch(openLibraryTrendingProvider);
    final trendingPapers = ref.watch(trendingPapersProvider);

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
          ref.refresh(currentUserProvider);
          ref.refresh(upcomingRoomReservationsProvider);
          ref.refresh(openLibraryTrendingProvider);
          ref.refresh(trendingPapersProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              currentUser.when(
                data: (user) =>
                user != null ? _buildWelcomeSection(user) : _buildDefaultWelcomeSection(),
                loading: () => _buildLoadingWelcomeSection(),
                error: (error, stack) => _buildErrorWelcomeSection(),
              ),

              // Quick Actions
              _buildQuickActions(),

              // Room Reservations
              roomReservations.when(
                data: (roomReservationList) =>
                    _buildRoomReservationsSection(roomReservationList),
                loading: () => _buildLoadingSection('Loading room reservations...', 200),
                error: (error, stack) => _buildErrorSection(
                  'Failed to load room reservations',
                      () => ref.refresh(upcomingRoomReservationsProvider),
                ),
              ),

              // Featured Books (from OpenLibrary API)
              trendingBooks.when(
                data: (bookList) => _buildFeaturedBooksSection(bookList),
                loading: () => _buildLoadingSection('Loading featured books...', 300),
                error: (error, stack) => _buildErrorSection(
                  'Failed to load featured books',
                      () => ref.refresh(openLibraryTrendingProvider),
                ),
              ),

              // Recent Research Papers
              trendingPapers.when(
                data: (papers) => _buildResourcesSection(papers),
                loading: () => _buildLoadingSection('Loading research papers...', 200),
                error: (error, stack) => _buildErrorSection(
                  'Failed to load research papers',
                      () => ref.refresh(trendingPapersProvider),
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
                label: 'Reserve Room',
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
                label: 'My Reservations',
                onTap: () => context.go('/my-reservations'),
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

  Widget _buildRoomReservationsSection(List<RoomReservation> roomReservations) {
    if (roomReservations.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Room Reservations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/my-reservations'),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: roomReservations
                .take(2)
                .map((reservation) => _buildRoomReservationCard(reservation))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRoomReservationCard(RoomReservation reservation) {
    final now = DateTime.now();
    final isToday = reservation.date.year == now.year &&
        reservation.date.month == now.month &&
        reservation.date.day == now.day;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isToday ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isToday ? BorderSide(color: Theme.of(context).primaryColor, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => context.go('/my-reservations'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isToday
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.meeting_room,
                  color: isToday
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.roomName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isToday ? "Today" : "Upcoming"} • ${reservation.timeSlot.displayTime}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
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
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     const Text(
          //       'Other Reservations',
          //       style: TextStyle(
          //         fontSize: 18,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //     TextButton(
          //       onPressed: () {
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           const SnackBar(content: Text('All reservations view coming soon!')),
          //         );
          //       },
          //       child: const Text('See All'),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 8),
          upcomingReservations.isEmpty
              ? EmptyState(
            message: 'You have no other upcoming reservations',
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

  Widget _buildFeaturedBooksSection(List<OpenLibraryBook>? books, {
    bool isLoading = false,
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always show title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Featured Books',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 2),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Loading
          if (isLoading)
            const SizedBox(
              height: 120,
              child: Center(child: LoadingIndicator(message: 'Loading featured books...')),
            )

          // Error
          else if (errorMessage != null)
            SizedBox(
              height: 150,
              child: ErrorDisplay(
                message: errorMessage,
                onRetry: onRetry,
              ),
            )

          // Empty
          else if (books == null || books.isEmpty)
              EmptyState(
                message: 'No featured books available',
                icon: Icons.book,
                actionText: 'Browse Books',
                onAction: () => setState(() => _currentIndex = 2),
              )

            // Data
            else
              SizedBox(
                height: 230,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 140,
                        child: _buildImprovedBookCard(book),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildImprovedBookCard(OpenLibraryBook book) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OpenLibraryBookDetailsScreen(book: book),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book cover
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: book.thumbnailUrl.isNotEmpty
                ? Image.network(
              book.thumbnailUrl,
              height: 160,
              width: 140,
              fit: BoxFit.cover,
            )
                : Container(
              height: 160,
              width: 140,
              color: Colors.grey.shade300,
              child: const Icon(Icons.book),
            ),
          ),
          const SizedBox(height: 6),
          // Title
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          // Author
          if (book.authors.isNotEmpty)
            Text(
              book.authors.first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }

  Widget _buildResourcesSection(List<ResearchPaperResource> papers) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Research Papers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 3),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          papers.isEmpty
              ? EmptyState(
            message: 'No research papers available',
            icon: Icons.article,
            actionText: 'Browse Resources',
            onAction: () => setState(() => _currentIndex = 3),
          )
              : Column(
            children: papers.take(5).map((paper) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const Icon(Icons.article, color: Colors.blueAccent),
                  title: Text(
                    paper.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    paper.year.toString(),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Viewing: ${paper.title}')),
                    );
                  },
                ),
              );
            }).toList(),
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
