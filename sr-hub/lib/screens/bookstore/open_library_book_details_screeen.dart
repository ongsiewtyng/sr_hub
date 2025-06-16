// lib/screens/bookstore/open_library_book_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/open_library_models.dart';
import '../../providers/open_library_provider.dart';
import '../../widgets/loading_indicator.dart';

class OpenLibraryBookDetailsScreen extends ConsumerStatefulWidget {
  final OpenLibraryBook book;

  const OpenLibraryBookDetailsScreen({Key? key, required this.book}) : super(key: key);

  @override
  ConsumerState<OpenLibraryBookDetailsScreen> createState() => _OpenLibraryBookDetailsScreenState();
}

class _OpenLibraryBookDetailsScreenState extends ConsumerState<OpenLibraryBookDetailsScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final bookDetailsAsync = ref.watch(openLibraryBookDetailsProvider(widget.book.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorite ? 'Added to favorites!' : 'Removed from favorites!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover and Basic Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Cover
                Container(
                  width: 140,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.book.coverUrl != null
                        ? Image.network(
                      widget.book.coverUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: LoadingIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.book,
                            size: 64,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.book,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Book Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.book.authors.isNotEmpty) ...[
                        Text(
                          'By ${widget.book.authors.join(', ')}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (widget.book.firstPublishYear != null) ...[
                        _buildInfoRow('Published', widget.book.firstPublishYear.toString()),
                      ],
                      if (widget.book.publisher != null) ...[
                        _buildInfoRow('Publisher', widget.book.publisher!),
                      ],
                      if (widget.book.pageCount != null) ...[
                        _buildInfoRow('Pages', widget.book.pageCount.toString()),
                      ],
                      if (widget.book.languages.isNotEmpty) ...[
                        _buildInfoRow('Language', widget.book.languages.first.toUpperCase()),
                      ],
                      const SizedBox(height: 12),
                      if (widget.book.ratingsAverage != null) ...[
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              return Icon(
                                index < (widget.book.ratingsAverage ?? 0).round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              );
                            }),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.book.ratingsAverage!.toStringAsFixed(1)} (${widget.book.ratingsCount ?? 0} reviews)',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openInOpenLibrary(),
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('View on Open Library'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addToReadingList(),
                    icon: const Icon(Icons.bookmark_add),
                    label: const Text('Add to List'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Book Description
            bookDetailsAsync.when(
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => const SizedBox.shrink(),
              data: (detailedBook) {
                final description = detailedBook?.description ?? widget.book.description;
                if (description != null && description.isNotEmpty) {
                  return _buildSection(
                    'Description',
                    Text(
                      description,
                      style: const TextStyle(height: 1.6),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Subjects/Categories
            if (widget.book.subjects.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSection(
                'Subjects',
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.book.subjects.take(10).map((subject) {
                    return Chip(
                      label: Text(
                        subject,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      side: BorderSide(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // More by this author
            if (widget.book.authors.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildMoreByAuthorSection(),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildMoreByAuthorSection() {
    final author = widget.book.authors.first;
    final authorBooksAsync = ref.watch(openLibraryAuthorBooksProvider(author));

    return _buildSection(
      'More by $author',
      authorBooksAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Text('Failed to load books by $author'),
        data: (books) {
          final otherBooks = books.where((book) => book.key != widget.book.key).take(5).toList();

          if (otherBooks.isEmpty) {
            return const Text('No other books found by this author');
          }

          return SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: otherBooks.length,
              itemBuilder: (context, index) {
                final book = otherBooks[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OpenLibraryBookDetailsScreen(book: book),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: book.coverUrl != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                book.thumbnailUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.book, size: 32);
                                },
                              ),
                            )
                                : const Icon(Icons.book, size: 32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (book.firstPublishYear != null)
                          Text(
                            book.firstPublishYear.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openInOpenLibrary() async {
    final url = 'https://openlibrary.org${widget.book.key}';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }

  void _addToReadingList() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to reading list!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}