import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resource_models.dart';
import '../services/semantic_scholar_service.dart';
import '../services/bookmark_service.dart';

/// 🔍 Search Query Provider
final resourceSearchQueryProvider = StateProvider<String>((ref) => '');

/// 🎛️ Filter Providers
final selectedYearRangeProvider = StateProvider<RangeValues?>((ref) => null);
final selectedMinCitationsProvider = StateProvider<int?>((ref) => null);
final openAccessOnlyProvider = StateProvider<bool>((ref) => false);
final selectedFieldOfStudyProvider = StateProvider<String?>((ref) => null);
final selectedAuthorProvider = StateProvider<String?>((ref) => null);
final selectedSubjectsProvider = StateProvider<List<String>>((ref) => []);

/// 🔥 Trending Papers Provider
final trendingPapersProvider = FutureProvider<List<ResearchPaperResource>>((ref) async {
  try {
    return await SemanticScholarService.getTrendingPapers();
  } catch (e) {
    print('Trending papers provider error: $e');
    return [];
  }
});

/// 📄 Paginated Search Provider
final paperSearchPaginatedProvider = FutureProvider.family<List<ResearchPaperResource>, ({String query, int page, int limit})>((ref, args) async {
  final query = args.query.trim();
  if (query.isEmpty) return [];

  final yearRange = ref.watch(selectedYearRangeProvider);
  final minCitations = ref.watch(selectedMinCitationsProvider);
  final openAccess = ref.watch(openAccessOnlyProvider);
  final field = ref.watch(selectedFieldOfStudyProvider);
  final author = ref.watch(selectedAuthorProvider);
  final subjects = ref.watch(selectedSubjectsProvider);

  return await SemanticScholarService.searchPapers(
    query: query,
    offset: args.page * args.limit,
    limit: args.limit,
    yearRange: yearRange,
    minCitations: minCitations,
    openAccessOnly: openAccess,
    fieldOfStudy: field,
    author: author,
    subjects: subjects,
  );
});

// Bookmarks
final bookmarksProvider = FutureProvider<List<Resource>>((ref) async {
  try {
    return await BookmarkService.getBookmarkedResources(type: ResourceType.researchPaper);
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

final bookmarkStateProvider = StateNotifierProvider<BookmarkStateNotifier, Map<String, bool>>((ref) {
  return BookmarkStateNotifier();
});


class BookmarkStateNotifier extends StateNotifier<Map<String, bool>> {
  BookmarkStateNotifier() : super({});

  Future<void> toggleBookmark(Resource resource) async {
    final isCurrentlyBookmarked = state[resource.id] ?? false;
    state = {...state, resource.id: !isCurrentlyBookmarked};

    try {
      bool success = isCurrentlyBookmarked
          ? await BookmarkService.removeBookmark(resource.id)
          : await BookmarkService.addBookmark(resource);

      if (!success) {
        state = {...state, resource.id: isCurrentlyBookmarked}; // rollback
      }
    } catch (e) {
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
