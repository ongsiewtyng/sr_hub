import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resource_models.dart';
import '../services/bookmark_service.dart';

/// All user bookmarks (all types)
final userBookmarksProvider = FutureProvider<List<Resource>>((ref) async {
  return await BookmarkService.getBookmarkedResources();
});

/// (Your existing state for toggling works as is)
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
