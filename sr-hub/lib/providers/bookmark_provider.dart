import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

final readingListProvider = FutureProvider<List<BookResource>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('reading_list')
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();

    return BookResource(
      id: (data['id'] ?? doc.id).toString(),
      title: (data['title'] ?? 'Untitled').toString(),
      authors: data['authors'] is List
          ? List<String>.from(data['authors'] as List)
          : <String>[],
      description: null, // your doc doesn't have this yet
      imageUrl: data['coverUrl']?.toString(),
      publishedDate: null, // your doc doesn't have this yet
      sourceUrl: 'https://openlibrary.org/works/${data['id'] ?? ''}',
      isbn: null,
      publisher: null,
      pageCount: null,
      subjects: [],
      rating: null,
      previewLink: null,
      isBookmarked: true,
    );
  }).toList();
});


// ✅ Combined Favorites provider using Future.wait
final combinedFavoritesProvider = FutureProvider<List<Resource>>((ref) async {
  try {
    final results = await Future.wait([
      ref.watch(userBookmarksProvider.future),
      ref.watch(readingListProvider.future),
    ]);

    final bookmarks = results[0] ?? [];
    final readingList = results[1] ?? [];

    return [...bookmarks, ...readingList];
  } catch (e, st) {
    print('❌ Combined favorites error: $e\n$st');
    return []; // fallback to empty list so UI still works
  }
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
