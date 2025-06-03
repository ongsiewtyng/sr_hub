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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'description': description,
      'price': price,
      'categories': categories,
      'publisher': publisher,
      'publishDate': publishDate.toIso8601String(),
      'isbn': isbn,
      'pageCount': pageCount,
      'formats': formats,
      'formatPrices': formatPrices,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'isNew': isNew,
      'isFeatured': isFeatured,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      coverUrl: map['coverUrl'] ?? '',
      description: map['description'],
      price: (map['price'] ?? 0).toDouble(),
      categories: List<String>.from(map['categories'] ?? []),
      publisher: map['publisher'] ?? '',
      publishDate: DateTime.parse(map['publishDate']),
      isbn: map['isbn'] ?? '',
      pageCount: map['pageCount'] ?? 0,
      formats: List<String>.from(map['formats'] ?? []),
      formatPrices: Map<String, double>.from(map['formatPrices'] ?? {}),
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      isNew: map['isNew'] ?? false,
      isFeatured: map['isFeatured'] ?? false,
    );
  }
}