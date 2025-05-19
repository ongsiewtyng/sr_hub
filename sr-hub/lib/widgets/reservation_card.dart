// lib/widgets/reservation_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reservation_model.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onNavigate;
  final bool compact;

  const ReservationCard({
    Key? key,
    required this.reservation,
    required this.onTap,
    this.onCancel,
    this.onNavigate,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final startDate = dateFormat.format(reservation.startTime);
    final endDate = dateFormat.format(reservation.endTime);
    final startTime = timeFormat.format(reservation.startTime);
    final endTime = timeFormat.format(reservation.endTime);

    final isSameDay = startDate == endDate;
    final dateTimeText = isSameDay
        ? '$startDate, $startTime - $endTime'
        : '$startDate $startTime - $endDate $endTime';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with resource type and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: _getResourceTypeColor(reservation.resourceType).withOpacity(0.2),
                        child: Icon(
                          _getResourceTypeIcon(reservation.resourceType),
                          color: _getResourceTypeColor(reservation.resourceType),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatResourceType(reservation.resourceType),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(reservation.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatStatus(reservation.status),
                      style: TextStyle(
                        color: _getStatusColor(reservation.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Resource name
              Text(
                reservation.resourceName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              // Date and time
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateTimeText,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (reservation.isUpcoming && onCancel != null)
                      OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    if (reservation.isUpcoming && onNavigate != null) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: onNavigate,
                        icon: const Icon(Icons.directions, size: 16),
                        label: const Text('Navigate'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getResourceTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'seat':
        return Colors.blue;
      case 'room':
        return Colors.green;
      case 'book':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getResourceTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'seat':
        return Icons.event_seat;
      case 'room':
        return Icons.meeting_room;
      case 'book':
        return Icons.book;
      default:
        return Icons.bookmark;
    }
  }

  String _formatResourceType(String type) {
    return type.substring(0, 1).toUpperCase() + type.substring(1);
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
      case ReservationStatus.expired:
        return Colors.grey;
    }
  }

  String _formatStatus(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return 'CONFIRMED';
      case ReservationStatus.pending:
        return 'PENDING';
      case ReservationStatus.cancelled:
        return 'CANCELLED';
      case ReservationStatus.completed:
        return 'COMPLETED';
      case ReservationStatus.expired:
        return 'EXPIRED';
    }
  }
}