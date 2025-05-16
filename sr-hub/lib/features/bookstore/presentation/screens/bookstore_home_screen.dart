import 'package:flutter/material.dart';
import 'package:sr_hub/core/theme/app_theme.dart';
import 'package:sr_hub/features/bookstore/presentation/widgets/featured_books_carousel.dart';
import 'package:sr_hub/features/bookstore/presentation/widgets/book_category_grid.dart';
import 'package:sr_hub/features/bookstore/presentation/widgets/promotional_banner.dart';

class BookstoreHomeScreen extends StatelessWidget {
  const BookstoreHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookstore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // TODO: Navigate to wishlist
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search books...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundSecondary,
                ),
                onTap: () {
                  // TODO: Navigate to search screen
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: PromotionalBanner(),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Featured Books',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: FeaturedBooksCarousel(),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: BookCategoryGrid(),
          ),
        ],
      ),
    );
  }
} 