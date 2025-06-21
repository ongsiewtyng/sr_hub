// lib/providers/firestore_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/book_model.dart';
import '../models/resource_models.dart';
import '../models/reservation_model.dart';
import '../models/seat_model.dart';
import '../models/floor_model.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// Books Providers
final booksProvider = FutureProvider<List<Book>>((ref) async {
  return await ref.read(firestoreServiceProvider).getBooks();
});

final featuredBooksProvider = FutureProvider<List<Book>>((ref) async {
  return await ref.read(firestoreServiceProvider).getFeaturedBooks();
});

// Resources Providers
final resourcesProvider = FutureProvider<List<Resource>>((ref) async {
  return await ref.read(firestoreServiceProvider).getResources();
});

// Reservations Providers
final userReservationsProvider = FutureProvider.family<List<Reservation>, String>((ref, userId) async {
  return await ref.read(firestoreServiceProvider).getUserReservations(userId);
});

// Seats Providers
final seatsProvider = FutureProvider<List<Seat>>((ref) async {
  return await ref.read(firestoreServiceProvider).getSeats();
});

final floorsProvider = FutureProvider<List<Floor>>((ref) async {
  return await ref.read(firestoreServiceProvider).getFloors();
});

// Wishlist Providers
final wishlistProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  return await ref.read(firestoreServiceProvider).getUserWishlist(userId);
});

// Saved Resources Providers
final savedResourcesProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  return await ref.read(firestoreServiceProvider).getUserSavedResources(userId);
});