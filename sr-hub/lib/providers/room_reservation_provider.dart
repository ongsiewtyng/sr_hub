// lib/providers/room_reservation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/library_models.dart';
import 'mock_room_provider.dart'; // Add this import
import '../config/api_config.dart';
import '../services/room_reservation_service.dart';


// Selected date provider
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Selected room provider
final selectedRoomProvider = StateProvider<LibraryRoom?>((ref) => null);

// Selected time slot provider
final selectedTimeSlotProvider = StateProvider<TimeSlot?>((ref) => null);

// Available rooms provider - NOW USING MOCK DATA
final availableRoomsProvider = FutureProvider<List<LibraryRoom>>((ref) async {
  if (ApiConfig.useMockData) {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockRoomData.getAllRooms();
  } else {
    return await RoomReservationService.getAvailableRooms();
  }
});

// Rooms by type provider - NOW USING MOCK DATA
final roomsByTypeProvider = FutureProvider.family<List<LibraryRoom>, RoomType>((ref, type) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return MockRoomData.getRoomsByType(type);
});

// Available time slots provider - NOW USING MOCK DATA
final availableTimeSlotsProvider = FutureProvider.family<List<TimeSlot>, Map<String, dynamic>>((ref, params) async {
  final roomId = params['roomId'] as String;
  final date = params['date'] as DateTime;

  await Future.delayed(const Duration(milliseconds: 400));
  return MockRoomData.generateTimeSlots(roomId: roomId, date: date);
});

// User reservations provider - NOW USING MOCK DATA
final userReservationsProvider = FutureProvider<List<RoomReservation>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return MockRoomData.getUserReservations();
});

// Reservation state provider
final reservationStateProvider = StateNotifierProvider<ReservationStateNotifier, ReservationState>((ref) {
  return ReservationStateNotifier();
});

class ReservationState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  ReservationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ReservationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return ReservationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class ReservationStateNotifier extends StateNotifier<ReservationState> {
  ReservationStateNotifier() : super(ReservationState());

  Future<String?> makeReservation({
    required LibraryRoom room,
    required DateTime date,
    required TimeSlot timeSlot,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Use mock data instead of Firebase
      final reservationId = MockRoomData.addReservation(
        room: room,
        date: date,
        timeSlot: timeSlot,
        notes: notes,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Reservation confirmed!',
      );
      return reservationId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error: $e',
      );
      return null;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}