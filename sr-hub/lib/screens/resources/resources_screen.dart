import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/resource_models.dart';
import '../../providers/resource_providers.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/resource_card.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';
import '../../widgets/empty_state.dart';

class ResourceSearchScreen extends ConsumerStatefulWidget {
  const ResourceSearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ResourceSearchScreen> createState() => _ResourceSearchScreenState();
}

class _ResourceSearchScreenState extends ConsumerState<ResourceSearchScreen> {
  @override
  Widget build(BuildContext context) {
    final query = ref.watch(resourceSearchQueryProvider);
    final selectedType = ref.watch(selectedResourceTypeProvider);
    final searchResults = ref.watch(combinedSearchProvider(query));
    final isQueryEmpty = query.trim().isEmpty;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Resources',
      ),
      body: Column(
        children: [
          CustomSearchBar(
            hintText: 'Search for books or research papers',
            onSubmitted: (value) {
              ref.read(resourceSearchQueryProvider.notifier).state = value;
            },
            showFilterButton: false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<ResourceType?>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Filter by type',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onChanged: (type) {
                ref.read(selectedResourceTypeProvider.notifier).state = type;
              },
              items: const [
                DropdownMenuItem<ResourceType?>(value: null, child: Text('All Types')),
                DropdownMenuItem<ResourceType>(value: ResourceType.book, child: Text('Books')),
                DropdownMenuItem<ResourceType>(value: ResourceType.researchPaper, child: Text('Research Papers')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isQueryEmpty
                ? _buildTrendingContent()
                : searchResults.when(
              data: (resources) {
                if (resources.isEmpty) {
                  return const EmptyState(
                    message: 'No resources found',
                    icon: Icons.search_off,
                  );
                }
                return ListView.builder(
                  itemCount: resources.length,
                  itemBuilder: (context, index) {
                    return ResourceCard(resource: resources[index]);
                  },
                );
              },
              loading: () => const LoadingIndicator(message: 'Searching...'),
              error: (error, stack) => ErrorDisplay(
                message: 'Failed to load resources: $error',
                onRetry: () {
                  ref.refresh(combinedSearchProvider(query));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingContent() {
    final trendingBooks = ref.watch(trendingBooksProvider);
    final trendingPapers = ref.watch(trendingPapersProvider);

    return trendingBooks.when(
      data: (books) {
        return trendingPapers.when(
          data: (papers) {
            final combined = [...books, ...papers];
            if (combined.isEmpty) {
              return const EmptyState(
                message: 'No trending resources available',
                icon: Icons.trending_down,
              );
            }

            return ListView.builder(
              itemCount: combined.length,
              itemBuilder: (context, index) => ResourceCard(resource: combined[index]),
            );
          },
          loading: () => const LoadingIndicator(message: 'Loading trending research papers...'),
          error: (error, _) => ErrorDisplay(
            message: 'Error loading papers: $error',
            onRetry: () => ref.refresh(trendingPapersProvider),
          ),
        );
      },
      loading: () => const LoadingIndicator(message: 'Loading trending books...'),
      error: (error, _) => ErrorDisplay(
        message: 'Error loading books: $error',
        onRetry: () => ref.refresh(trendingBooksProvider),
      ),
    );
  }
}
