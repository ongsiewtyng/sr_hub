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
}