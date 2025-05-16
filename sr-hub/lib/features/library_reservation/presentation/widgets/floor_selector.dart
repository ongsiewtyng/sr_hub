import 'package:flutter/material.dart';
import 'package:sr_hub/core/theme/app_theme.dart';

class FloorSelector extends StatelessWidget {
  final int selectedFloor;
  final Function(int) onFloorSelected;

  const FloorSelector({
    super.key,
    required this.selectedFloor,
    required this.onFloorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFloorButton(1, '1st Floor'),
          const SizedBox(width: 8),
          _buildFloorButton(2, '2nd Floor'),
          const SizedBox(width: 8),
          _buildFloorButton(3, '3rd Floor'),
        ],
      ),
    );
  }

  Widget _buildFloorButton(int floor, String label) {
    final isSelected = floor == selectedFloor;
    return ElevatedButton(
      onPressed: () => onFloorSelected(floor),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryColor : AppTheme.backgroundSecondary,
        foregroundColor: isSelected ? Colors.white : AppTheme.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(label),
    );
  }
} 