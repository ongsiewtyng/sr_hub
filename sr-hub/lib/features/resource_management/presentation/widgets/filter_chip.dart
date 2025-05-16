import 'package:flutter/material.dart';
import 'package:sr_hub/core/theme/app_theme.dart';

class FilterChip extends StatelessWidget {
  final Widget label;
  final bool selected;
  final VoidCallback? onDeleted;
  final ValueChanged<bool>? onSelected;

  const FilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onDeleted,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: label,
      selected: selected,
      onSelected: onSelected,
      deleteIcon: onDeleted != null
          ? const Icon(
              Icons.close,
              size: 18,
            )
          : null,
      onDeleted: onDeleted,
      backgroundColor: selected ? AppTheme.primaryColor.withOpacity(0.1) : null,
      labelStyle: TextStyle(
        color: selected ? AppTheme.primaryColor : AppTheme.textPrimary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppTheme.primaryColor : AppTheme.borderColor,
        ),
      ),
    );
  }
} 