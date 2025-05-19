// lib/models/floor_model.dart
class FloorZone {
  final String id;
  final String name;
  final String type;
  final Map<String, double> bounds;
  final String description;
  final String color;

  FloorZone({
    required this.id,
    required this.name,
    required this.type,
    required this.bounds,
    required this.description,
    required this.color,
  });
}

class Floor {
  final String id;
  final String name;
  final int level;
  final String mapImageUrl;
  final List<String> features;
  final Map<String, double> dimensions;
  final List<FloorZone> zones;
  final bool isAccessible;

  Floor({
    required this.id,
    required this.name,
    required this.level,
    required this.mapImageUrl,
    required this.features,
    required this.dimensions,
    required this.zones,
    this.isAccessible = true,
  });
}