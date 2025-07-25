// lib/services/purchase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/open_library_models.dart';

class PurchaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mark book as purchased
  static Future<bool> markAsPurchased({
    required OpenLibraryBook book,
    required String format, // "epub", "pdf", "print"
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final purchaseData = {
        'bookId': book.id,
        'title': book.title,
        'authors': book.authors,
        'coverUrl': book.coverUrl,
        'format': format,
        'purchaseDate': FieldValue.serverTimestamp(),
        'status': 'purchased',
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('purchased_books')
          .doc(book.id)
          .set(purchaseData);

      print('✅ Book marked as purchased: ${book.title} ($format)');
      return true;
    } catch (e) {
      print('❌ Purchase marking error: $e');
      return false;
    }
  }

  // Check if book is purchased
  static Future<Map<String, dynamic>?> getPurchaseInfo(String bookId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('purchased_books')
          .doc(bookId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ Purchase check error: $e');
      return null;
    }
  }

  // Get all purchased books
  static Future<Map<String, dynamic>?> getPurchasedBooks(String bookId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('purchased_books')
          .doc(bookId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ Purchase check error: $e');
      // Return null instead of crashing when permissions are denied
      return null;
    }
  }

  // Generate buy links
  static Map<String, String> generateBuyLinks({
    required String title,
    required List<String> authors,
    String? isbn,
    String? previewLink,
  }) {
    final authorString = authors.isNotEmpty ? authors.join(' ') : '';
    final searchQuery = '$title $authorString'.trim();
    final encodedQuery = Uri.encodeComponent(searchQuery);
    final encodedTitle = Uri.encodeComponent(title);

    return {
      'amazon': 'https://www.amazon.com/s?k=$encodedQuery&i=stripbooks',
      'googleBooks': previewLink ?? 'https://books.google.com/books?q=$encodedQuery',
      'mph': 'https://mphonline.com/search?q=$encodedTitle',
    };
  }

  // Open external link
  static Future<bool> openLink(String url) async {
    try {
      final uri = Uri.parse(url);

      final result = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      return result;
    } catch (e) {
      print('❌ Error launching URL: $e');
      return false;
    }
  }

}