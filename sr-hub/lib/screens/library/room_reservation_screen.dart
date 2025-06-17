import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../models/library_models.dart';
import '../../providers/room_reservation_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';

class RoomReservationScreen extends ConsumerStatefulWidget {
  const RoomReservationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RoomReservationScreen> createState() => _RoomReservationScreenState();
}

class _RoomReservationScreenState extends ConsumerState<RoomReservationScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _notesController = TextEditingController();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Reserve a Room'),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildRoomSelectionStep(),
                _buildDateSelectionStep(),
                _buildTimeSlotSelectionStep(),
                _buildSummaryStep(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildStepCircle(0, 'Room'),
          _buildStepLine(0),
          _buildStepCircle(1, 'Date'),
          _buildStepLine(1),
          _buildStepCircle(2, 'Time'),
          _buildStepLine(2),
          _buildStepCircle(3, 'Summary'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = step <= _currentStep;
    final isCurrent = step == _currentStep;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade300,
              border: isCurrent
                  ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                  : null,
            ),
            child: Center(
              child: isActive
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                '${step + 1}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = step < _currentStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive
            ? Theme.of(context).primaryColor
            : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildRoomSelectionStep() {
    final roomsAsync = ref.watch(availableRoomsProvider);
    final selectedRoom = ref.watch(selectedRoomProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a Room',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose from our available study rooms',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: roomsAsync.when(
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => ErrorDisplay(
                message: 'Failed to load rooms: $error',
                onRetry: () => ref.invalidate(availableRoomsProvider),
              ),
              data: (rooms) {
                if (rooms.isEmpty) {
                  return const Center(
                    child: Text('No rooms available at the moment'),
                  );
                }

                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final isSelected = selectedRoom?.id == room.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isSelected ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          ref.read(selectedRoomProvider.notifier).state = room;
                          print('🏠 Room selected: ${room.name}');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      room.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                room.description,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Capacity: ${room.capacity}',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    room.location,
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              if (room.amenities.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: room.amenities.map((amenity) {
                                    return Chip(
                                      label: Text(
                                        amenity,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectionStep() {
    final selectedDate = ref.watch(selectedDateProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred date',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CalendarDatePicker(
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    onDateChanged: (date) {
                      ref.read(selectedDateProvider.notifier).state = date;
                      print('📅 Date selected: ${date.toString()}');
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotSelectionStep() {
    final selectedRoom = ref.watch(selectedRoomProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedTimeSlot = ref.watch(selectedTimeSlotProvider);

    if (selectedRoom == null) {
      return const Center(
        child: Text('Please select a room first'),
      );
    }

    print('🔄 Building time slot step for room: ${selectedRoom.id}');

    // Use the provider that watches date changes
    final timeSlotsAsync = ref.watch(timeSlotsForRoomProvider(selectedRoom.id));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Time Slot',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred time slot for ${selectedRoom.name}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(selectedDate),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: timeSlotsAsync.when(
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) {
                print('❌ Time slots error: $error');
                return ErrorDisplay(
                  message: 'Failed to load time slots: $error',
                  onRetry: () {
                    print('🔄 Retrying time slots for room: ${selectedRoom.id}');
                    ref.invalidate(timeSlotsForRoomProvider(selectedRoom.id));
                  },
                );
              },
              data: (timeSlots) {
                print('✅ Received ${timeSlots.length} time slots in UI');

                if (timeSlots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text('No time slots available for this date'),
                        const SizedBox(height: 8),
                        Text(
                          'Please try selecting a different date',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.8, // Increased from 2.5 to give more height
                  ),
                  itemCount: timeSlots.length,
                  itemBuilder: (context, index) {
                    final timeSlot = timeSlots[index];
                    final isSelected = selectedTimeSlot?.id == timeSlot.id;
                    final isAvailable = timeSlot.isAvailable;

                    return _buildTimeSlotCard(timeSlot, isSelected, isAvailable);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Separate method for time slot card to fix overflow
  Widget _buildTimeSlotCard(TimeSlot timeSlot, bool isSelected, bool isAvailable) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: isAvailable ? () {
          ref.read(selectedTimeSlotProvider.notifier).state = timeSlot;
          print('⏰ Time slot selected: ${timeSlot.displayTime}');
        } : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8), // Reduced padding
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: !isAvailable
                ? Colors.grey.shade100
                : isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Important: Use minimum space
            children: [
              // Time display
              Flexible( // Use Flexible instead of fixed SizedBox
                child: Text(
                  timeSlot.displayTime,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13, // Slightly smaller font
                    color: !isAvailable
                        ? Colors.grey.shade400
                        : isSelected
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Small spacing
              const SizedBox(height: 2),

              // Duration
              Flexible(
                child: Text(
                  '${timeSlot.duration.inHours} hour',
                  style: TextStyle(
                    fontSize: 11, // Smaller font
                    color: !isAvailable
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),

              // Booked status (only if not available)
              if (!isAvailable) ...[
                const SizedBox(height: 2),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Booked',
                      style: TextStyle(
                        fontSize: 9, // Very small font
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStep() {
    final selectedRoom = ref.watch(selectedRoomProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedTimeSlot = ref.watch(selectedTimeSlotProvider);

    if (selectedRoom == null || selectedTimeSlot == null) {
      return const Center(
        child: Text('Please complete all previous steps'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your reservation details',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reservation Details',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSummaryRow(
                            icon: Icons.meeting_room,
                            label: 'Room',
                            value: selectedRoom.name,
                          ),
                          const SizedBox(height: 12),

                          _buildSummaryRow(
                            icon: Icons.location_on,
                            label: 'Location',
                            value: selectedRoom.location,
                          ),
                          const SizedBox(height: 12),

                          _buildSummaryRow(
                            icon: Icons.calendar_today,
                            label: 'Date',
                            value: DateFormat('EEEE, MMMM d, y').format(selectedDate),
                          ),
                          const SizedBox(height: 12),

                          _buildSummaryRow(
                            icon: Icons.access_time,
                            label: 'Time',
                            value: selectedTimeSlot.displayTime,
                          ),
                          const SizedBox(height: 12),

                          _buildSummaryRow(
                            icon: Icons.schedule,
                            label: 'Duration',
                            value: '${selectedTimeSlot.duration.inHours} hour',
                          ),
                          const SizedBox(height: 12),

                          _buildSummaryRow(
                            icon: Icons.people,
                            label: 'Capacity',
                            value: '${selectedRoom.capacity} people',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Additional Notes (Optional)',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Add any special requirements or notes...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final selectedRoom = ref.watch(selectedRoomProvider);
    final selectedTimeSlot = ref.watch(selectedTimeSlotProvider);
    final reservationState = ref.watch(reservationStateProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: reservationState.isLoading ? null : () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Back'),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          Expanded(
            child: ElevatedButton(
              onPressed: _getNextButtonAction(selectedRoom, selectedTimeSlot, reservationState),
              child: reservationState.isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(_getNextButtonText()),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getNextButtonAction(
      LibraryRoom? selectedRoom,
      TimeSlot? selectedTimeSlot,
      AsyncValue<String?> reservationState,
      ) {
    if (reservationState.isLoading) return null;

    switch (_currentStep) {
      case 0:
        return selectedRoom != null ? _nextStep : null;
      case 1:
        return _nextStep;
      case 2:
        return selectedTimeSlot != null ? _nextStep : null;
      case 3:
        return _makeReservation;
      default:
        return null;
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
      case 1:
      case 2:
        return 'Next';
      case 3:
        return 'Confirm Reservation';
      default:
        return 'Next';
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _makeReservation() async {
    final selectedRoom = ref.read(selectedRoomProvider);
    final selectedDate = ref.read(selectedDateProvider);
    final selectedTimeSlot = ref.read(selectedTimeSlotProvider);

    if (selectedRoom == null || selectedTimeSlot == null) return;

    final reservationId = await ref.read(reservationStateProvider.notifier).makeReservation(
      room: selectedRoom,
      date: selectedDate,
      timeSlot: selectedTimeSlot,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (reservationId != null && mounted) {
      // Invalidate providers to refresh data - using correct provider names
      ref.invalidate(roomReservationsProvider);
      ref.invalidate(upcomingRoomReservationsProvider);

      // Show success dialog with redirect
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
          title: const Text('Reservation Confirmed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your room has been successfully reserved.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Reservation Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Room: ${selectedRoom.name}'),
                    Text('Date: ${DateFormat('MMM d, y').format(selectedDate)}'),
                    Text('Time: ${selectedTimeSlot.displayTime}'),
                    const SizedBox(height: 8),
                    Text(
                      'ID: $reservationId',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _clearSelectionsAndNavigateToReservations();
              },
              child: const Text('View My Reservations'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _redirectToHome();
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.error,
            color: Colors.red,
            size: 48,
          ),
          title: const Text('Reservation Failed'),
          content: const Text('Sorry, we couldn\'t complete your reservation. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _clearSelectionsAndNavigateToReservations() {
    // Clear all selections
    ref.read(selectedRoomProvider.notifier).state = null;
    ref.read(selectedTimeSlotProvider.notifier).state = null;
    ref.read(selectedDateProvider.notifier).state = DateTime.now();

    // Navigate to reservations page using GoRouter
    context.go('/my-reservations');
  }

  void _redirectToHome() {
    // Clear all selections
    ref.read(selectedRoomProvider.notifier).state = null;
    ref.read(selectedTimeSlotProvider.notifier).state = null;
    ref.read(selectedDateProvider.notifier).state = DateTime.now();

    // Navigate to home using GoRouter
    context.go('/');
  }
}
