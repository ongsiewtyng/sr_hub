// lib/widgets/buy_book_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/open_library_models.dart';
import '../services/purchase_service.dart';
import '../services/google_books_service.dart';

class BuyBookBottomSheet extends ConsumerStatefulWidget {
  final OpenLibraryBook book;

  const BuyBookBottomSheet({Key? key, required this.book}) : super(key: key);

  @override
  ConsumerState<BuyBookBottomSheet> createState() => _BuyBookBottomSheetState();
}

class _BuyBookBottomSheetState extends ConsumerState<BuyBookBottomSheet> {
  bool _isLoading = false;
  String? _previewLink;
  Map<String, bool> _availableFormats = {};

  @override
  void initState() {
    super.initState();
    _loadGoogleBooksData();
  }

  Future<void> _loadGoogleBooksData() async {
    setState(() => _isLoading = true);

    try {
      final googleBookData = await GoogleBooksService.searchBook(
        title: widget.book.title,
        author: widget.book.authors.isNotEmpty ? widget.book.authors.first : null,
        isbn: widget.book.isbn.isNotEmpty ? widget.book.isbn.first : null,
      );

      if (mounted) {
        setState(() {
          _previewLink = GoogleBooksService.extractPreviewLink(googleBookData);
          _availableFormats = GoogleBooksService.extractAvailableFormats(googleBookData);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableFormats = {
            'epub': widget.book.hasEpub,
            'pdf': widget.book.hasPdf,
            'print': widget.book.hasPrint,
          };
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final buyLinks = PurchaseService.generateBuyLinks(
      title: widget.book.title,
      authors: widget.book.authors,
      isbn: widget.book.isbn.isNotEmpty ? widget.book.isbn.first : null,
      previewLink: _previewLink,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  'Buy "${widget.book.title}"',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.book.authors.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'by ${widget.book.authors.join(', ')}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Online Stores Section
                    _buildSectionHeader('Buy Online'),
                    const SizedBox(height: 12),

                    _buildBuyOption(
                      title: 'Amazon',
                      subtitle: 'Global marketplace',
                      icon: Icons.shopping_cart,
                      color: Colors.orange,
                      onTap: () => _openLink(buyLinks['amazon']!),
                    ),

                    _buildBuyOption(
                      title: 'Google Books',
                      subtitle: _previewLink != null ? 'Preview available' : 'Search on Google Books',
                      icon: Icons.book,
                      color: Colors.blue,
                      onTap: () => _openLink(buyLinks['googleBooks']!),
                    ),

                    const SizedBox(height: 20),

                    // Local Stores Section
                    _buildSectionHeader('Local Bookstores'),
                    const SizedBox(height: 12),

                    _buildBuyOption(
                      title: 'MPH Bookstores',
                      subtitle: 'Malaysia\'s leading bookstore',
                      icon: Icons.store,
                      color: Colors.red,
                      onTap: () => _openLink(buyLinks['mph']!),
                    ),

                    _buildBuyOption(
                      title: 'Popular Bookstore',
                      subtitle: 'Popular bookstore chain',
                      icon: Icons.store,
                      color: Colors.green,
                      onTap: () => _openLink(buyLinks['popular']!),
                    ),

                    _buildBuyOption(
                      title: 'Kinokuniya',
                      subtitle: 'Japanese bookstore chain',
                      icon: Icons.store,
                      color: Colors.purple,
                      onTap: () => _openLink(buyLinks['kinokuniya']!),
                    ),

                    const SizedBox(height: 20),

                    // Mark as Purchased Section
                    _buildSectionHeader('Already Own This Book?'),
                    const SizedBox(height: 12),

                    if (_availableFormats['epub'] == true)
                      _buildPurchaseOption(
                        title: 'Mark as Purchased (ePub)',
                        icon: Icons.android,
                        color: Colors.green,
                        format: 'epub',
                      ),

                    if (_availableFormats['pdf'] == true)
                      _buildPurchaseOption(
                        title: 'Mark as Purchased (PDF)',
                        icon: Icons.picture_as_pdf,
                        color: Colors.red,
                        format: 'pdf',
                      ),

                    if (_availableFormats['print'] == true)
                      _buildPurchaseOption(
                        title: 'Mark as Purchased (Print)',
                        icon: Icons.menu_book,
                        color: Colors.brown,
                        format: 'print',
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildBuyOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.open_in_new, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPurchaseOption({
    required String title,
    required IconData icon,
    required Color color,
    required String format,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Add to your library'),
        trailing: const Icon(Icons.check_circle_outline),
        onTap: () => _markAsPurchased(format),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final success = await PurchaseService.openLink(url);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open link'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAsPurchased(String format) async {
    final success = await PurchaseService.markAsPurchased(
      book: widget.book,
      format: format,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${widget.book.title}" marked as purchased ($format)'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Library',
              onPressed: () {
                // Navigate to purchased books library
                // You can implement this navigation
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to mark as purchased'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}