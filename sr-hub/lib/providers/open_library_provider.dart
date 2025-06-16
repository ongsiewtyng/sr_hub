// lib/providers/open_library_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/open_library_models.dart';
import '../services/open_library_service.dart';

// Search query state
final openLibrarySearchQueryProvider = StateProvider<String>((ref) => '');

// Search results provider
final openLibrarySearchProvider = FutureProvider.family<List<OpenLibraryBook>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];

  try {
    final response = await OpenLibraryService.searchBooks(query: query.trim());
    return response?.docs ?? [];
  } catch (e) {
    print('Search provider error: $e');
    return [];
  }
});

// Trending books provider
final openLibraryTrendingProvider = FutureProvider<List<OpenLibraryBook>>((ref) async {
  try {
    return await OpenLibraryService.getTrendingBooks();
  } catch (e) {
    print('Trending books provider error: $e');
    return [];
  }
});

// Subject books provider
final openLibrarySubjectProvider = FutureProvider.family<List<OpenLibraryBook>, String>((ref, subject) async {
  try {
    return await OpenLibraryService.getBooksBySubject(subject: subject);
  } catch (e) {
    print('Subject books provider error: $e');
    return [];
  }
});

// Book details provider
final openLibraryBookDetailsProvider = FutureProvider.family<OpenLibraryBook?, String>((ref, workId) async {
  try {
    return await OpenLibraryService.getBookDetails(workId);
  } catch (e) {
    print('Book details provider error: $e');
    return null;
  }
});

// Author books provider
final openLibraryAuthorBooksProvider = FutureProvider.family<List<OpenLibraryBook>, String>((ref, author) async {
  try {
    return await OpenLibraryService.getBooksByAuthor(author: author);
  } catch (e) {
    print('Author books provider error: $e');
    return [];
  }
});

// Loading state
final openLibraryLoadingProvider = StateProvider<bool>((ref) => false);

// Error state
final openLibraryErrorProvider = StateProvider<String?>((ref) => null);