// lib/services/room_reservation_service.dart - Updated to save to database

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/library_models.dart';
import 'mock_data_service.dart';

class RoomReservationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Set to false to use real database
  static const bool useMockData = false; // Changed to false for database saving

  // Get all available rooms
  static Future<List<LibraryRoom>> getAvailableRooms() async {
    if (useMockData) {
      print('🔍 Using mock rooms data');
      await Future.delayed(const Duration(milliseconds: 500));
      final rooms = MockDataService.getMockRooms();
      print('✅ Found ${rooms.length} mock rooms');
      return rooms;
    }

    try {
      print('🔍 Fetching available rooms from Firestore...');

      // First check if we have any rooms in the database
      final snapshot = await _firestore.collection('library_rooms').limit(1).get();

      if (snapshot.docs.isEmpty) {
        print('📝 No rooms found in database, using mock data');
        return MockDataService.getMockRooms();
      }

      final roomsSnapshot = await _firestore
          .collection('library_rooms')
          .where('isAvailable', isEqualTo: true)
          .get();

      final rooms = roomsSnapshot.docs
          .map((doc) => LibraryRoom.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      print('✅ Found ${rooms.length} available rooms from database');
      return rooms;
    } catch (e) {
      print('❌ Error fetching rooms from database, using mock data: $e');
      return MockDataService.getMockRooms();
    }
  }

  // Get available time slots for a room on a specific date
  static Future<List<TimeSlot>> getAvailableTimeSlots({
    required String roomId,
    required DateTime date,
  }) async {
    if (useMockData) {
      print('🔍 Using mock time slots for room: $roomId on ${date.toString()}');
      await Future.delayed(const Duration(milliseconds: 300));
      final timeSlots = MockDataService.getMockTimeSlots(roomId: roomId, date: date);
      print('✅ Generated ${timeSlots.length} mock time slots');
      return timeSlots;
    }

    try {
      print('🔍 Fetching time slots for room: $roomId on ${date.toString()}');

      // Generate standard time slots (9 AM to 9 PM, 1-hour slots)
      final timeSlots = <TimeSlot>[];
      final baseDate = DateTime(date.year, date.month, date.day);

      for (int hour = 9; hour < 21; hour++) {
        final startTime = baseDate.add(Duration(hours: hour));
        final endTime = startTime.add(const Duration(hours: 1));

        // Check if this slot is already booked
        final isBooked = await _isTimeSlotBooked(roomId, startTime, endTime);

        // Make past time slots unavailable if it's today
        final now = DateTime.now();
        bool isPast = false;
        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day &&
            startTime.isBefore(now)) {
          isPast = true;
        }

        timeSlots.add(TimeSlot(
          id: '${roomId}_${date.millisecondsSinceEpoch}_$hour',
          startTime: startTime,
          endTime: endTime,
          isAvailable: !isBooked && !isPast,
        ));
      }

      print('✅ Generated ${timeSlots.length} time slots');
      final availableCount = timeSlots.where((slot) => slot.isAvailable).length;
      print('✅ Available slots: $availableCount');

      return timeSlots;
    } catch (e) {
      print('❌ Error fetching time slots: $e');
      return [];
    }
  }

  // Check if a time slot is already booked
  static Future<bool> _isTimeSlotBooked(String roomId, DateTime startTime, DateTime endTime) async {
    try {
      final startOfDay = DateTime(startTime.year, startTime.month, startTime.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('room_reservations')
          .where('roomId', isEqualTo: roomId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      for (final doc in snapshot.docs) {
        try {
          final reservation = RoomReservation.fromJson({...doc.data(), 'id': doc.id});

          // Check for time overlap
          if (startTime.isBefore(reservation.timeSlot.endTime) &&
              endTime.isAfter(reservation.timeSlot.startTime)) {
            print('⚠️ Time slot conflict found for ${startTime.hour}:00');
            return true;
          }
        } catch (e) {
          print('⚠️ Error parsing reservation: $e');
          continue;
        }
      }

      return false;
    } catch (e) {
      print('❌ Error checking booking: $e');
      return false;
    }
  }

  // Make a reservation - SAVE TO DATABASE
  static Future<String?> makeReservation({
    required LibraryRoom room,
    required DateTime date,
    required TimeSlot timeSlot,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return null;
      }

      print('🔄 Creating reservation in database...');

      // Generate reservation ID
      final reservationDoc = _firestore.collection('room_reservations').doc();
      final reservationId = reservationDoc.id;

      final reservation = RoomReservation(
        id: reservationId,
        userId: user.uid,
        roomId: room.id,
        roomName: room.name,
        date: date,
        timeSlot: timeSlot,
        status: ReservationStatus.confirmed,
        createdAt: DateTime.now(),
        notes: notes,
      );

      // Save to Firestore
      await reservationDoc.set(reservation.toJson());

      print('✅ Reservation saved to database: $reservationId');
      return reservationId;
    } catch (e) {
      print('❌ Error saving reservation to database: $e');
      return null;
    }
  }

  // Get user's reservations
  static Future<List<RoomReservation>> getUserReservations() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      print('🔍 Fetching user reservations from database...');

      final snapshot = await _firestore
          .collection('room_reservations')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final reservations = snapshot.docs
          .map((doc) => RoomReservation.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      print('✅ Found ${reservations.length} user reservations');
      return reservations;
    } catch (e) {
      print('❌ Error fetching user reservations: $e');
      return [];
    }
  }

  // Cancel reservation
  static Future<bool> cancelReservation(String reservationId) async {
    try {
      print('🔄 Cancelling reservation: $reservationId');

      await _firestore
          .collection('room_reservations')
          .doc(reservationId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      print('✅ Reservation cancelled: $reservationId');
      return true;
    } catch (e) {
      print('❌ Error cancelling reservation: $e');
      return false;
    }
  }

  // Initialize sample rooms in database (call this once)
  static Future<void> initializeSampleRooms() async {
    try {
      print('🔄 Initializing sample rooms in database...');

      final rooms = MockDataService.getMockRooms();
      final batch = _firestore.batch();

      for (final room in rooms) {
        final docRef = _firestore.collection('library_rooms').doc(room.id);
        batch.set(docRef, room.toJson());
      }

      await batch.commit();
      print('✅ Sample rooms initialized in database');
    } catch (e) {
      print('❌ Error initializing sample rooms: $e');
    }
  }
}