// lib/providers/mock_room_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/library_models.dart';

class MockRoomData {
  static final List<LibraryRoom> _mockRooms = [
    LibraryRoom(
      id: 'room_001',
      name: 'Study Room A',
      description: 'Quiet study room perfect for individual work and small groups',
      capacity: 4,
      amenities: ['WiFi', 'Whiteboard', 'Air Conditioning', 'Power Outlets'],
      imageUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
      isAvailable: true,
      location: 'Level 2, Wing A',
      type: RoomType.study,
    ),
    LibraryRoom(
      id: 'room_002',
      name: 'Meeting Room B',
      description: 'Professional meeting room with presentation facilities',
      capacity: 8,
      amenities: ['WiFi', 'Projector', 'Conference Table', 'Air Conditioning', 'Video Conferencing'],
      imageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=400',
      isAvailable: true,
      location: 'Level 3, Wing B',
      type: RoomType.meeting,
    ),
    LibraryRoom(
      id: 'room_003',
      name: 'Discussion Room C',
      description: 'Collaborative space for group discussions and brainstorming',
      capacity: 6,
      amenities: ['WiFi', 'Whiteboard', 'Comfortable Seating', 'Flip Chart'],
      imageUrl: 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=400',
      isAvailable: true,
      location: 'Level 2, Wing C',
      type: RoomType.discussion,
    ),
    LibraryRoom(
      id: 'room_004',
      name: 'Silent Study Pod',
      description: 'Ultra-quiet pod for focused individual study',
      capacity: 1,
      amenities: ['WiFi', 'Desk Lamp', 'Power Outlet', 'Noise Cancellation'],
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      isAvailable: true,
      location: 'Level 1, Quiet Zone',
      type: RoomType.silent,
    ),
    LibraryRoom(
      id: 'room_005',
      name: 'Computer Lab D',
      description: 'Equipped with high-performance computers and software',
      capacity: 12,
      amenities: ['WiFi', 'Computers', 'Printers', 'Software Suite', 'Scanners'],
      imageUrl: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=400',
      isAvailable: true,
      location: 'Level 1, Tech Wing',
      type: RoomType.computer,
    ),
    LibraryRoom(
      id: 'room_006',
      name: 'Group Study Hall',
      description: 'Large space for group projects and collaborative work',
      capacity: 15,
      amenities: ['WiFi', 'Multiple Whiteboards', 'Moveable Tables', 'Presentation Screen'],
      imageUrl: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=400',
      isAvailable: true,
      location: 'Level 3, Wing A',
      type: RoomType.group,
    ),
    LibraryRoom(
      id: 'room_007',
      name: 'Creative Workshop',
      description: 'Flexible space for creative projects and workshops',
      capacity: 10,
      amenities: ['WiFi', 'Art Supplies', 'Large Tables', 'Natural Light'],
      imageUrl: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400',
      isAvailable: true,
      location: 'Level 2, Creative Wing',
      type: RoomType.group,
    ),
    LibraryRoom(
      id: 'room_008',
      name: 'Phone Booth',
      description: 'Private space for phone calls and video conferences',
      capacity: 1,
      amenities: ['WiFi', 'Soundproof', 'Phone Charging', 'Good Lighting'],
      imageUrl: 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400',
      isAvailable: true,
      location: 'Level 1, Quiet Zone',
      type: RoomType.silent,
    ),
  ];

  static List<LibraryRoom> getAllRooms() => List.from(_mockRooms);

  static List<LibraryRoom> getRoomsByType(RoomType type) {
    return _mockRooms.where((room) => room.type == type).toList();
  }

  static LibraryRoom? getRoomById(String id) {
    try {
      return _mockRooms.firstWhere((room) => room.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<TimeSlot> generateTimeSlots({
    required String roomId,
    required DateTime date,
  }) {
    final timeSlots = <TimeSlot>[];
    final baseDate = DateTime(date.year, date.month, date.day);

    // Generate time slots from 9 AM to 9 PM
    for (int hour = 9; hour < 21; hour++) {
      final startTime = baseDate.add(Duration(hours: hour));
      final endTime = startTime.add(const Duration(hours: 1));

      // Mock some slots as unavailable for realism
      bool isAvailable = true;
      if (hour == 14 || hour == 16) { // 2 PM and 4 PM are "booked"
        isAvailable = false;
      }

      timeSlots.add(TimeSlot(
        id: '${roomId}_${hour}',
        startTime: startTime,
        endTime: endTime,
        isAvailable: isAvailable,
      ));
    }

    return timeSlots;
  }

  // Mock reservations for demonstration
  static final List<RoomReservation> _mockReservations = [];

  static List<RoomReservation> getUserReservations() {
    return List.from(_mockReservations);
  }

  static String addReservation({
    required LibraryRoom room,
    required DateTime date,
    required TimeSlot timeSlot,
    String? notes,
  }) {
    final reservationId = 'mock_${DateTime.now().millisecondsSinceEpoch}';

    final reservation = RoomReservation(
      id: reservationId,
      userId: 'mock_user',
      roomId: room.id,
      roomName: room.name,
      date: date,
      timeSlot: timeSlot,
      status: ReservationStatus.confirmed,
      createdAt: DateTime.now(),
      notes: notes,
    );

    _mockReservations.add(reservation);
    return reservationId;
  }
}