// lib/services/google_books_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  static const Duration _timeout = Duration(seconds: 15);

  // Add your API key here (or better yet, use environment variables)
  static String? get _apiKey => ApiConfig.googleBooksApiKey;

  static Future<Map<String, dynamic>?> searchBook({
    required String title,
    String? author,
    String? isbn,
  }) async {
    try {
      String query = title;
      if (author != null) query += ' inauthor:$author';
      if (isbn != null) query += ' isbn:$isbn';

      final queryParams = {
        'q': query,
        'maxResults': '1',
        'printType': 'books',
      };

      // Add API key if available
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        queryParams['key'] = _apiKey!;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

      print('🔍 Google Books Search: ${uri.toString().replaceAll(_apiKey ?? '', 'API_KEY_HIDDEN')}');

      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          return data['items'][0];
        }
      } else if (response.statusCode == 403) {
        print('❌ Google Books API: Quota exceeded or API key required');
        return null;
      }
      return null;
    } catch (e) {
      print('❌ Google Books Error: $e');
      return null;
    }
  }

  // Enhanced method with better error handling
  static Future<List<Map<String, dynamic>>> searchMultipleBooks({
    required String query,
    int maxResults = 10,
  }) async {
    try {
      final queryParams = {
        'q': query,
        'maxResults': maxResults.toString(),
        'printType': 'books',
      };

      if (_apiKey != null && _apiKey!.isNotEmpty) {
        queryParams['key'] = _apiKey!;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['items'] ?? []);
      }
      return [];
    } catch (e) {
      print('❌ Google Books Multiple Search Error: $e');
      return [];
    }
  }

  // Check API quota status
  static Future<bool> checkApiStatus() async {
    try {
      final queryParams = {
        'q': 'test',
        'maxResults': '1',
      };

      if (_apiKey != null && _apiKey!.isNotEmpty) {
        queryParams['key'] = _apiKey!;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Rest of your existing methods...
  static String? extractPreviewLink(Map<String, dynamic>? googleBookData) {
    if (googleBookData == null) return null;

    final volumeInfo = googleBookData['volumeInfo'] as Map<String, dynamic>?;
    return volumeInfo?['previewLink'] as String?;
  }

  static Map<String, bool> extractAvailableFormats(Map<String, dynamic>? googleBookData) {
    if (googleBookData == null) {
      return {'epub': false, 'pdf': false, 'print': true};
    }

    final saleInfo = googleBookData['saleInfo'] as Map<String, dynamic>?;
    final accessInfo = googleBookData['accessInfo'] as Map<String, dynamic>?;

    bool hasEpub = false;
    bool hasPdf = false;
    bool hasPrint = true;

    if (saleInfo != null && saleInfo['isEbook'] == true) {
      hasEpub = true;
      hasPdf = true;
    }

    if (accessInfo != null) {
      final epub = accessInfo['epub'] as Map<String, dynamic>?;
      final pdf = accessInfo['pdf'] as Map<String, dynamic>?;

      if (epub != null && epub['isAvailable'] == true) hasEpub = true;
      if (pdf != null && pdf['isAvailable'] == true) hasPdf = true;
    }

    return {
      'epub': hasEpub,
      'pdf': hasPdf,
      'print': hasPrint,
    };
  }
}