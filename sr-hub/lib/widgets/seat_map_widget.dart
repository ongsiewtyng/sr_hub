// lib/widgets/seat_map_widget.dart
import 'package:flutter/material.dart';
import '../models/seat_model.dart';

class SeatMapWidget extends StatelessWidget {
  final List<Seat> seats;
  final String? selectedSeatId;
  final Function(Seat) onSeatTap;
  final double mapWidth;
  final double mapHeight;
  final String? mapImageUrl;
  final double seatSize;
  final double scale;

  const SeatMapWidget({
    Key? key,
    required this.seats,
    this.selectedSeatId,
    required this.onSeatTap,
    required this.mapWidth,
    required this.mapHeight,
    this.mapImageUrl,
    this.seatSize = 30,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: mapWidth,
      height: mapHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        image: mapImageUrl != null
            ? DecorationImage(
          image: NetworkImage(mapImageUrl!),
          fit: BoxFit.cover,
          opacity: 0.5,
        )
            : null,
      ),
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.5,
        maxScale: 3.0,
        child: Stack(
          children: seats.map((seat) {
            final isSelected = seat.id == selectedSeatId;
            return Positioned(
              left: seat.position['x'],
              top: seat.position['y'],
              child: GestureDetector(
                onTap: () => onSeatTap(seat),
                child: _buildSeatWidget(context, seat, isSelected),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSeatWidget(BuildContext context, Seat seat, bool isSelected) {
    final size = seat.type == SeatType.group ? seatSize * 1.5 : seatSize;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getSeatColor(seat.status, isSelected),
        borderRadius: BorderRadius.circular(seat.type == SeatType.group ? 8 : 4),
        border: Border.all(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade400,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getSeatIcon(seat.type),
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
              size: seat.type == SeatType.group ? 16 : 12,
            ),
            Text(
              seat.name,
              style: TextStyle(
                fontSize: seat.type == SeatType.group ? 12 : 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeatColor(SeatStatus status, bool isSelected) {
    if (isSelected) {
      return Colors.blue.shade100;
    }

    switch (status) {
      case SeatStatus.available:
        return Colors.green.shade100;
      case SeatStatus.occupied:
        return Colors.red.shade100;
      case SeatStatus.reserved:
        return Colors.orange.shade100;
      case SeatStatus.maintenance:
        return Colors.grey.shade300;
      default:
        return Colors.grey.shade100;
    }
  }

  IconData _getSeatIcon(SeatType type) {
    switch (type) {
      case SeatType.individual:
        return Icons.person;
      case SeatType.group:
        return Icons.people;
      case SeatType.quiet:
        return Icons.volume_off;
      case SeatType.computer:
        return Icons.computer;
      case SeatType.accessible:
        return Icons.accessible;
      default:
        return Icons.chair;
    }
  }
}