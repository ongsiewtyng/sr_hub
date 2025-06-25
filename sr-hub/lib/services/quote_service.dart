import 'dart:convert';
import 'package:http/http.dart' as http;

class QuoteService {
  static Future<String> fetchRandomQuote() async {
    final uri = Uri.parse('https://zenquotes.io/api/random');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final quote = data[0]['q'];
          final author = data[0]['a'];
          return '“$quote” — $author';
        }
      }
      throw Exception('Invalid response from ZenQuotes');
    } catch (e) {
      throw Exception('Failed to load quote: $e');
    }
  }
}
