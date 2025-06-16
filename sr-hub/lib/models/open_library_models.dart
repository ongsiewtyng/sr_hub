// lib/models/open_library_models.dart
class OpenLibraryBook {
  final String key;
  final String title;
  final List<String> authors;
  final String? description;
  final String? coverUrl;
  final int? firstPublishYear;
  final int? pageCount;
  final List<String> subjects;
  final List<String> languages;
  final double? ratingsAverage;
  final int? ratingsCount;
  final List<String> isbn;
  final String? publisher;
  final List<String> publishDates;

  OpenLibraryBook({
    required this.key,
    required this.title,
    required this.authors,
    this.description,
    this.coverUrl,
    this.firstPublishYear,
    this.pageCount,
    this.subjects = const [],
    this.languages = const [],
    this.ratingsAverage,
    this.ratingsCount,
    this.isbn = const [],
    this.publisher,
    this.publishDates = const [],
  });

  factory OpenLibraryBook.fromSearchResult(Map<String, dynamic> json) {
    // Extract cover URL
    String? coverUrl;
    if (json['cover_i'] != null) {
      coverUrl = 'https://covers.openlibrary.org/b/id/${json['cover_i']}-L.jpg';
    }

    // Extract authors
    List<String> authors = [];
    if (json['author_name'] != null) {
      authors = List<String>.from(json['author_name']);
    }

    // Extract subjects (limit to first 10 for performance)
    List<String> subjects = [];
    if (json['subject'] != null) {
      subjects = List<String>.from(json['subject']).take(10).toList();
    }

    // Extract languages
    List<String> languages = [];
    if (json['language'] != null) {
      languages = List<String>.from(json['language']);
    }

    // Extract ISBN
    List<String> isbn = [];
    if (json['isbn'] != null) {
      isbn = List<String>.from(json['isbn']);
    }

    // Extract publish dates
    List<String> publishDates = [];
    if (json['publish_date'] != null) {
      publishDates = List<String>.from(json['publish_date']);
    }

    return OpenLibraryBook(
      key: json['key'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      authors: authors,
      coverUrl: coverUrl,
      firstPublishYear: json['first_publish_year'],
      pageCount: json['number_of_pages_median'],
      subjects: subjects,
      languages: languages,
      ratingsAverage: json['ratings_average']?.toDouble(),
      ratingsCount: json['ratings_count'],
      isbn: isbn,
      publisher: json['publisher']?.isNotEmpty == true ? json['publisher'][0] : null,
      publishDates: publishDates,
    );
  }

  factory OpenLibraryBook.fromWorkDetails(Map<String, dynamic> json) {
    String? description;
    if (json['description'] != null) {
      if (json['description'] is String) {
        description = json['description'];
      } else if (json['description'] is Map && json['description']['value'] != null) {
        description = json['description']['value'];
      }
    }

    // Extract subjects
    List<String> subjects = [];
    if (json['subjects'] != null) {
      subjects = List<String>.from(json['subjects']);
    }

    return OpenLibraryBook(
      key: json['key'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      authors: [], // Will be populated separately
      description: description,
      subjects: subjects,
    );
  }

  String get id => key.replaceAll('/works/', '');

  String get thumbnailUrl => coverUrl?.replaceAll('-L.jpg', '-M.jpg') ?? '';

  String get smallCoverUrl => coverUrl?.replaceAll('-L.jpg', '-S.jpg') ?? '';

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'authors': authors,
      'description': description,
      'coverUrl': coverUrl,
      'firstPublishYear': firstPublishYear,
      'pageCount': pageCount,
      'subjects': subjects,
      'languages': languages,
      'ratingsAverage': ratingsAverage,
      'ratingsCount': ratingsCount,
      'isbn': isbn,
      'publisher': publisher,
      'publishDates': publishDates,
    };
  }

  // Convert to your existing Book model if needed
  Map<String, dynamic> toBookModel() {
    return {
      'id': id,
      'title': title,
      'author': authors.isNotEmpty ? authors.first : 'Unknown Author',
      'description': description ?? '',
      'imageUrl': coverUrl ?? '',
      'rating': ratingsAverage ?? 0.0,
      'category': subjects.isNotEmpty ? subjects.first : 'General',
      'isAvailable': true,
      'publishedDate': firstPublishYear?.toString() ?? '',
      'pageCount': pageCount ?? 0,
      'language': languages.isNotEmpty ? languages.first : 'en',
      'isbn': isbn.isNotEmpty ? isbn.first : '',
      'publisher': publisher ?? '',
    };
  }
}

class OpenLibrarySearchResponse {
  final int numFound;
  final int start;
  final bool numFoundExact;
  final List<OpenLibraryBook> docs;

  OpenLibrarySearchResponse({
    required this.numFound,
    required this.start,
    required this.numFoundExact,
    required this.docs,
  });

  factory OpenLibrarySearchResponse.fromJson(Map<String, dynamic> json) {
    final docsList = json['docs'] as List? ?? [];
    final books = docsList.map((doc) => OpenLibraryBook.fromSearchResult(doc)).toList();

    return OpenLibrarySearchResponse(
      numFound: json['numFound'] ?? 0,
      start: json['start'] ?? 0,
      numFoundExact: json['numFoundExact'] ?? false,
      docs: books,
    );
  }
}