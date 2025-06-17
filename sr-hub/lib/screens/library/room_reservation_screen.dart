// lib/screens/library/room_reservation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/library_models.dart';
import '../../providers/room_reservation_provider.dart';
import '../../services/sample_data_service.dart';
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
  int _currentStep = 0;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addTestRoomIfNeeded();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Reserve a Room'),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),

          // Page Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDateSelectionStep(),
                _buildRoomSelectionStep(),
                _buildTimeSlotSelectionStep(),
                _buildSummaryStep(),
              ],
            ),
          ),

          // Navigation Buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          for (int i = 0; i < 4; i++) ...[
            _buildStepIndicator(
              step: i + 1,
              title: _getStepTitle(i),
              isActive: i == _currentStep,
              isCompleted: i < _currentStep,
            ),
            if (i < 3)
              Expanded(
                child: Container(
                  height: 2,
                  color: i < _currentStep ? Theme.of(context).primaryColor : Colors.grey.shade300,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int step,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isActive
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Date';
      case 1: return 'Room';
      case 2: return 'Time';
      case 3: return 'Summary';
      default: return '';
    }
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
            'Choose the date for your room reservation',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          Card(
            child: CalendarDatePicker(
              initialDate: selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              onDateChanged: (date) {
                ref.read(selectedDateProvider.notifier).state = date;
              },
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selected: ${DateFormat('EEEE, MMMM d, y').format(selectedDate)}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            'Select Room',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a room that fits your needs',
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
                    child: Text('No rooms available'),
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
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Room Image
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade200,
                                ),
                                child: room.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    room.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        _getRoomIcon(room.type),
                                        size: 32,
                                        color: Colors.grey.shade400,
                                      );
                                    },
                                  ),
                                )
                                    : Icon(
                                  _getRoomIcon(room.type),
                                  size: 32,
                                  color: Colors.grey.shade400,
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Room Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      room.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      room.description,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${room.capacity} people',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                      ],
                                    ),
                                    if (room.amenities.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 4,
                                        children: room.amenities.take(3).map((amenity) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              amenity,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Selection Indicator
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).primaryColor,
                                  size: 24,
                                ),
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

  Widget _buildTimeSlotSelectionStep() {
    final selectedRoom = ref.watch(selectedRoomProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedTimeSlot = ref.watch(selectedTimeSlotProvider);

    if (selectedRoom == null) {
      return const Center(
        child: Text('Please select a room first'),
      );
    }

    final timeSlotsAsync = ref.watch(availableTimeSlotsProvider({
      'roomId': selectedRoom.id,
      'date': selectedDate,
    }));

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
          const SizedBox(height: 24),

          Expanded(
            child: timeSlotsAsync.when(
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => ErrorDisplay(
                message: 'Failed to load time slots: $error',
                onRetry: () => ref.invalidate(availableTimeSlotsProvider({
                  'roomId': selectedRoom.id,
                  'date': selectedDate,
                })),
              ),
              data: (timeSlots) {
                if (timeSlots.isEmpty) {
                  return const Center(
                    child: Text('No time slots available for this date'),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: timeSlots.length,
                  itemBuilder: (context, index) {
                    final timeSlot = timeSlots[index];
                    final isSelected = selectedTimeSlot?.id == timeSlot.id;
                    final isAvailable = timeSlot.isAvailable;

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
                        } : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
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
                            children: [
                              Text(
                                timeSlot.displayTime,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: !isAvailable
                                      ? Colors.grey.shade400
                                      : isSelected
                                      ? Theme.of(context).primaryColor
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'RM ${timeSlot.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: !isAvailable
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                              if (!isAvailable) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Booked',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
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

  Widget _buildSummaryStep() {
    final selectedRoom = ref.watch(selectedRoomProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedTimeSlot = ref.watch(selectedTimeSlotProvider);
    final reservationState = ref.watch(reservationStateProvider);

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
            'Please review your booking details',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Room Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getRoomIcon(selectedRoom.type),
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Room Details',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow('Room', selectedRoom.name),
                          _buildSummaryRow('Location', selectedRoom.location),
                          _buildSummaryRow('Capacity', '${selectedRoom.capacity} people'),
                          if (selectedRoom.amenities.isNotEmpty)
                            _buildSummaryRow('Amenities', selectedRoom.amenities.join(', ')),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Booking Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Booking Details',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow('Date', DateFormat('EEEE, MMMM d, y').format(selectedDate)),
                          _buildSummaryRow('Time', selectedTimeSlot.displayTime),
                          _buildSummaryRow('Duration', '${selectedTimeSlot.duration.inHours} hour(s)'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Price Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Price Details',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow('Hourly Rate', 'RM ${selectedRoom.hourlyRate.toStringAsFixed(2)}'),
                          _buildSummaryRow('Duration', '${selectedTimeSlot.duration.inHours} hour(s)'),
                          const Divider(),
                          _buildSummaryRow(
                            'Total Amount',
                            'RM ${selectedTimeSlot.price.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notes Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.note,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Additional Notes (Optional)',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              hintText: 'Any special requirements or notes...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Reserve Button
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: reservationState.isLoading ? null : _makeReservation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: reservationState.isLoading
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Processing...'),
                ],
              )
                  : Text(
                'Reserve Room - RM ${selectedTimeSlot.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                fontSize: isTotal ? 16 : 14,
                color: isTotal ? Theme.of(context).primaryColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final selectedRoom = ref.watch(selectedRoomProvider);
    final selectedTimeSlot = ref.watch(selectedTimeSlotProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                onPressed: _previousStep,
                child: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? (_currentStep < 3 ? _nextStep : null) : null,
              child: Text(_currentStep < 3 ? 'Next' : 'Complete'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: return true; // Date is always selected
      case 1: return ref.read(selectedRoomProvider) != null;
      case 2: return ref.read(selectedTimeSlotProvider) != null;
      case 3: return true;
      default: return false;
    }
  }

  Future<void> _addTestRoomIfNeeded() async {
    try {
      // Check if any rooms exist
      final rooms = await SampleDataService.checkExistingRooms();

      if (rooms.isEmpty) {
        print('🔄 No rooms found, adding test room...');
        await SampleDataService.addTestRoom();

        // Refresh the provider
        ref.invalidate(availableRoomsProvider);
      }
    } catch (e) {
      print('❌ Error checking/adding rooms: $e');
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
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
          title: const Text('Reservation Confirmed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your room has been successfully reserved.'),
              const SizedBox(height: 8),
              Text(
                'Reservation ID: $reservationId',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  IconData _getRoomIcon(RoomType type) {
    switch (type) {
      case RoomType.study: return Icons.menu_book;
      case RoomType.meeting: return Icons.meeting_room;
      case RoomType.discussion: return Icons.groups;
      case RoomType.silent: return Icons.volume_off;
      case RoomType.computer: return Icons.computer;
      case RoomType.group: return Icons.group_work;
    }
  }
}