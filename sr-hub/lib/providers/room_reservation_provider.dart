import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/library_models.dart';
import '../services/room_reservation_service.dart';

// Selected room provider
final selectedRoomProvider = StateProvider<LibraryRoom?>((ref) => null);

// Selected date provider
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Selected time slot provider
final selectedTimeSlotProvider = StateProvider<TimeSlot?>((ref) => null);

// Available rooms provider
final availableRoomsProvider = FutureProvider<List<LibraryRoom>>((ref) async {
  print('🔄 Fetching available rooms...');
  final rooms = await RoomReservationService.getAvailableRooms();
  print('✅ Rooms provider returned ${rooms.length} rooms');
  return rooms;
});

// Time slots for a specific room provider
final timeSlotsForRoomProvider = FutureProvider.family<List<TimeSlot>, String>((ref, roomId) async {
  final selectedDate = ref.watch(selectedDateProvider);
  print('🔄 Fetching time slots for room: $roomId on ${selectedDate.toString()}');

  final timeSlots = await RoomReservationService.getAvailableTimeSlots(
    roomId: roomId,
    date: selectedDate,
  );

  print('✅ Time slots provider returned ${timeSlots.length} slots');
  return timeSlots;
});

// Renamed to avoid conflict with firestore provider
final roomReservationsProvider = FutureProvider<List<RoomReservation>>((ref) async {
  print('🔄 Fetching room reservations...');
  final reservations = await RoomReservationService.getUserReservations();
  print('✅ Room reservations provider returned ${reservations.length} reservations');
  return reservations;
});

// Upcoming room reservations provider (for home screen)
final upcomingRoomReservationsProvider = FutureProvider<List<RoomReservation>>((ref) async {
  print('🔄 Fetching upcoming room reservations...');
  final allReservations = await RoomReservationService.getUserReservations();

  // Filter for upcoming reservations only
  final now = DateTime.now();
  final upcomingReservations = allReservations
      .where((reservation) =>
  reservation.status == ReservationStatus.confirmed &&
      reservation.date.isAfter(now.subtract(const Duration(hours: 1))))
      .toList();

  // Sort by date and time
  upcomingReservations.sort((a, b) => a.date.compareTo(b.date));

  print('✅ Upcoming room reservations provider returned ${upcomingReservations.length} reservations');
  return upcomingReservations;
});

// Reservation state notifier for making reservations
final reservationStateProvider = StateNotifierProvider<ReservationStateNotifier, AsyncValue<String?>>((ref) {
  return ReservationStateNotifier();
});

class ReservationStateNotifier extends StateNotifier<AsyncValue<String?>> {
  ReservationStateNotifier() : super(const AsyncValue.data(null));

  Future<String?> makeReservation({
    required LibraryRoom room,
    required DateTime date,
    required TimeSlot timeSlot,
    String? notes,
  }) async {
    state = const AsyncValue.loading();

    try {
      print('🔄 Making reservation...');
      final reservationId = await RoomReservationService.makeReservation(
        room: room,
        date: date,
        timeSlot: timeSlot,
        notes: notes,
      );

      if (reservationId != null) {
        state = AsyncValue.data(reservationId);
        print('✅ Reservation successful: $reservationId');
        return reservationId;
      } else {
        state = const AsyncValue.error('Failed to create reservation', StackTrace.empty);
        print('❌ Reservation failed');
        return null;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      print('❌ Reservation error: $error');
      return null;
    }
  }
}
