// lib/widgets/resource_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/resource_models.dart';
import '../providers/resource_providers.dart';
import '../screens/webview/webview_screen.dart';

class ResourceCard extends ConsumerStatefulWidget {
  final Resource resource;
  final VoidCallback? onTap;
  final VoidCallback? onSave;

  const ResourceCard({
    Key? key,
    required this.resource,
    this.onTap,
    this.onSave,
  }) : super(key: key);

  @override
  ConsumerState<ResourceCard> createState() => _ResourceCardState();
}

class _ResourceCardState extends ConsumerState<ResourceCard> {
  @override
  void initState() {
    super.initState();
    // Load bookmark status when card is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookmarkStateProvider.notifier).loadBookmarkStatus(widget.resource.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkState = ref.watch(bookmarkStateProvider);
    final isBookmarked = bookmarkState[widget.resource.id] ?? widget.resource.isBookmarked;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap ?? () => _openResource(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resource Image/Icon
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildResourceImage(),
              ),
              const SizedBox(width: 16),

              // Resource Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Bookmark
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.resource.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: widget.onSave ?? () => _toggleBookmark(),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: isBookmarked ? Theme.of(context).primaryColor : Colors.grey,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Authors
                    if (widget.resource.authors.isNotEmpty)
                      Text(
                        'By ${widget.resource.authors.join(', ')}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 8),

                    // Resource Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTypeColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getTypeColor().withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTypeIcon(),
                            size: 14,
                            color: _getTypeColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTypeLabel(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getTypeColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Resource-specific details
                    _buildResourceSpecificDetails(),

                    const SizedBox(height: 8),

                    // Description
                    if (widget.resource.description != null &&
                        widget.resource.description!.isNotEmpty)
                      Text(
                        widget.resource.description!,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceImage() {
    if (widget.resource.imageUrl != null && widget.resource.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.resource.imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildImageFallback();
          },
        ),
      );
    }

    return _buildImageFallback();
  }

  Widget _buildImageFallback() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getTypeIcon(),
        size: 48,
        color: Colors.grey.shade600,
      ),
    );
  }


  Widget _buildResourceSpecificDetails() {
    if (widget.resource is BookResource) {
      final book = widget.resource as BookResource;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (book.publishedDate != null)
            _buildDetailRow(Icons.calendar_today, '${book.publishedDate!.year}'),
          if (book.pageCount != null)
            _buildDetailRow(Icons.menu_book, '${book.pageCount} pages'),
          if (book.rating != null)
            _buildDetailRow(Icons.star, '${book.rating!.toStringAsFixed(1)} rating'),
          if (book.subjects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: book.subjects.take(3).map((subject) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subject,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    } else if (widget.resource is ResearchPaperResource) {
      final paper = widget.resource as ResearchPaperResource;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (paper.year != null)
            _buildDetailRow(Icons.calendar_today, '${paper.year}'),
          if (paper.venue != null && paper.venue!.isNotEmpty)
            _buildDetailRow(Icons.location_on, paper.venue!),
          if (paper.citationCount != null)
            _buildDetailRow(Icons.format_quote, '${paper.citationCount} citations'),
          if (paper.keywords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: paper.keywords.take(3).map((keyword) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      keyword,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (widget.resource.type) {
      case ResourceType.book:
        return Icons.book;
      case ResourceType.researchPaper:
        return Icons.article;
    }
  }

  String _getTypeLabel() {
    switch (widget.resource.type) {
      case ResourceType.book:
        return 'Book';
      case ResourceType.researchPaper:
        return 'Research Paper';
    }
  }

  Color _getTypeColor() {
    switch (widget.resource.type) {
      case ResourceType.book:
        return Colors.blue;
      case ResourceType.researchPaper:
        return Colors.green;
    }
  }

  Future<void> _toggleBookmark() async {
    await ref.read(bookmarkStateProvider.notifier).toggleBookmark(widget.resource);
    ref.invalidate(bookmarkCountsProvider);

    if (mounted) {
      final isNowBookmarked = ref.read(bookmarkStateProvider)[widget.resource.id] ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowBookmarked ? '✅ Added to bookmarks' : '❌ Removed from bookmarks',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: isNowBookmarked ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _openResource() async {
    final url = widget.resource.sourceUrl;

    try {
      final uri = Uri.parse(url);
      if (uri.scheme.startsWith('http')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WebViewScreen(url: url, title: widget.resource.title),
          ),
        );
      } else {
        _showError('Invalid resource link');
      }
    } catch (e) {
      _showError('Error opening resource: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }


}
