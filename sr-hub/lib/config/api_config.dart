// lib/config/api_config.dart
class ApiConfig {
  static const String? googleBooksApiKey = String.fromEnvironment('GOOGLE_BOOKS_API_KEY');

  static bool get hasGoogleBooksApiKey =>
      googleBooksApiKey != null && googleBooksApiKey!.isNotEmpty;
}