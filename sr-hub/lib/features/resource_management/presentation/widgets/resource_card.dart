import 'package:flutter/material.dart';
import 'package:sr_hub/core/theme/app_theme.dart';

class ResourceCard extends StatelessWidget {
  final String title;
  final String type;
  final String availability;
  final String location;

  const ResourceCard({
    super.key,
    required this.title,
    required this.type,
    required this.availability,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to resource details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildAvailabilityChip(availability),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _getTypeIcon(type),
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    type,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityChip(String availability) {
    Color chipColor;
    switch (availability.toLowerCase()) {
      case 'available':
        chipColor = AppTheme.successColor;
        break;
      case 'unavailable':
        chipColor = AppTheme.errorColor;
        break;
      case 'reserved':
        chipColor = AppTheme.warningColor;
        break;
      default:
        chipColor = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        availability,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'book':
        return Icons.book;
      case 'journal':
        return Icons.article;
      case 'article':
        return Icons.description;
      case 'database':
        return Icons.storage;
      case 'e-book':
        return Icons.tablet;
      case 'audio book':
        return Icons.headphones;
      case 'video':
        return Icons.video_library;
      default:
        return Icons.library_books;
    }
  }
} 