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
  int _page = 0;
  final int _limit = 20;
  final ScrollController _scrollController = ScrollController();
  List<ResearchPaperResource> _accumulatedResults = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMore(String query) async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final newResults = await ref.read(
      paperSearchPaginatedProvider((query: query, page: _page + 1, limit: _limit)).future,
    );

    setState(() {
      _page++;
      _accumulatedResults.addAll(newResults);
      _isLoadingMore = false;
      _hasMore = newResults.length == _limit;
    });
  }

  void _onSearch(String value) {
    ref.read(resourceSearchQueryProvider.notifier).state = value;
    setState(() {
      _page = 0;
      _accumulatedResults = [];
      _hasMore = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(resourceSearchQueryProvider);
    final isQueryEmpty = query.trim().isEmpty;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Research Papers'),
      body: Column(
        children: [
          CustomSearchBar(
            hintText: 'Search for research papers',
            onSubmitted: _onSearch,
            showFilterButton: true,
            onFilterPressed: () => _showFilterSheet(context),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isQueryEmpty
                ? _buildTrendingContent()
                : ref.watch(
              paperSearchPaginatedProvider((query: query, page: 0, limit: _limit)),
            ).when(
              data: (results) {
                if (_accumulatedResults.isEmpty) {
                  _accumulatedResults = [...results];
                }
                if (_accumulatedResults.isEmpty) {
                  return const EmptyState(
                    message: 'No research papers found',
                    icon: Icons.search_off,
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: _accumulatedResults.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _accumulatedResults.length) {
                      return ResourceCard(resource: _accumulatedResults[index]);
                    } else {
                      _loadMore(query);
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                );
              },
              loading: () => const LoadingIndicator(message: 'Searching...'),
              error: (error, _) => ErrorDisplay(
                message: 'Error searching papers: $error',
                onRetry: () {
                  ref.refresh(paperSearchPaginatedProvider((query: query, page: 0, limit: _limit)));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingContent() {
    final trending = ref.watch(trendingPapersProvider);

    return trending.when(
      data: (papers) {
        if (papers.isEmpty) {
          return const EmptyState(
            message: 'No trending research papers available',
            icon: Icons.trending_down,
          );
        }

        return ListView.builder(
          itemCount: papers.length,
          itemBuilder: (context, index) => ResourceCard(resource: papers[index]),
        );
      },
      loading: () => const LoadingIndicator(message: 'Loading trending research papers...'),
      error: (error, _) => ErrorDisplay(
        message: 'Error loading papers: $error',
        onRetry: () => ref.refresh(trendingPapersProvider),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final yearRange = ref.read(selectedYearRangeProvider);
    final minCitations = ref.read(selectedMinCitationsProvider);
    final openAccess = ref.read(openAccessOnlyProvider);

    RangeValues selectedRange = yearRange ?? const RangeValues(2015, 2024);
    int selectedCitations = minCitations ?? 0;
    bool openAccessOnly = openAccess;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  Text('Year Range: ${selectedRange.start.toInt()} - ${selectedRange.end.toInt()}'),
                  RangeSlider(
                    min: 2000,
                    max: DateTime.now().year.toDouble(),
                    divisions: 24,
                    values: selectedRange,
                    onChanged: (range) => setModalState(() => selectedRange = range),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Min Citations:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: selectedCitations.toDouble(),
                          min: 0,
                          max: 1000,
                          divisions: 20,
                          label: selectedCitations.toString(),
                          onChanged: (val) => setModalState(() => selectedCitations = val.toInt()),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: openAccessOnly,
                        onChanged: (value) => setModalState(() => openAccessOnly = value ?? false),
                      ),
                      const Text('Open Access Only'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(selectedYearRangeProvider.notifier).state = selectedRange;
                      ref.read(selectedMinCitationsProvider.notifier).state = selectedCitations;
                      ref.read(openAccessOnlyProvider.notifier).state = openAccessOnly;

                      _onSearch(ref.read(resourceSearchQueryProvider));
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('Apply Filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
