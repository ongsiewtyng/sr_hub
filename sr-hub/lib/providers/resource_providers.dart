// lib/models/resource_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class Resource {
  final String id;
  final String title;
  final List<String> authors;
  final String? description;
  final String? imageUrl;
  final DateTime? publishedDate;
  final ResourceType type;
  final String sourceUrl;
  final bool isBookmarked;

  Resource({
    required this.id,
    required this.title,
    required this.authors,
    this.description,
    this.imageUrl,
    this.publishedDate,
    required this.type,
    required this.sourceUrl,
    this.isBookmarked = false,
  });

  Map<String, dynamic> toJson();

  Resource copyWith({bool? isBookmarked});

  factory Resource.fromMap(Map<String, dynamic> json) {
    final typeStr = json['type'];
    final ResourceType type = ResourceType.values.firstWhere(
          (e) => e.toString().split('.').last == typeStr,
      orElse: () => ResourceType.book,
    );

    switch (type) {
      case ResourceType.book:
        return BookResource.fromJson(json);
      case ResourceType.researchPaper:
        return ResearchPaperResource.fromJson(json);
    }
  }
}

enum ResourceType {
  book,
  researchPaper,
}

class BookResource extends Resource {
  final String? isbn;
  final String? publisher;
  final int? pageCount;
  final List<String> subjects;
  final double? rating;
  final String? previewLink;

  BookResource({
    required super.id,
    required super.title,
    required super.authors,
    super.description,
    super.imageUrl,
    super.publishedDate,
    required super.sourceUrl,
    super.isBookmarked = false,
    this.isbn,
    this.publisher,
    this.pageCount,
    this.subjects = const [],
    this.rating,
    this.previewLink,
  }) : super(type: ResourceType.book);

  factory BookResource.fromOpenLibrary(Map<String, dynamic> json) {
    String? coverUrl;
    if (json['cover_i'] != null) {
      coverUrl = 'https://covers.openlibrary.org/b/id/${json['cover_i']}-M.jpg';
    }

    List<String> authors = [];
    if (json['author_name'] != null) {
      authors = List<String>.from(json['author_name']);
    }

    List<String> subjects = [];
    if (json['subject'] != null) {
      subjects = List<String>.from(json['subject']).take(5).toList();
    }

    DateTime? publishedDate;
    if (json['first_publish_year'] != null) {
      publishedDate = DateTime(json['first_publish_year']);
    }

    return BookResource(
      id: json['key']?.toString().replaceAll('/works/', '') ?? '',
      title: json['title'] ?? 'Unknown Title',
      authors: authors,
      description: json['description'] is String ? json['description'] : null,
      imageUrl: coverUrl,
      publishedDate: publishedDate,
      sourceUrl: 'https://openlibrary.org${json['key'] ?? ''}',
      isbn: json['isbn']?.isNotEmpty == true ? json['isbn'][0] : null,
      publisher: json['publisher']?.isNotEmpty == true ? json['publisher'][0] : null,
      pageCount: json['number_of_pages_median'],
      subjects: subjects,
      rating: json['ratings_average']?.toDouble(),
      previewLink: json['preview_link'],
    );
  }

  factory BookResource.fromJson(Map<String, dynamic> json) {
    return BookResource(
      id: json['id'],
      title: json['title'],
      authors: List<String>.from(json['authors']),
      description: json['description'],
      imageUrl: json['imageUrl'],
      publishedDate: json['publishedDate'] != null
          ? DateTime.tryParse(json['publishedDate'])
          : null,
      sourceUrl: json['sourceUrl'],
      isbn: json['isbn'],
      publisher: json['publisher'],
      pageCount: json['pageCount'],
      subjects: List<String>.from(json['subjects'] ?? []),
      rating: (json['rating'] as num?)?.toDouble(),
      previewLink: json['previewLink'],
      isBookmarked: json['isBookmarked'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'authors': authors,
      'description': description,
      'imageUrl': imageUrl,
      'publishedDate': publishedDate?.toIso8601String(),
      'type': 'book',
      'sourceUrl': sourceUrl,
      'isbn': isbn,
      'publisher': publisher,
      'pageCount': pageCount,
      'subjects': subjects,
      'rating': rating,
      'previewLink': previewLink,
      'isBookmarked': isBookmarked,
    };
  }

  @override
  BookResource copyWith({bool? isBookmarked}) {
    return BookResource(
      id: id,
      title: title,
      authors: authors,
      description: description,
      imageUrl: imageUrl,
      publishedDate: publishedDate,
      sourceUrl: sourceUrl,
      isbn: isbn,
      publisher: publisher,
      pageCount: pageCount,
      subjects: subjects,
      rating: rating,
      previewLink: previewLink,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

class ResearchPaperResource extends Resource {
  final String? doi;
  final String? venue;
  final int? citationCount;
  final List<String> keywords;
  final String? abstractText;
  final String? pdfUrl;
  final int? year;

  ResearchPaperResource({
    required super.id,
    required super.title,
    required super.authors,
    super.description,
    super.imageUrl,
    super.publishedDate,
    required super.sourceUrl,
    super.isBookmarked = false,
    this.doi,
    this.venue,
    this.citationCount,
    this.keywords = const [],
    this.abstractText,
    this.pdfUrl,
    this.year,
  }) : super(type: ResourceType.researchPaper);

  factory ResearchPaperResource.fromSemanticScholar(Map<String, dynamic> json) {
    // Extract authors
    List<String> authors = [];
    if (json['authors'] != null) {
      authors = (json['authors'] as List)
          .map((author) => author['name']?.toString() ?? 'Unknown Author')
          .toList();
    }

    // Extract publish date
    DateTime? publishedDate;
    if (json['year'] != null) {
      publishedDate = DateTime(json['year']);
    } else if (json['publicationDate'] != null) {
      try {
        publishedDate = DateTime.parse(json['publicationDate']);
      } catch (_) {}
    }

    // Extract keywords
    List<String> keywords = [];
    if (json['fieldsOfStudy'] != null) {
      keywords = List<String>.from(json['fieldsOfStudy']).take(5).toList();
    }

    // Ensure sourceUrl is valid
    String paperId = json['paperId'] ?? json['id'] ?? '';
    String? rawUrl = json['url'];
    String sourceUrl = (rawUrl != null && rawUrl.toString().startsWith('http'))
        ? rawUrl
        : 'https://www.semanticscholar.org/paper/$paperId';

    return ResearchPaperResource(
      id: paperId,
      title: json['title'] ?? 'Unknown Title',
      authors: authors,
      description: json['abstract'],
      publishedDate: publishedDate,
      sourceUrl: sourceUrl,
      doi: json['doi'],
      venue: json['venue'],
      citationCount: json['citationCount'],
      keywords: keywords,
      abstractText: json['abstract'],
      pdfUrl: json['openAccessPdf']?['url'],
      year: json['year'],
    );
  }

  factory ResearchPaperResource.fromJson(Map<String, dynamic> json) {
    return ResearchPaperResource(
      id: json['id'],
      title: json['title'],
      authors: List<String>.from(json['authors']),
      description: json['description'],
      imageUrl: json['imageUrl'],
      publishedDate: json['publishedDate'] != null
          ? DateTime.tryParse(json['publishedDate'])
          : null,
      sourceUrl: json['sourceUrl'],
      doi: json['doi'],
      venue: json['venue'],
      citationCount: json['citationCount'],
      keywords: List<String>.from(json['keywords'] ?? []),
      abstractText: json['abstractText'],
      pdfUrl: json['pdfUrl'],
      year: json['year'],
      isBookmarked: json['isBookmarked'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'authors': authors,
      'description': description,
      'imageUrl': imageUrl,
      'publishedDate': publishedDate?.toIso8601String(),
      'type': 'researchPaper',
      'sourceUrl': sourceUrl,
      'doi': doi,
      'venue': venue,
      'citationCount': citationCount,
      'keywords': keywords,
      'abstractText': abstractText,
      'pdfUrl': pdfUrl,
      'year': year,
      'isBookmarked': isBookmarked,
    };
  }

  @override
  ResearchPaperResource copyWith({bool? isBookmarked}) {
    return ResearchPaperResource(
      id: id,
      title: title,
      authors: authors,
      description: description,
      imageUrl: imageUrl,
      publishedDate: publishedDate,
      sourceUrl: sourceUrl,
      doi: doi,
      venue: venue,
      citationCount: citationCount,
      keywords: keywords,
      abstractText: abstractText,
      pdfUrl: pdfUrl,
      year: year,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

class BookmarkData {
  final String id;
  final String userId;
  final String resourceId;
  final ResourceType resourceType;
  final Map<String, dynamic> resourceData;
  final DateTime createdAt;
  final String? notes;

  BookmarkData({
    required this.id,
    required this.userId,
    required this.resourceId,
    required this.resourceType,
    required this.resourceData,
    required this.createdAt,
    this.notes,
  });

  factory BookmarkData.fromJson(Map<String, dynamic> json) {
    return BookmarkData(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      resourceId: json['resourceId'] ?? '',
      resourceType: ResourceType.values.firstWhere(
            (e) => e.toString() == 'ResourceType.${json['resourceType']}',
        orElse: () => ResourceType.book,
      ),
      resourceData: json['resourceData'] ?? {},
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'resourceId': resourceId,
      'resourceType': resourceType.toString().split('.').last,
      'resourceData': resourceData,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
    };
  }
}
