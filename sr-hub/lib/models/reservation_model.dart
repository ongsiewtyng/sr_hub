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
}