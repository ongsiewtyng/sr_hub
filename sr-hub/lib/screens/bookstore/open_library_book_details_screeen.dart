import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/open_library_models.dart';
import '../../providers/open_library_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/purchase_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/buy_book_bottom_sheet.dart';

class OpenLibraryBookDetailsScreen extends ConsumerStatefulWidget {
  final OpenLibraryBook book;

  const OpenLibraryBookDetailsScreen({Key? key, required this.book}) : super(key: key);

  @override
  ConsumerState<OpenLibraryBookDetailsScreen> createState() => _OpenLibraryBookDetailsScreenState();
}

class _OpenLibraryBookDetailsScreenState extends ConsumerState<OpenLibraryBookDetailsScreen> {
  bool _isFavorite = false;
  bool _isInReadingList = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _checkReadingListStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;
    final isFav = await FirestoreService().isBookFavoritedInStats(userId, widget.book.id);
    setState(() => _isFavorite = isFav);
  }

  Future<void> _checkReadingListStatus() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('reading_list')
        .doc(widget.book.id)
        .get();

    setState(() => _isInReadingList = doc.exists);
  }

  @override
  Widget build(BuildContext context) {
    final bookDetailsAsync = ref.watch(openLibraryBookDetailsProvider(widget.book.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
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
            // Book cover + info row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover
                Container(
                  width: 140,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.book.coverUrl != null
                        ? Image.network(widget.book.coverUrl!, fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: LoadingIndicator());
                    }, errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.grey.shade300, child: const Icon(Icons.book, size: 64, color: Colors.grey));
                    })
                        : Container(color: Colors.grey.shade300, child: const Icon(Icons.book, size: 64, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 20),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.book.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (widget.book.authors.isNotEmpty)
                        Text('By ${widget.book.authors.join(', ')}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      if (widget.book.firstPublishYear != null) _buildInfoRow('Published', widget.book.firstPublishYear.toString()),
                      if (widget.book.publisher != null) _buildInfoRow('Publisher', widget.book.publisher!),
                      if (widget.book.pageCount != null) _buildInfoRow('Pages', widget.book.pageCount.toString()),
                      if (widget.book.languages.isNotEmpty) _buildInfoRow('Language', widget.book.languages.first.toUpperCase()),
                      const SizedBox(height: 12),
                      if (widget.book.ratingsAverage != null)
                        Row(
                          children: [
                            ...List.generate(5, (i) => Icon(i < widget.book.ratingsAverage!.round() ? Icons.star : Icons.star_border, color: Colors.amber, size: 20)),
                            const SizedBox(width: 8),
                            Text('${widget.book.ratingsAverage!.toStringAsFixed(1)} (${widget.book.ratingsCount ?? 0} reviews)',
                                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showBuyBottomSheet,
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Buy Book'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleReadingList,
                    icon: Icon(_isInReadingList ? Icons.check : Icons.bookmark_add),
                    label: Text(_isInReadingList ? 'Added to List' : 'Add to List'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description
            bookDetailsAsync.when(
              loading: () => const Center(child: LoadingIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (details) {
                final description = details?.description ?? widget.book.description;
                return (description != null && description.isNotEmpty)
                    ? _buildSection('Description', Text(description, style: const TextStyle(height: 1.6)))
                    : const SizedBox.shrink();
              },
            ),

            // Subjects
            if (widget.book.subjects.isNotEmpty)
              _buildSection(
                'Subjects',
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.book.subjects.take(10).map((s) {
                    return Chip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                    );
                  }).toList(),
                ),
              ),

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
          SizedBox(width: 80, child: Text('$label:', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildMoreByAuthorSection() {
    final author = widget.book.authors.first;
    final authorBooksAsync = ref.watch(openLibraryAuthorBooksProvider(author));
    return _buildSection('More by $author', authorBooksAsync.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (_, __) => Text('Failed to load books by $author'),
      data: (books) {
        final others = books.where((b) => b.key != widget.book.key).take(5).toList();
        if (others.isEmpty) return const Text('No other books found by this author');

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: others.length,
            itemBuilder: (context, i) {
              final book = others[i];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => OpenLibraryBookDetailsScreen(book: book)));
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
                            child: Image.network(book.thumbnailUrl, fit: BoxFit.cover, width: double.infinity),
                          )
                              : const Icon(Icons.book, size: 32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(book.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (book.firstPublishYear != null)
                        Text(book.firstPublishYear.toString(), style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ));
  }

  void _toggleFavorite() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    if (_isFavorite) {
      // Remove from favorites
      await FirestoreService().removeFromFavoritesInStats(userId, widget.book.id);

      // Remove from reading list (sync)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('reading_list')
          .doc(widget.book.id)
          .delete();

      setState(() {
        _isFavorite = false;
        _isInReadingList = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites and reading list'), duration: Duration(seconds: 2)),
      );
    } else {
      // Add to favorites
      await FirestoreService().addToFavoritesInStats(userId, widget.book);

      // Add to reading list (sync)
      await FirestoreService().addToReadingList(userId, widget.book);

      setState(() {
        _isFavorite = true;
        _isInReadingList = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to favorites and reading list!'), duration: Duration(seconds: 2)),
      );
    }
  }

  void _toggleReadingList() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    if (_isInReadingList) {
      // Remove from reading list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('reading_list')
          .doc(widget.book.id)
          .delete();

      // Also remove from favorites
      await FirestoreService().removeFromFavoritesInStats(userId, widget.book.id);

      setState(() {
        _isInReadingList = false;
        _isFavorite = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from reading list and favorites'), duration: Duration(seconds: 2)),
      );
    } else {
      // Add to reading list
      await FirestoreService().addToReadingList(userId, widget.book);

      // Also add to favorites
      await FirestoreService().addToFavoritesInStats(userId, widget.book);

      setState(() {
        _isInReadingList = true;
        _isFavorite = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to reading list and favorites!'), duration: Duration(seconds: 2)),
      );
    }
  }

  void _showBuyBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => BuyBookBottomSheet(book: widget.book),
      ),
    );
  }
}
