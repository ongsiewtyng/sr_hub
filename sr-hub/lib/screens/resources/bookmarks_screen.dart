// lib/screens/resources/bookmarks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/resource_models.dart';
import '../../providers/resource_providers.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';
import '../../widgets/resource_card.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkCounts = ref.watch(bookmarkCountsProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'My Bookmarks'),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.all_inclusive, size: 18),
                      const SizedBox(width: 4),
                      const Text('All'),
                      bookmarkCounts.when(
                        data: (counts) {
                          final totalCount = counts.values.fold(0, (sum, count) => sum + count);
                          if (totalCount > 0) {
                            return Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                totalCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.book, size: 18),
                      const SizedBox(width: 4),
                      const Text('Books'),
                      bookmarkCounts.when(
                        data: (counts) {
                          final bookCount = counts[ResourceType.book] ?? 0;
                          if (bookCount > 0) {
                            return Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                bookCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.article, size: 18),
                      const SizedBox(width: 4),
                      const Text('Papers'),
                      bookmarkCounts.when(
                        data: (counts) {
                          final paperCount = counts[ResourceType.researchPaper] ?? 0;
                          if (paperCount > 0) {
                            return Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                paperCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookmarksList(null),
                _buildBookmarksList(ResourceType.book),
                _buildBookmarksList(ResourceType.researchPaper),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(ResourceType? type) {
    final bookmarksAsync = ref.watch(bookmarksProvider(type));

    return bookmarksAsync.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => ErrorDisplay(
        message: 'Failed to load bookmarks: $error',
        onRetry: () => ref.invalidate(bookmarksProvider(type)),
      ),
      data: (bookmarks) {
        if (bookmarks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    type == null
                        ? 'No bookmarks yet'
                        : type == ResourceType.book
                        ? 'No bookmarked books'
                        : 'No bookmarked papers',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start exploring resources and bookmark your favorites!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Explore Resources'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(bookmarksProvider(type));
            ref.invalidate(bookmarkCountsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ResourceCard(resource: bookmarks[index]),
              );
            },
          ),
        );
      },
    );
  }
}