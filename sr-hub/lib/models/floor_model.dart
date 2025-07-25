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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'bounds': bounds,
      'description': description,
      'color': color,
    };
  }

  factory FloorZone.fromMap(Map<String, dynamic> map) {
    return FloorZone(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      bounds: Map<String, double>.from(map['bounds'] ?? {}),
      description: map['description'] ?? '',
      color: map['color'] ?? '#E3F2FD',
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'mapImageUrl': mapImageUrl,
      'features': features,
      'dimensions': dimensions,
      'zones': zones.map((zone) => zone.toMap()).toList(),
      'isAccessible': isAccessible,
    };
  }

  factory Floor.fromMap(Map<String, dynamic> map) {
    return Floor(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      level: map['level'] ?? 1,
      mapImageUrl: map['mapImageUrl'] ?? '',
      features: List<String>.from(map['features'] ?? []),
      dimensions: Map<String, double>.from(map['dimensions'] ?? {}),
      zones: (map['zones'] as List<dynamic>?)
          ?.map((zone) => FloorZone.fromMap(zone as Map<String, dynamic>))
          .toList() ?? [],
      isAccessible: map['isAccessible'] ?? true,
    );
  }
}