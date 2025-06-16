// lib/services/room_reservation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/library_models.dart';

class RoomReservationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all available rooms
  static Future<List<LibraryRoom>> getAvailableRooms() async {
    try {
      final snapshot = await _firestore
          .collection('library_rooms')
          .where('isAvailable', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => LibraryRoom.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('❌ Error fetching rooms: $e');
      return [];
    }
  }

  // Get rooms by type
  static Future<List<LibraryRoom>> getRoomsByType(RoomType type) async {
    try {
      final snapshot = await _firestore
          .collection('library_rooms')
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('isAvailable', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => LibraryRoom.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('❌ Error fetching rooms by type: $e');
      return [];
    }
  }

  // Get available time slots for a room on a specific date
  static Future<List<TimeSlot>> getAvailableTimeSlots({
    required String roomId,
    required DateTime date,
  }) async {
    try {
      // Generate standard time slots (9 AM to 9 PM, 1-hour slots)
      final timeSlots = <TimeSlot>[];
      final baseDate = DateTime(date.year, date.month, date.day);

      for (int hour = 9; hour < 21; hour++) {
        final startTime = baseDate.add(Duration(hours: hour));
        final endTime = startTime.add(const Duration(hours: 1));

        // Check if this slot is already booked
        final isBooked = await _isTimeSlotBooked(roomId, startTime, endTime);

        timeSlots.add(TimeSlot(
          id: '${roomId}_${hour}',
          startTime: startTime,
          endTime: endTime,
          isAvailable: !isBooked,
          price: 10.0, // RM 10 per hour
        ));
      }

      return timeSlots;
    } catch (e) {
      print('❌ Error fetching time slots: $e');
      return [];
    }
  }

  // Check if a time slot is already booked
  static Future<bool> _isTimeSlotBooked(String roomId, DateTime startTime, DateTime endTime) async {
    try {
      final snapshot = await _firestore
          .collection('room_reservations')
          .where('roomId', isEqualTo: roomId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      for (final doc in snapshot.docs) {
        final reservation = RoomReservation.fromJson({...doc.data(), 'id': doc.id});

        // Check for time overlap
        if (startTime.isBefore(reservation.timeSlot.endTime) &&
            endTime.isAfter(reservation.timeSlot.startTime)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('❌ Error checking booking: $e');
      return false;
    }
  }

  // Make a reservation
  static Future<String?> makeReservation({
    required LibraryRoom room,
    required DateTime date,
    required TimeSlot timeSlot,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final reservationId = _firestore.collection('room_reservations').doc().id;

      final reservation = RoomReservation(
        id: reservationId,
        userId: user.uid,
        roomId: room.id,
        roomName: room.name,
        date: date,
        timeSlot: timeSlot,
        status: ReservationStatus.pending,
        totalPrice: timeSlot.price,
        createdAt: DateTime.now(),
        notes: notes,
      );

      await _firestore
          .collection('room_reservations')
          .doc(reservationId)
          .set(reservation.toJson());

      print('✅ Reservation created: $reservationId');
      return reservationId;
    } catch (e) {
      print('❌ Error making reservation: $e');
      return null;
    }
  }

  // Get user's reservations
  static Future<List<RoomReservation>> getUserReservations() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('room_reservations')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RoomReservation.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('❌ Error fetching user reservations: $e');
      return [];
    }
  }

  // Cancel reservation
  static Future<bool> cancelReservation(String reservationId) async {
    try {
      await _firestore
          .collection('room_reservations')
          .doc(reservationId)
          .update({'status': 'cancelled'});

      print('✅ Reservation cancelled: $reservationId');
      return true;
    } catch (e) {
      print('❌ Error cancelling reservation: $e');
      return false;
    }
  }
}