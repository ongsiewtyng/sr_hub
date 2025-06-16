// lib/screens/debug/open_library_test_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/open_library_service.dart';
import '../../models/open_library_models.dart';

class OpenLibraryTestScreen extends ConsumerStatefulWidget {
  const OpenLibraryTestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OpenLibraryTestScreen> createState() => _OpenLibraryTestScreenState();
}

class _OpenLibraryTestScreenState extends ConsumerState<OpenLibraryTestScreen> {
  bool _isLoading = false;
  String _results = '';

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _results = 'Running Open Library API tests...\n\n';
    });

    final buffer = StringBuffer();

    // Test 1: Basic Search
    buffer.writeln('=== BASIC SEARCH TEST ===');
    try {
      final response = await OpenLibraryService.searchBooks(query: 'harry potter');
      if (response != null && response.docs.isNotEmpty) {
        buffer.writeln('✅ Basic search: SUCCESS');
        buffer.writeln('   Found ${response.docs.length} books');
        buffer.writeln('   First book: ${response.docs.first.title}');
      } else {
        buffer.writeln('❌ Basic search: FAILED - No results');
      }
    } catch (e) {
      buffer.writeln('❌ Basic search: ERROR - $e');
    }
    buffer.writeln('');

    // Test 2: Subject Search
    buffer.writeln('=== SUBJECT SEARCH TEST ===');
    try {
      final books = await OpenLibraryService.getBooksBySubject(subject: 'science fiction');
      if (books.isNotEmpty) {
        buffer.writeln('✅ Subject search: SUCCESS');
        buffer.writeln('   Found ${books.length} science fiction books');
      } else {
        buffer.writeln('❌ Subject search: FAILED - No results');
      }
    } catch (e) {
      buffer.writeln('❌ Subject search: ERROR - $e');
    }
    buffer.writeln('');

    // Test 3: Trending Books
    buffer.writeln('=== TRENDING BOOKS TEST ===');
    try {
      final books = await OpenLibraryService.getTrendingBooks(limit: 10);
      if (books.isNotEmpty) {
        buffer.writeln('✅ Trending books: SUCCESS');
        buffer.writeln('   Found ${books.length} trending books');
      } else {
        buffer.writeln('❌ Trending books: FAILED - No results');
      }
    } catch (e) {
      buffer.writeln('❌ Trending books: ERROR - $e');
    }
    buffer.writeln('');

    // Test 4: Book Details
    buffer.writeln('=== BOOK DETAILS TEST ===');
    try {
      final searchResponse = await OpenLibraryService.searchBooks(query: 'the great gatsby');
      if (searchResponse != null && searchResponse.docs.isNotEmpty) {
        final book = searchResponse.docs.first;
        final details = await OpenLibraryService.getBookDetails(book.id);
        if (details != null) {
          buffer.writeln('✅ Book details: SUCCESS');
          buffer.writeln('   Book: ${details.title}');
          buffer.writeln('   Has description: ${details.description != null}');
        } else {
          buffer.writeln('❌ Book details: FAILED - No details found');
        }
      } else {
        buffer.writeln('❌ Book details: FAILED - No book to get details for');
      }
    } catch (e) {
      buffer.writeln('❌ Book details: ERROR - $e');
    }

    buffer.writeln('\n=== TEST SUMMARY ===');
    final successCount = buffer.toString().split('✅').length - 1;
    final failCount = buffer.toString().split('❌').length - 1;
    buffer.writeln('✅ Successful tests: $successCount');
    buffer.writeln('❌ Failed tests: $failCount');

    setState(() {
      _isLoading = false;
      _results = buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Library API Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _runTests,
              child: _isLoading
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Running Tests...'),
                ],
              )
                  : const Text('Run Open Library Tests'),
            ),
            const SizedBox(height: 16),
            if (_results.isNotEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _results,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}