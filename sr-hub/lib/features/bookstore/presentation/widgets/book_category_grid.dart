import 'package:flutter/material.dart';
import 'package:sr_hub/core/theme/app_theme.dart';

class BookCategoryGrid extends StatelessWidget {
  const BookCategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Fiction', 'icon': Icons.book},
      {'name': 'Non-Fiction', 'icon': Icons.science},
      {'name': 'Textbooks', 'icon': Icons.school},
      {'name': 'Reference', 'icon': Icons.menu_book},
      {'name': 'Magazines', 'icon': Icons.article},
      {'name': 'Digital', 'icon': Icons.tablet},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(
          category['name'] as String,
          category['icon'] as IconData,
        );
      },
    );
  }

  Widget _buildCategoryCard(String name, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to category
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 