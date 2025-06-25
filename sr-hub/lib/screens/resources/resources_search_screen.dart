import 'dart:async';
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

// Add these to your providers file
final selectedAuthorProvider = StateProvider<String?>((ref) => null);
final selectedSubjectsProvider = StateProvider<List<String>>((ref) => []);

class ResourceSearchScreen extends ConsumerStatefulWidget {
  const ResourceSearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ResourceSearchScreen> createState() => _ResourceSearchScreenState();
}

class _ResourceSearchScreenState extends ConsumerState<ResourceSearchScreen> {
  final int _limit = 20;
  int _page = 0;
  final ScrollController _scrollController = ScrollController();
  List<ResearchPaperResource> _accumulatedResults = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Timer? _debounce;

  final List<String> hotKeywords = ['AI', 'Climate Change', 'Blockchain', 'COVID-19', 'Quantum', 'Sustainability'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        final query = ref.read(resourceSearchQueryProvider);
        if (query.trim().isNotEmpty) {
          _loadMore(query);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
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
      _hasMore = newResults.length == _limit;
      _isLoadingMore = false;
    });
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(resourceSearchQueryProvider.notifier).state = value;
      setState(() {
        _page = 0;
        _accumulatedResults = [];
        _hasMore = true;
      });
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: hotKeywords.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ActionChip(
                  label: Text(hotKeywords[i]),
                  onPressed: () => _onSearch(hotKeywords[i]),
                ),
              ),
            ),
          ),
          CustomSearchBar(
            hintText: 'Search for research papers',
            onSubmitted: _onSearch,
            showFilterButton: true,
            onFilterPressed: () => _showFilterSheet(context),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isQueryEmpty
                ? _buildTrendingContent()
                : ref.watch(paperSearchPaginatedProvider((query: query, page: 0, limit: _limit))).when(
              data: (results) {
                if (_accumulatedResults.isEmpty) {
                  _accumulatedResults = [...results];
                }

                if (_accumulatedResults.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const EmptyState(
                        message: 'No research papers found',
                        icon: Icons.search_off,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          ref.read(resourceSearchQueryProvider.notifier).state = '';
                        },
                        child: const Text('Clear Search'),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _accumulatedResults.length + (_hasMore ? 1 : 0),
                  itemBuilder: (_, index) {
                    if (index < _accumulatedResults.length) {
                      return ResourceCard(resource: _accumulatedResults[index]);
                    } else {
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
      data: (papers) => ListView.builder(
        itemCount: papers.length,
        itemBuilder: (_, i) => ResourceCard(resource: papers[i]),
      ),
      loading: () => const LoadingIndicator(message: 'Loading trending research papers...'),
      error: (e, _) => ErrorDisplay(message: 'Error: $e', onRetry: () => ref.refresh(trendingPapersProvider)),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final yearRange = ref.read(selectedYearRangeProvider);
    final minCitations = ref.read(selectedMinCitationsProvider);
    final openAccess = ref.read(openAccessOnlyProvider);
    final currentAuthor = ref.read(selectedAuthorProvider);
    final currentSubjects = ref.read(selectedSubjectsProvider);

    RangeValues selectedRange = yearRange ?? const RangeValues(2015, 2024);
    int selectedCitations = minCitations ?? 0;
    bool openAccessOnly = openAccess;
    String? author = currentAuthor;
    List<String> subjects = [...currentSubjects];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  TextFormField(
                    initialValue: author,
                    decoration: const InputDecoration(
                      labelText: 'Author',
                      prefixIcon: Icon(Icons.person_outline),
                      hintText: 'Enter author name',
                    ),
                    onChanged: (v) => setModalState(() => author = v),
                  ),

                  const SizedBox(height: 16),

                  Text('Subject Areas'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['AI', 'Biology', 'Economics', 'Physics', 'Psychology']
                        .map((s) => ChoiceChip(
                      label: Text(s),
                      selected: subjects.contains(s),
                      onSelected: (selected) {
                        setModalState(() {
                          selected ? subjects.add(s) : subjects.remove(s);
                        });
                      },
                    ))
                        .toList(),
                  ),

                  const SizedBox(height: 24),
                  Text('Year Range: ${selectedRange.start.toInt()} - ${selectedRange.end.toInt()}'),
                  RangeSlider(
                    values: selectedRange,
                    min: 2000,
                    max: DateTime.now().year.toDouble(),
                    divisions: 25,
                    onChanged: (v) => setModalState(() => selectedRange = v),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Min Citations'),
                      Expanded(
                        child: Slider(
                          value: selectedCitations.toDouble(),
                          min: 0,
                          max: 1000,
                          divisions: 20,
                          label: '$selectedCitations',
                          onChanged: (val) => setModalState(() => selectedCitations = val.toInt()),
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Checkbox(
                        value: openAccessOnly,
                        onChanged: (v) => setModalState(() => openAccessOnly = v ?? false),
                      ),
                      const Text('Open Access Only'),
                    ],
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Apply Filters'),
                    onPressed: () {
                      ref.read(selectedYearRangeProvider.notifier).state = selectedRange;
                      ref.read(selectedMinCitationsProvider.notifier).state = selectedCitations;
                      ref.read(openAccessOnlyProvider.notifier).state = openAccessOnly;
                      ref.read(selectedAuthorProvider.notifier).state = author;
                      ref.read(selectedSubjectsProvider.notifier).state = subjects;
                      Navigator.pop(context);
                      _onSearch(ref.read(resourceSearchQueryProvider));
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
