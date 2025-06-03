// lib/models/resource_model.dart
class Resource {
  final String id;
  final String title;
  final String description;
  final String type;
  final String url;
  final String subject;
  final String author;
  final DateTime dateAdded;
  final String format;
  final String size;
  final String language;
  final String license;
  final String? previewImageUrl;
  final List<String> tags;
  final int viewCount;
  final int downloadCount;
  final bool isPublic;

  Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.url,
    required this.subject,
    required this.author,
    required this.dateAdded,
    required this.format,
    required this.size,
    required this.language,
    required this.license,
    this.previewImageUrl,
    required this.tags,
    this.viewCount = 0,
    this.downloadCount = 0,
    this.isPublic = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'url': url,
      'subject': subject,
      'author': author,
      'dateAdded': dateAdded.toIso8601String(),
      'format': format,
      'size': size,
      'language': language,
      'license': license,
      'previewImageUrl': previewImageUrl,
      'tags': tags,
      'viewCount': viewCount,
      'downloadCount': downloadCount,
      'isPublic': isPublic,
    };
  }

  factory Resource.fromMap(Map<String, dynamic> map) {
    return Resource(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      url: map['url'] ?? '',
      subject: map['subject'] ?? '',
      author: map['author'] ?? '',
      dateAdded: DateTime.parse(map['dateAdded']),
      format: map['format'] ?? '',
      size: map['size'] ?? '',
      language: map['language'] ?? 'English',
      license: map['license'] ?? '',
      previewImageUrl: map['previewImageUrl'],
      tags: List<String>.from(map['tags'] ?? []),
      viewCount: map['viewCount'] ?? 0,
      downloadCount: map['downloadCount'] ?? 0,
      isPublic: map['isPublic'] ?? true,
    );
  }
}