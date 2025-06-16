// lib/screens/bookstore/bookstore_homepage_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/open_library_provider.dart';
import '../../models/open_library_models.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';
import 'open_library_book_details_screeen.dart';


class BookstoreHomepageScreen extends ConsumerStatefulWidget {
  const BookstoreHomepageScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BookstoreHomepageScreen> createState() => _BookstoreHomepageScreenState();
}

class _BookstoreHomepageScreenState extends ConsumerState<BookstoreHomepageScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(openLibrarySearchQueryProvider.notifier).state = query;
    }
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(openLibrarySearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(openLibrarySearchQueryProvider);
    final trendingBooksAsync = ref.watch(openLibraryTrendingProvider);
    final searchResultsAsync = searchQuery.isNotEmpty
        ? ref.watch(openLibrarySearchProvider(searchQuery))
        : null;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Open Library Bookstore'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(openLibraryTrendingProvider);
          if (searchQuery.isNotEmpty) {
            ref.invalidate(openLibrarySearchProvider(searchQuery));
          }
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search books, authors, subjects...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _performSearch(),
                        onChanged: (value) {
                          if (value.isEmpty) {
                            _clearSearch();
                          }
                        },
                      ),
                    ),
                    if (searchQuery.isNotEmpty)
                      IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.clear),
                      ),
                    IconButton(
                      onPressed: _performSearch,
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Search Results or Trending Books
              if (searchResultsAsync != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Search Results for "$searchQuery"',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _clearSearch,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                searchResultsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: LoadingIndicator(),
                    ),
                  ),
                  error: (error, stack) => ErrorDisplay(
                    message: 'Failed to search books: $error',
                    onRetry: () => ref.invalidate(openLibrarySearchProvider(searchQuery)),
                  ),
                  data: (books) {
                    if (books.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text('No books found'),
                              const SizedBox(height: 8),
                              Text(
                                'Try different search terms or browse our trending books below',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _clearSearch,
                                child: const Text('Browse Trending Books'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Found ${books.length} books',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBookGrid(books),
                      ],
                    );
                  },
                ),
              ] else ...[
                // Trending Books Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trending Books',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(openLibraryTrendingProvider);
                      },
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                trendingBooksAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: LoadingIndicator(),
                    ),
                  ),
                  error: (error, stack) => ErrorDisplay(
                    message: 'Failed to load trending books: $error',
                    onRetry: () => ref.invalidate(openLibraryTrendingProvider),
                  ),
                  data: (books) {
                    if (books.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No trending books available'),
                        ),
                      );
                    }
                    return _buildBookGrid(books);
                  },
                ),
                const SizedBox(height: 32),

                // Popular Subjects Section
                Text(
                  'Browse by Subject',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSubjectsGrid(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookGrid(List<OpenLibraryBook> books) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildBookCard(book);
      },
    );
  }

  Widget _buildBookCard(OpenLibraryBook book) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OpenLibraryBookDetailsScreen(book: book),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: book.coverUrl != null
                      ? Image.network(
                    book.thumbnailUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.book,
                          size: 48,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                      : Container(
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.book,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            // Book Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (book.authors.isNotEmpty)
                      Text(
                        book.authors.first,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    if (book.firstPublishYear != null)
                      Text(
                        book.firstPublishYear.toString(),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        if (book.ratingsAverage != null) ...[
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            book.ratingsAverage!.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                        const Spacer(),
                        if (book.subjects.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              book.subjects.first,
                              style: TextStyle(
                                fontSize: 9,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsGrid() {
    final subjects = [
      {'name': 'Fiction', 'icon': Icons.auto_stories, 'color': Colors.blue},
      {'name': 'Science', 'icon': Icons.science, 'color': Colors.green},
      {'name': 'Technology', 'icon': Icons.computer, 'color': Colors.purple},
      {'name': 'History', 'icon': Icons.history_edu, 'color': Colors.brown},
      {'name': 'Philosophy', 'icon': Icons.psychology, 'color': Colors.indigo},
      {'name': 'Art', 'icon': Icons.palette, 'color': Colors.pink},
      {'name': 'Biography', 'icon': Icons.person, 'color': Colors.orange},
      {'name': 'Poetry', 'icon': Icons.format_quote, 'color': Colors.teal},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: () {
              _searchController.text = subject['name'] as String;
              _performSearch();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    subject['icon'] as IconData,
                    size: 28,
                    color: subject['color'] as Color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subject['name'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}