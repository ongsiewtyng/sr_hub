import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/library_models.dart';
import '../../providers/room_reservation_provider.dart';
import '../../services/room_reservation_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';

class MyReservationsScreen extends ConsumerWidget {
  const MyReservationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(roomReservationsProvider);

    return WillPopScope(
      onWillPop: () async {
        context.go('/'); //
        return false; // Prevent default pop
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'My Reservations',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.go('/'); // ⬅️ When AppBar back is tapped, go Home
            },
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(roomReservationsProvider);
            ref.invalidate(upcomingRoomReservationsProvider);
          },
          child: reservationsAsync.when(
            loading: () => const Center(child: LoadingIndicator()),
            error: (error, stack) => ErrorDisplay(
              message: 'Failed to load reservations: $error',
              onRetry: () {
                ref.invalidate(roomReservationsProvider);
                ref.invalidate(upcomingRoomReservationsProvider);
              },
            ),
            data: (reservations) {
              if (reservations.isEmpty) {
                return _buildEmptyState(context);
              }

              final upcomingReservations = reservations
                  .where((r) =>
              r.status == ReservationStatus.confirmed &&
                  r.date.isAfter(DateTime.now().subtract(const Duration(hours: 1))))
                  .toList();

              final pastReservations = reservations
                  .where((r) =>
              r.status == ReservationStatus.completed ||
                  (r.date.isBefore(DateTime.now().subtract(const Duration(hours: 1))) &&
                      r.status == ReservationStatus.confirmed))
                  .toList();

              final cancelledReservations = reservations
                  .where((r) => r.status == ReservationStatus.cancelled)
                  .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCards(upcomingReservations.length, pastReservations.length),
                    const SizedBox(height: 24),

                    if (upcomingReservations.isNotEmpty) ...[
                      _buildSectionHeader('Upcoming Reservations', upcomingReservations.length),
                      const SizedBox(height: 12),
                      ...upcomingReservations.map((reservation) =>
                          _buildReservationCard(context, ref, reservation, true)),
                      const SizedBox(height: 24),
                    ],

                    if (pastReservations.isNotEmpty) ...[
                      _buildSectionHeader('Past Reservations', pastReservations.length),
                      const SizedBox(height: 12),
                      ...pastReservations.map((reservation) =>
                          _buildReservationCard(context, ref, reservation, false)),
                      const SizedBox(height: 24),
                    ],

                    if (cancelledReservations.isNotEmpty) ...[
                      _buildSectionHeader('Cancelled Reservations', cancelledReservations.length),
                      const SizedBox(height: 12),
                      ...cancelledReservations.map((reservation) =>
                          _buildReservationCard(context, ref, reservation, false)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/reserve-room');
          },
          icon: const Icon(Icons.add),
          label: const Text('New Reservation'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No Reservations Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You haven\'t made any room reservations yet.\nStart by booking your first study room!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/reserve-room');
              },
              icon: const Icon(Icons.add),
              label: const Text('Make Your First Reservation'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(int upcoming, int past) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Upcoming',
            upcoming.toString(),
            Icons.schedule,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Completed',
            past.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReservationCard(BuildContext context, WidgetRef ref, RoomReservation reservation, bool isUpcoming) {
    final statusColor = _getStatusColor(reservation.status);
    final now = DateTime.now();
    final isToday = reservation.date.year == now.year &&
        reservation.date.month == now.month &&
        reservation.date.day == now.day;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isToday ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isToday ? BorderSide(color: Theme.of(context).primaryColor, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showReservationDetails(context, ref, reservation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.roomName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${reservation.id.substring(0, 8)}...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusText(reservation.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEEE, MMM d, y').format(reservation.date),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    reservation.timeSlot.displayTime,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const Spacer(),
                  Text(
                    '${reservation.timeSlot.duration.inHours}h duration',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              if (reservation.notes != null && reservation.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reservation.notes!,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Booked ${_getRelativeTime(reservation.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  if (isUpcoming && reservation.status == ReservationStatus.confirmed)
                    TextButton(
                      onPressed: () => _showCancelDialog(context, ref, reservation),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReservationDetails(BuildContext context, WidgetRef ref, RoomReservation reservation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Reservation Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              _buildDetailRow('Room', reservation.roomName, Icons.meeting_room),
              _buildDetailRow('Date', DateFormat('EEEE, MMMM d, y').format(reservation.date), Icons.calendar_today),
              _buildDetailRow('Time', reservation.timeSlot.displayTime, Icons.access_time),
              _buildDetailRow('Duration', '${reservation.timeSlot.duration.inHours} hour', Icons.schedule),
              _buildDetailRow('Status', _getStatusText(reservation.status), Icons.info,
                  color: _getStatusColor(reservation.status)),
              _buildDetailRow('Reservation ID', reservation.id, Icons.confirmation_number),
              _buildDetailRow('Booked On', DateFormat('MMM d, y \'at\' h:mm a').format(reservation.createdAt), Icons.history),

              if (reservation.notes != null && reservation.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    reservation.notes!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              if (reservation.status == ReservationStatus.confirmed &&
                  reservation.date.isAfter(DateTime.now().subtract(const Duration(hours: 1))))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCancelDialog(context, ref, reservation);
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel Reservation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: color ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, RoomReservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this reservation?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Room: ${reservation.roomName}'),
                  Text('Date: ${DateFormat('MMM d, y').format(reservation.date)}'),
                  Text('Time: ${reservation.timeSlot.displayTime}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Reservation'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await RoomReservationService.cancelReservation(reservation.id);
              if (success) {
                ref.invalidate(roomReservationsProvider);
                ref.invalidate(upcomingRoomReservationsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reservation cancelled successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to cancel reservation'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Reservation'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return Colors.green;
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.cancelled:
        return Colors.red;
      case ReservationStatus.completed:
        return Colors.blue;
    }
  }

  String _getStatusText(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return 'Confirmed';
      case ReservationStatus.pending:
        return 'Pending';
      case ReservationStatus.cancelled:
        return 'Cancelled';
      case ReservationStatus.completed:
        return 'Completed';
    }
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
