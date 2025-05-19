// lib/models/book_model.dart
class Book {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final String? description;
  final double price;
  final List<String> categories;
  final String publisher;
  final DateTime publishDate;
  final String isbn;
  final int pageCount;
  final List<String> formats;
  final Map<String, double> formatPrices;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final bool isNew;
  final bool isFeatured;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    this.description,
    required this.price,
    required this.categories,
    required this.publisher,
    required this.publishDate,
    required this.isbn,
    required this.pageCount,
    required this.formats,
    required this.formatPrices,
    this.rating = 0,
    this.reviewCount = 0,
    this.isAvailable = true,
    this.isNew = false,
    this.isFeatured = false,
  });
}