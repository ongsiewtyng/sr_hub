// lib/widgets/rating_widget.dart
import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool showLabel;
  final int? reviewCount;
  final int maxRating;

  const RatingWidget({
    Key? key,
    required this.rating,
    this.size = 16,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.showLabel = false,
    this.reviewCount,
    this.maxRating = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stars
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxRating, (index) {
            final value = index + 1;
            final isHalf = value > rating && value - 0.5 <= rating;
            final isFull = value <= rating;

            return Icon(
              isFull
                  ? Icons.star
                  : isHalf
                  ? Icons.star_half
                  : Icons.star_border,
              color: isFull || isHalf ? activeColor : inactiveColor,
              size: size,
            );
          }),
        ),
        // Rating label
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size * 0.8,
            ),
          ),
          // Review count
          if (reviewCount != null) ...[
            const SizedBox(width: 2),
            Text(
              '($reviewCount)',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: size * 0.7,
              ),
            ),
          ],
        ],
      ],
    );
  }
}