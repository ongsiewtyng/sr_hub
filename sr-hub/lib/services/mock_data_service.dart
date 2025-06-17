// lib/services/mock_data_service.dart
import '../models/library_models.dart';

class MockDataService {
  // Mock rooms data
  static List<LibraryRoom> getMockRooms() {
    return [
      LibraryRoom(
        id: 'room_001',
        name: 'Study Room A',
        description: 'Quiet study room perfect for individual work and focused learning',
        capacity: 4,
        amenities: ['WiFi', 'Whiteboard', 'Air Conditioning', 'Power Outlets'],
        imageUrl: '/placeholder.svg?height=200&width=300',
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
        imageUrl: '/placeholder.svg?height=200&width=300',
        isAvailable: true,
        location: 'Level 3, Wing B',
        type: RoomType.meeting,
      ),
      LibraryRoom(
        id: 'room_003',
        name: 'Discussion Room C',
        description: 'Collaborative space for group discussions and team projects',
        capacity: 6,
        amenities: ['WiFi', 'Whiteboard', 'Comfortable Seating', 'Flip Chart'],
        imageUrl: '/placeholder.svg?height=200&width=300',
        isAvailable: true,
        location: 'Level 2, Wing C',
        type: RoomType.discussion,
      ),
      LibraryRoom(
        id: 'room_004',
        name: 'Silent Study Pod',
        description: 'Ultra-quiet pod for focused individual study sessions',
        capacity: 1,
        amenities: ['WiFi', 'Desk Lamp', 'Power Outlet', 'Noise Cancellation'],
        imageUrl: '/placeholder.svg?height=200&width=300',
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
        imageUrl: '/placeholder.svg?height=200&width=300',
        isAvailable: true,
        location: 'Level 1, Tech Wing',
        type: RoomType.computer,
      ),
      LibraryRoom(
        id: 'room_006',
        name: 'Group Study Hall',
        description: 'Large space for group study sessions and collaborative work',
        capacity: 15,
        amenities: ['WiFi', 'Multiple Whiteboards', 'Movable Tables', 'Air Conditioning'],
        imageUrl: '/placeholder.svg?height=200&width=300',
        isAvailable: true,
        location: 'Level 3, Wing A',
        type: RoomType.group,
      ),
      LibraryRoom(
        id: 'room_007',
        name: 'Research Room E',
        description: 'Specialized room for research activities and academic work',
        capacity: 3,
        amenities: ['WiFi', 'Research Databases', 'Quiet Environment', 'Reference Materials'],
        imageUrl: '/placeholder.svg?height=200&width=300',
        isAvailable: true,
        location: 'Level 4, Research Wing',
        type: RoomType.study,
      ),
      LibraryRoom(
        id: 'room_008',
        name: 'Presentation Room F',
        description: 'Room equipped for presentations and seminars',
        capacity: 20,
        amenities: ['WiFi', 'Large Screen', 'Sound System', 'Microphone', 'Podium'],
        imageUrl: '/placeholder.svg?height=200&width=300',
        isAvailable: true,
        location: 'Level 3, Wing C',
        type: RoomType.meeting,
      ),
    ];
  }

  // Generate mock time slots for a specific date and room
  static List<TimeSlot> getMockTimeSlots({
    required String roomId,
    required DateTime date,
  }) {
    final timeSlots = <TimeSlot>[];
    final baseDate = DateTime(date.year, date.month, date.day);

    // Generate time slots from 9 AM to 9 PM (12 hours)
    for (int hour = 9; hour < 21; hour++) {
      final startTime = baseDate.add(Duration(hours: hour));
      final endTime = startTime.add(const Duration(hours: 1));

      // Simulate some booked slots for realism
      bool isAvailable = true;

      // Make some slots unavailable based on room and time
      if (roomId == 'room_001' && (hour == 10 || hour == 14)) {
        isAvailable = false; // Study Room A busy at 10 AM and 2 PM
      } else if (roomId == 'room_002' && (hour == 11 || hour == 15 || hour == 16)) {
        isAvailable = false; // Meeting Room B busy during common meeting times
      } else if (roomId == 'room_003' && hour == 13) {
        isAvailable = false; // Discussion Room C busy at lunch time
      } else if (roomId == 'room_005' && (hour >= 9 && hour <= 11)) {
        isAvailable = false; // Computer Lab busy in the morning
      }

      // Make past time slots unavailable if it's today
      final now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day &&
          startTime.isBefore(now)) {
        isAvailable = false;
      }

      timeSlots.add(TimeSlot(
        id: '${roomId}_${date.millisecondsSinceEpoch}_$hour',
        startTime: startTime,
        endTime: endTime,
        isAvailable: isAvailable,
      ));
    }

    return timeSlots;
  }

  // Get mock reservations for a user
  static List<RoomReservation> getMockReservations(String userId) {
    final now = DateTime.now();
    final rooms = getMockRooms();

    return [
      RoomReservation(
        id: 'reservation_001',
        userId: userId,
        roomId: 'room_001',
        roomName: 'Study Room A',
        date: now.add(const Duration(days: 1)),
        timeSlot: TimeSlot(
          id: 'slot_001',
          startTime: DateTime(now.year, now.month, now.day + 1, 10, 0),
          endTime: DateTime(now.year, now.month, now.day + 1, 11, 0),
          isAvailable: false,
        ),
        status: ReservationStatus.confirmed,
        createdAt: now.subtract(const Duration(hours: 2)),
        notes: 'Group study session for final exams',
      ),
      RoomReservation(
        id: 'reservation_002',
        userId: userId,
        roomId: 'room_002',
        roomName: 'Meeting Room B',
        date: now.add(const Duration(days: 3)),
        timeSlot: TimeSlot(
          id: 'slot_002',
          startTime: DateTime(now.year, now.month, now.day + 3, 14, 0),
          endTime: DateTime(now.year, now.month, now.day + 3, 15, 0),
          isAvailable: false,
        ),
        status: ReservationStatus.pending,
        createdAt: now.subtract(const Duration(minutes: 30)),
        notes: 'Project presentation meeting',
      ),
    ];
  }
}