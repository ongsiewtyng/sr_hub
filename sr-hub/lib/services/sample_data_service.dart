// lib/services/sample_data_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/library_models.dart';

class SampleDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> addSampleRooms() async {
    final sampleRooms = [
      LibraryRoom(
        id: 'room_001',
        name: 'Study Room A',
        description: 'Quiet study room perfect for individual work and small groups',
        capacity: 4,
        amenities: ['WiFi', 'Whiteboard', 'Air Conditioning', 'Power Outlets'],
        imageUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
        isAvailable: true,
        hourlyRate: 10.0,
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
        hourlyRate: 25.0,
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
        hourlyRate: 15.0,
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
        hourlyRate: 8.0,
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
        hourlyRate: 20.0,
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
        hourlyRate: 30.0,
        location: 'Level 3, Wing A',
        type: RoomType.group,
      ),
    ];

    try {
      print('🔄 Starting to add sample rooms...');

      for (final room in sampleRooms) {
        await _firestore
            .collection('library_rooms')
            .doc(room.id)
            .set(room.toJson());

        print('✅ Added room: ${room.name}');
      }

      print('🎉 All sample rooms added successfully!');
    } catch (e) {
      print('❌ Error adding sample rooms: $e');
      rethrow;
    }
  }

  // Check if rooms already exist
  static Future<List<Map<String, dynamic>>> checkExistingRooms() async {
    try {
      final snapshot = await _firestore.collection('library_rooms').get();
      print('📊 Found ${snapshot.docs.length} rooms in database');

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Error checking existing rooms: $e');
      rethrow;
    }
  }

  // Clear all rooms (for testing)
  static Future<void> clearAllRooms() async {
    try {
      final snapshot = await _firestore.collection('library_rooms').get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('🗑️ Cleared ${snapshot.docs.length} rooms');
    } catch (e) {
      print('❌ Error clearing rooms: $e');
      rethrow;
    }
  }

  // Add a single test room quickly
  static Future<void> addTestRoom() async {
    try {
      final testRoom = LibraryRoom(
        id: 'test_room',
        name: 'Test Room',
        description: 'A test room to verify the system works',
        capacity: 2,
        amenities: ['WiFi', 'Table'],
        imageUrl: '',
        isAvailable: true,
        location: 'Test Location',
        type: RoomType.study,
      );

      await _firestore
          .collection('library_rooms')
          .doc(testRoom.id)
          .set(testRoom.toJson());

      print('✅ Test room added successfully!');
    } catch (e) {
      print('❌ Error adding test room: $e');
      rethrow;
    }
  }
}