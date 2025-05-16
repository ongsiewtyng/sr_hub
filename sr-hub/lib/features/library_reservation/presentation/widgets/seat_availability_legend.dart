import 'package:flutter/material.dart';
import 'package:sr_hub/core/theme/app_theme.dart';

class SeatAvailabilityLegend extends StatelessWidget {
  const SeatAvailabilityLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seat Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            _buildLegendItem('Available', AppTheme.seatAvailable),
            _buildLegendItem('Occupied', AppTheme.seatOccupied),
            _buildLegendItem('Reserved', AppTheme.seatReserved),
            _buildLegendItem('Unavailable', AppTheme.seatUnavailable),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
} 