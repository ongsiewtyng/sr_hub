// lib/models/library_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryRoom {
  final String id;
  final String name;
  final String description;
  final int capacity;
  final List<String> amenities;
  final String imageUrl;
  final bool isAvailable;
  final String location;
  final RoomType type;

  LibraryRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.capacity,
    required this.amenities,
    required this.imageUrl,
    required this.isAvailable,
    required this.location,
    required this.type,
  });

  factory LibraryRoom.fromJson(Map<String, dynamic> json) {
    return LibraryRoom(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      capacity: json['capacity'] ?? 0,
      amenities: List<String>.from(json['amenities'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      hourlyRate: (json['hourlyRate'] ?? 0.0).toDouble(),
      location: json['location'] ?? '',
      type: RoomType.values.firstWhere(
            (e) => e.toString() == 'RoomType.${json['type']}',
        orElse: () => RoomType.study,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'capacity': capacity,
      'amenities': amenities,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'hourlyRate': hourlyRate,
      'location': location,
      'type': type.toString().split('.').last,
    };
  }
}

enum RoomType {
  study,
  meeting,
  discussion,
  silent,
  computer,
  group,
}

class TimeSlot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final double price;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.price,
  });

  String get displayTime {
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  Duration get duration => endTime.difference(startTime);

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] ?? '',
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: (json['endTime'] as Timestamp).toDate(),
      isAvailable: json['isAvailable'] ?? true,
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isAvailable': isAvailable,
      'price': price,
    };
  }
}

class RoomReservation {
  final String id;
  final String userId;
  final String roomId;
  final String roomName;
  final DateTime date;
  final TimeSlot timeSlot;
  final ReservationStatus status;
  final double totalPrice;
  final DateTime createdAt;
  final String? notes;

  RoomReservation({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.roomName,
    required this.date,
    required this.timeSlot,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    this.notes,
  });

  factory RoomReservation.fromJson(Map<String, dynamic> json) {
    return RoomReservation(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      roomId: json['roomId'] ?? '',
      roomName: json['roomName'] ?? '',
      date: (json['date'] as Timestamp).toDate(),
      timeSlot: TimeSlot.fromJson(json['timeSlot']),
      status: ReservationStatus.values.firstWhere(
            (e) => e.toString() == 'ReservationStatus.${json['status']}',
        orElse: () => ReservationStatus.pending,
      ),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'roomId': roomId,
      'roomName': roomName,
      'date': Timestamp.fromDate(date),
      'timeSlot': timeSlot.toJson(),
      'status': status.toString().split('.').last,
      'totalPrice': totalPrice,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
    };
  }
}

enum ReservationStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}