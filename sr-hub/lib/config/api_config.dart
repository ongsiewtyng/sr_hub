// lib/config/api_config.dart
class ApiConfig {
  static const String? googleBooksApiKey = String.fromEnvironment('GOOGLE_BOOKS_API_KEY');

  static bool get hasGoogleBooksApiKey =>
      googleBooksApiKey != null && googleBooksApiKey!.isNotEmpty;

  static const bool useMockData = true; // Set to false to use Firebase

  static bool get isUsingMockData => useMockData;
}