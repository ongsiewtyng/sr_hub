// lib/models/seat_model.dart
enum SeatType {
  individual,
  group,
  quiet,
  computer,
  accessible,
}

enum SeatStatus {
  available,
  occupied,
  reserved,
  maintenance,
}

class Seat {
  final String id;
  final String name;
  final String floorId;
  final String floorName;
  final SeatType type;
  final SeatStatus status;
  final List<String> amenities;
  final int capacity;
  final Map<String, double> position;

  Seat({
    required this.id,
    required this.name,
    required this.floorId,
    required this.floorName,
    required this.type,
    required this.status,
    required this.amenities,
    required this.capacity,
    required this.position,
  });

  String get typeDisplayName {
    switch (type) {
      case SeatType.individual:
        return 'Individual Seat';
      case SeatType.group:
        return 'Group Study Room';
      case SeatType.quiet:
        return 'Quiet Zone Seat';
      case SeatType.computer:
        return 'Computer Workstation';
      case SeatType.accessible:
        return 'Accessible Seat';
      default:
        return 'Seat';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case SeatStatus.available:
        return 'Available';
      case SeatStatus.occupied:
        return 'Occupied';
      case SeatStatus.reserved:
        return 'Reserved';
      case SeatStatus.maintenance:
        return 'Maintenance';
      default:
        return 'Unknown';
    }
  }

  bool get isAvailable => status == SeatStatus.available;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'floorId': floorId,
      'floorName': floorName,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'amenities': amenities,
      'capacity': capacity,
      'position': position,
    };
  }

  factory Seat.fromMap(Map<String, dynamic> map) {
    return Seat(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      floorId: map['floorId'] ?? '',
      floorName: map['floorName'] ?? '',
      type: SeatType.values.firstWhere(
            (e) => e.toString().split('.').last == map['type'],
        orElse: () => SeatType.individual,
      ),
      status: SeatStatus.values.firstWhere(
            (e) => e.toString().split('.').last == map['status'],
        orElse: () => SeatStatus.available,
      ),
      amenities: List<String>.from(map['amenities'] ?? []),
      capacity: map['capacity'] ?? 1,
      position: Map<String, double>.from(map['position'] ?? {}),
    );
  }
}