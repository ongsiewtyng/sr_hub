// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../models/resource_model.dart';
import '../models/reservation_model.dart';
import '../models/seat_model.dart';
import '../models/floor_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Books Collection
  Future<List<Book>> getBooks() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('books').get();
      return snapshot.docs.map((doc) => Book.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Get books error: $e');
      return [];
    }
  }

  Future<List<Book>> getFeaturedBooks() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('books')
          .where('isFeatured', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) => Book.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Get featured books error: $e');
      return [];
    }
  }

  Future<List<Book>> searchBooks(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('books')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: query + 'z')
          .get();
      return snapshot.docs.map((doc) => Book.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Search books error: $e');
      return [];
    }
  }

  // Resources Collection
  Future<List<Resource>> getResources() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('resources').get();
      return snapshot.docs.map((doc) => Resource.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Get resources error: $e');
      return [];
    }
  }

  Future<List<Resource>> searchResources(String query, {String? type, String? subject}) async {
    try {
      Query queryRef = _firestore.collection('resources');

      if (type != null && type != 'all') {
        queryRef = queryRef.where('type', isEqualTo: type);
      }

      if (subject != null && subject != 'all') {
        queryRef = queryRef.where('subject', isEqualTo: subject);
      }

      QuerySnapshot snapshot = await queryRef.get();
      List<Resource> resources = snapshot.docs
          .map((doc) => Resource.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by title if query is provided
      if (query.isNotEmpty) {
        resources = resources.where((resource) =>
            resource.title.toLowerCase().contains(query.toLowerCase())).toList();
      }

      return resources;
    } catch (e) {
      print('Search resources error: $e');
      return [];
    }
  }

  // Reservations Collection
  Future<List<Reservation>> getUserReservations(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .get();
      return snapshot.docs.map((doc) => Reservation.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Get user reservations error: $e');
      return [];
    }
  }

  Future<String> createReservation(Reservation reservation) async {
    try {
      DocumentReference docRef = await _firestore.collection('reservations').add(reservation.toMap());
      return docRef.id;
    } catch (e) {
      print('Create reservation error: $e');
      rethrow;
    }
  }

  Future<void> cancelReservation(String reservationId) async {
    try {
      await _firestore.collection('reservations').doc(reservationId).update({
        'status': 'cancelled',
      });
    } catch (e) {
      print('Cancel reservation error: $e');
      rethrow;
    }
  }

  // Seats Collection
  Future<List<Seat>> getSeats() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('seats').get();
      return snapshot.docs.map((doc) => Seat.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Get seats error: $e');
      return [];
    }
  }

  Future<List<Seat>> getAvailableSeats(String floorId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('seats')
          .where('floorId', isEqualTo: floorId)
          .where('status', isEqualTo: 'available')
          .get();
      return snapshot.docs.map((doc) => Seat.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Get available seats error: $e');
      return [];
    }
  }

  Future<void> updateSeatStatus(String seatId, String status) async {
    try {
      await _firestore.collection('seats').doc(seatId).update({
        'status': status,
      });
    } catch (e) {
      print('Update seat status error: $e');
      rethrow;
    }
  }

  // Floors Collection
  Future<List<Floor>> getFloors() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('floors').get();
      return snapshot.docs.map((doc) => Floor.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Get floors error: $e');
      return [];
    }
  }

  // Wishlist
  Future<void> addToWishlist(String userId, String bookId) async {
    try {
      await _firestore.collection('wishlists').doc('${userId}_$bookId').set({
        'userId': userId,
        'bookId': bookId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Add to wishlist error: $e');
      rethrow;
    }
  }

  Future<void> removeFromWishlist(String userId, String bookId) async {
    try {
      await _firestore.collection('wishlists').doc('${userId}_$bookId').delete();
    } catch (e) {
      print('Remove from wishlist error: $e');
      rethrow;
    }
  }

  Future<List<String>> getUserWishlist(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('wishlists')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['bookId'] as String)
          .toList();
    } catch (e) {
      print('Get user wishlist error: $e');
      return [];
    }
  }

  // Saved Resources
  Future<void> saveResource(String userId, String resourceId) async {
    try {
      await _firestore.collection('saved_resources').doc('${userId}_$resourceId').set({
        'userId': userId,
        'resourceId': resourceId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Save resource error: $e');
      rethrow;
    }
  }

  Future<void> unsaveResource(String userId, String resourceId) async {
    try {
      await _firestore.collection('saved_resources').doc('${userId}_$resourceId').delete();
    } catch (e) {
      print('Unsave resource error: $e');
      rethrow;
    }
  }

  Future<List<String>> getUserSavedResources(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('saved_resources')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['resourceId'] as String)
          .toList();
    } catch (e) {
      print('Get user saved resources error: $e');
      return [];
    }
  }
}