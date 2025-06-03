// lib/models/reservation_model.dart
enum ReservationStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  expired,
}

class Reservation {
  final String id;
  final String userId;
  final String resourceId;
  final String resourceType;
  final String resourceName;
  final DateTime startTime;
  final DateTime endTime;
  final ReservationStatus status;
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.userId,
    required this.resourceId,
    required this.resourceType,
    required this.resourceName,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
  });

  bool get isUpcoming =>
      status == ReservationStatus.confirmed &&
          endTime.isAfter(DateTime.now());

  bool get isActive =>
      status == ReservationStatus.confirmed &&
          startTime.isBefore(DateTime.now()) &&
          endTime.isAfter(DateTime.now());

  bool get isPast =>
      status == ReservationStatus.completed ||
          (status == ReservationStatus.confirmed && endTime.isBefore(DateTime.now()));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'resourceId': resourceId,
      'resourceType': resourceType,
      'resourceName': resourceName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      resourceId: map['resourceId'] ?? '',
      resourceType: map['resourceType'] ?? '',
      resourceName: map['resourceName'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      status: ReservationStatus.values.firstWhere(
            (e) => e.toString().split('.').last == map['status'],
        orElse: () => ReservationStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}