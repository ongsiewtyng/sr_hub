// lib/services/open_library_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/open_library_models.dart';

class OpenLibraryService {
  static const String _baseUrl = 'https://openlibrary.org';
  static const Duration _timeout = Duration(seconds: 30);

  // Search books
  static Future<OpenLibrarySearchResponse?> searchBooks({
    required String query,
    int limit = 20,
    int offset = 0,
    String? author,
    String? title,
    String? subject,
    String? publisher,
    int? publishYear,
  }) async {
    try {
      // Build search query
      String searchQuery = query;
      if (author != null) searchQuery += ' author:"$author"';
      if (title != null) searchQuery += ' title:"$title"';
      if (subject != null) searchQuery += ' subject:"$subject"';
      if (publisher != null) searchQuery += ' publisher:"$publisher"';
      if (publishYear != null) searchQuery += ' publish_year:$publishYear';

      final queryParams = {
        'q': searchQuery,
        'limit': limit.toString(),
        'offset': offset.toString(),
        'fields': 'key,title,author_name,cover_i,first_publish_year,subject,ratings_average,ratings_count,number_of_pages_median,language,isbn,publisher,publish_date',
      };

      final uri = Uri.parse('$_baseUrl/search.json').replace(queryParameters: queryParams);

      print('🔍 Open Library Search: $uri');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'StudyResourceHub/1.0 (Flutter App)',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      print('📊 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OpenLibrarySearchResponse.fromJson(data);
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Search Error: $e');
      return null;
    }
  }

  // Get book details by work ID
  static Future<OpenLibraryBook?> getBookDetails(String workId) async {
    try {
      final uri = Uri.parse('$_baseUrl/works/$workId.json');

      print('📖 Fetching book details: $uri');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'StudyResourceHub/1.0 (Flutter App)',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OpenLibraryBook.fromWorkDetails(data);
      } else {
        print('❌ Details Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Details Error: $e');
      return null;
    }
  }

  // Get author details
  static Future<Map<String, dynamic>?> getAuthorDetails(String authorKey) async {
    try {
      final uri = Uri.parse('$_baseUrl$authorKey.json');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'StudyResourceHub/1.0 (Flutter App)',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Author Error: $e');
      return null;
    }
  }

  // Get trending/popular books
  static Future<List<OpenLibraryBook>> getTrendingBooks({int limit = 20}) async {
    try {
      // Search for books with high ratings and recent publications
      final trendingQueries = [
        'ratings_average:[4.0 TO *] AND first_publish_year:[2020 TO *]',
        'subject:fiction AND ratings_count:[100 TO *]',
        'subject:science AND first_publish_year:[2018 TO *]',
        'subject:technology AND ratings_average:[3.5 TO *]',
      ];

      final allBooks = <OpenLibraryBook>[];

      for (final query in trendingQueries) {
        final response = await searchBooks(
          query: query,
          limit: limit ~/ trendingQueries.length,
        );

        if (response != null) {
          allBooks.addAll(response.docs);
        }
      }

      // Remove duplicates and return
      final uniqueBooks = <String, OpenLibraryBook>{};
      for (final book in allBooks) {
        uniqueBooks[book.key] = book;
      }

      return uniqueBooks.values.take(limit).toList();
    } catch (e) {
      print('❌ Trending Books Error: $e');
      return [];
    }
  }

  // Get books by subject
  static Future<List<OpenLibraryBook>> getBooksBySubject({
    required String subject,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await searchBooks(
        query: 'subject:"$subject"',
        limit: limit,
        offset: offset,
      );

      return response?.docs ?? [];
    } catch (e) {
      print('❌ Subject Books Error: $e');
      return [];
    }
  }

  // Get books by author
  static Future<List<OpenLibraryBook>> getBooksByAuthor({
    required String author,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await searchBooks(
        query: '',
        author: author,
        limit: limit,
        offset: offset,
      );

      return response?.docs ?? [];
    } catch (e) {
      print('❌ Author Books Error: $e');
      return [];
    }
  }

  // Check if cover image exists
  static Future<bool> coverExists(String coverUrl) async {
    try {
      final response = await http.head(Uri.parse(coverUrl)).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get multiple cover sizes for a book
  static Map<String, String> getCoverUrls(int? coverId) {
    if (coverId == null) return {};

    return {
      'small': 'https://covers.openlibrary.org/b/id/$coverId-S.jpg',
      'medium': 'https://covers.openlibrary.org/b/id/$coverId-M.jpg',
      'large': 'https://covers.openlibrary.org/b/id/$coverId-L.jpg',
    };
  }
}