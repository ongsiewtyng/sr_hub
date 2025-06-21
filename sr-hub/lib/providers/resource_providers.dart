// lib/providers/resource_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resource_models.dart';
import '../services/open_library_service.dart';
import '../services/semantic_scholar_service.dart';
import '../services/bookmark_service.dart';

// Search query and filters
final resourceSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedResourceTypeProvider = StateProvider<ResourceType?>((ref) => null);

// Book search provider
final bookSearchProvider = FutureProvider.family<List<BookResource>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];

  try {
    final response = await OpenLibraryService.searchBooks(query: query.trim());
    if (response == null) return [];

    return response.docs.map((book) => BookResource.fromOpenLibrary({
      'key': book.key,
      'title': book.title,
      'author_name': book.authors,
      'cover_i': book.coverUrl?.contains('/id/') == true
          ? int.tryParse(book.coverUrl!.split('/id/')[1].split('-')[0])
          : null,
      'first_publish_year': book.firstPublishYear,
      'subject': book.subjects,
      'ratings_average': book.ratingsAverage,
      'isbn': book.isbn,
      'publisher': book.publisher != null ? [book.publisher] : null,
      'number_of_pages_median': book.pageCount,
      'description': book.description,
    })).toList();
  } catch (e) {
    print('Book search provider error: $e');
    return [];
  }
});

// Research paper search provider
final paperSearchProvider = FutureProvider.family<List<ResearchPaperResource>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];

  try {
    return await SemanticScholarService.searchPapers(query: query.trim());
  } catch (e) {
    print('Paper search provider error: $e');
    return [];
  }
});

// Combined search provider
final combinedSearchProvider = FutureProvider.family<List<Resource>, String>((ref, query) async {
  final selectedType = ref.watch(selectedResourceTypeProvider);
  final trimmedQuery = query.trim();

  print('🔍 [combinedSearchProvider] query="$trimmedQuery"');
  print('🎯 Selected type: $selectedType');

  try {
    // If no search query, return trending
    if (trimmedQuery.isEmpty) {
      print('📈 No query entered — loading trending resources...');
      if (selectedType == ResourceType.book) {
        final books = await ref.watch(trendingBooksProvider.future);
        print('📘 Trending books loaded: ${books.length}');
        return books.cast<Resource>();
      } else if (selectedType == ResourceType.researchPaper) {
        final papers = await ref.watch(trendingPapersProvider.future);
        print('📄 Trending papers loaded: ${papers.length}');
        return papers.cast<Resource>();
      } else {
        final books = await ref.watch(trendingBooksProvider.future);
        final papers = await ref.watch(trendingPapersProvider.future);
        print('📘+📄 Trending books: ${books.length}, papers: ${papers.length}');
        return [...books, ...papers];
      }
    }

    // Search case
    if (selectedType == ResourceType.book) {
      print('🔎 Searching books...');
      final books = await ref.watch(bookSearchProvider(trimmedQuery).future);
      print('📘 Books found: ${books.length}');
      return books.cast<Resource>();
    } else if (selectedType == ResourceType.researchPaper) {
      print('🔎 Searching research papers...');
      final papers = await ref.watch(paperSearchProvider(trimmedQuery).future);
      print('📄 Papers found: ${papers.length}');
      return papers.cast<Resource>();
    } else {
      print('🔎 Searching both books and papers...');
      final results = await Future.wait([
        ref.watch(bookSearchProvider(trimmedQuery).future),
        ref.watch(paperSearchProvider(trimmedQuery).future),
      ]);

      final books = results[0] as List<BookResource>;
      final papers = results[1] as List<ResearchPaperResource>;
      print('📘 Books: ${books.length}, 📄 Papers: ${papers.length}');

      return [...books, ...papers];
    }
  } catch (e, stack) {
    print('❌ Error in combinedSearchProvider: $e');
    print(stack);
    return [];
  }
});


// Trending resources providers
final trendingBooksProvider = FutureProvider<List<BookResource>>((ref) async {
  try {
    final books = await OpenLibraryService.getTrendingBooks();
    return books.map((book) => BookResource.fromOpenLibrary({
      'key': book.key,
      'title': book.title,
      'author_name': book.authors,
      'cover_i': book.coverUrl?.contains('/id/') == true
          ? int.tryParse(book.coverUrl!.split('/id/')[1].split('-')[0])
          : null,
      'first_publish_year': book.firstPublishYear,
      'subject': book.subjects,
      'ratings_average': book.ratingsAverage,
      'isbn': book.isbn,
      'publisher': book.publisher != null ? [book.publisher] : null,
      'number_of_pages_median': book.pageCount,
      'description': book.description,
    })).toList();
  } catch (e) {
    print('Trending books provider error: $e');
    return [];
  }
});

final trendingPapersProvider = FutureProvider<List<ResearchPaperResource>>((ref) async {
  try {
    return await SemanticScholarService.getTrendingPapers();
  } catch (e) {
    print('Trending papers provider error: $e');
    return [];
  }
});

// Bookmarks providers
final bookmarksProvider = FutureProvider.family<List<Resource>, ResourceType?>((ref, type) async {
  try {
    return await BookmarkService.getBookmarkedResources(type: type);
  } catch (e) {
    print('Bookmarks provider error: $e');
    return [];
  }
});

final bookmarkCountsProvider = FutureProvider<Map<ResourceType, int>>((ref) async {
  try {
    return await BookmarkService.getBookmarkCounts();
  } catch (e) {
    print('Bookmark counts provider error: $e');
    return {};
  }
});

// Bookmark state provider
final bookmarkStateProvider = StateNotifierProvider<BookmarkStateNotifier, Map<String, bool>>((ref) {
  return BookmarkStateNotifier();
});

class BookmarkStateNotifier extends StateNotifier<Map<String, bool>> {
  BookmarkStateNotifier() : super({});

  Future<void> toggleBookmark(Resource resource) async {
    final isCurrentlyBookmarked = state[resource.id] ?? false;

    // Optimistically update UI
    state = {...state, resource.id: !isCurrentlyBookmarked};

    try {
      bool success;
      if (isCurrentlyBookmarked) {
        success = await BookmarkService.removeBookmark(resource.id);
      } else {
        success = await BookmarkService.addBookmark(resource);
      }

      if (!success) {
        // Revert on failure
        state = {...state, resource.id: isCurrentlyBookmarked};
      }
    } catch (e) {
      // Revert on error
      state = {...state, resource.id: isCurrentlyBookmarked};
      print('Bookmark toggle error: $e');
    }
  }

  Future<void> loadBookmarkStatus(String resourceId) async {
    try {
      final isBookmarked = await BookmarkService.isBookmarked(resourceId);
      state = {...state, resourceId: isBookmarked};
    } catch (e) {
      print('Load bookmark status error: $e');
    }
  }

  void setBookmarkStatus(String resourceId, bool isBookmarked) {
    state = {...state, resourceId: isBookmarked};
  }
}