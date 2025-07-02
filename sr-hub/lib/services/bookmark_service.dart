// lib/services/bookmark_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/resource_models.dart';

class BookmarkService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add bookmark
  static Future<bool> addBookmark(Resource resource, {String? notes}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final bookmarkId = '${user.uid}_${resource.id}';

      final bookmark = BookmarkData(
        id: bookmarkId,
        userId: user.uid,
        resourceId: resource.id,
        resourceType: resource.type,
        resourceData: resource.toJson(),
        createdAt: DateTime.now(),
        notes: notes,
      );

      await _firestore
          .collection('bookmarks')
          .doc(bookmarkId)
          .set(bookmark.toJson());

      print('✅ Bookmark added: ${resource.title}');
      return true;
    } catch (e) {
      print('❌ Bookmark add error: $e');
      return false;
    }
  }

  // Remove bookmark
  static Future<bool> removeBookmark(String resourceId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final bookmarkId = '${user.uid}_$resourceId';

      await _firestore
          .collection('bookmarks')
          .doc(bookmarkId)
          .delete();

      print('✅ Bookmark removed: $resourceId');
      return true;
    } catch (e) {
      print('❌ Bookmark remove error: $e');
      return false;
    }
  }

  // Check if resource is bookmarked
  static Future<bool> isBookmarked(String resourceId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final bookmarkId = '${user.uid}_$resourceId';

      final doc = await _firestore
          .collection('bookmarks')
          .doc(bookmarkId)
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ Bookmark check error: $e');
      return false;
    }
  }

  // Get all bookmarks for user
  static Future<List<BookmarkData>> getUserBookmarks({ResourceType? type}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      Query query = _firestore
          .collection('bookmarks')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true);

      if (type != null) {
        query = query.where('resourceType', isEqualTo: type.toString().split('.').last);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => BookmarkData.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      print('❌ User bookmarks fetch error: $e');
      return [];
    }
  }

  // Get bookmarked resources as Resource objects
  static Future<List<Resource>> getBookmarkedResources({ResourceType? type}) async {
    try {
      final bookmarks = await getUserBookmarks(type: type);
      final resources = <Resource>[];

      for (final bookmark in bookmarks) {
        Resource? resource;

        if (bookmark.resourceType == ResourceType.book) {
          resource = BookResource(
            id: bookmark.resourceData['id'] ?? '',
            title: bookmark.resourceData['title'] ?? '',
            authors: List<String>.from(bookmark.resourceData['authors'] ?? []),
            description: bookmark.resourceData['description'],
            imageUrl: bookmark.resourceData['imageUrl'],
            publishedDate: bookmark.resourceData['publishedDate'] != null
                ? DateTime.parse(bookmark.resourceData['publishedDate'])
                : null,
            sourceUrl: bookmark.resourceData['sourceUrl'] ?? '',
            isbn: bookmark.resourceData['isbn'],
            publisher: bookmark.resourceData['publisher'],
            pageCount: bookmark.resourceData['pageCount'],
            subjects: List<String>.from(bookmark.resourceData['subjects'] ?? []),
            rating: bookmark.resourceData['rating']?.toDouble(),
            previewLink: bookmark.resourceData['previewLink'],
            isBookmarked: true,
          );
        } else if (bookmark.resourceType == ResourceType.researchPaper) {
          resource = ResearchPaperResource(
            id: bookmark.resourceData['id'] ?? '',
            title: bookmark.resourceData['title'] ?? '',
            authors: List<String>.from(bookmark.resourceData['authors'] ?? []),
            description: bookmark.resourceData['description'],
            imageUrl: bookmark.resourceData['imageUrl'],
            publishedDate: bookmark.resourceData['publishedDate'] != null
                ? DateTime.parse(bookmark.resourceData['publishedDate'])
                : null,
            sourceUrl: bookmark.resourceData['sourceUrl'] ?? '',
            doi: bookmark.resourceData['doi'],
            venue: bookmark.resourceData['venue'],
            citationCount: bookmark.resourceData['citationCount'],
            keywords: List<String>.from(bookmark.resourceData['keywords'] ?? []),
            abstractText: bookmark.resourceData['abstractText'],
            pdfUrl: bookmark.resourceData['pdfUrl'],
            year: bookmark.resourceData['year'],
            isBookmarked: true,
          );
        }

        if (resource != null) {
          resources.add(resource);
        }
      }

      return resources;
    } catch (e) {
      print('❌ Bookmarked resources fetch error: $e');
      return [];
    }
  }

  // Update bookmark notes
  static Future<bool> updateBookmarkNotes(String resourceId, String notes) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final bookmarkId = '${user.uid}_$resourceId';

      await _firestore
          .collection('bookmarks')
          .doc(bookmarkId)
          .update({'notes': notes});

      return true;
    } catch (e) {
      print('❌ Bookmark notes update error: $e');
      return false;
    }
  }

  // Get bookmark count by type
  static Future<Map<ResourceType, int>> getBookmarkCounts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final snapshot = await _firestore
          .collection('bookmarks')
          .where('userId', isEqualTo: user.uid)
          .get();

      final counts = <ResourceType, int>{
        ResourceType.book: 0,
        ResourceType.researchPaper: 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final typeString = data['resourceType'] as String?;
        if (typeString != null) {
          final type = ResourceType.values.firstWhere(
                (e) => e.toString() == 'NewResourceType.$typeString',
            orElse: () => ResourceType.book,
          );
          counts[type] = (counts[type] ?? 0) + 1;
        }
      }

      return counts;
    } catch (e) {
      print('❌ Bookmark counts error: $e');
      return {};
    }
  }

}