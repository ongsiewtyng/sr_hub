// lib/services/semantic_scholar_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/resource_models.dart'; // Use the main resource models file

class SemanticScholarService {
  static const String _baseUrl = 'https://api.semanticscholar.org/graph/v1';
  static const Duration _timeout = Duration(seconds: 30);

  // Search papers
  static Future<List<ResearchPaperResource>> searchPapers({
    required String query,
    int limit = 20,
    int offset = 0,
    List<String>? fields,
  }) async {
    try {
      final searchFields = fields ?? [
        'paperId',
        'title',
        'abstract',
        'authors',
        'venue',
        'year',
        'citationCount',
        'fieldsOfStudy',
        'url',
        'openAccessPdf',
        'publicationDate',
      ];


      final queryParams = {
        'query': query.trim(),
        'limit': limit.toString(),
        'offset': offset.toString(),
        'fields': searchFields.join(','),
      };

      final uri = Uri.parse('$_baseUrl/paper/search').replace(queryParameters: queryParams);

      print('🔍 Semantic Scholar Search: $uri');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'StudyResourceHub/1.0 (Flutter App)',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      print('📊 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final papers = data['data'] as List? ?? [];

        return papers
            .map((paper) => ResearchPaperResource.fromSemanticScholar(paper))
            .where((paper) => paper.title.isNotEmpty)
            .toList();
      } else {
        print('❌ Semantic Scholar API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Semantic Scholar Search Error: $e');
      return [];
    }
  }

  // Get paper details by ID
  static Future<ResearchPaperResource?> getPaperDetails(String paperId) async {
    try {
      final fields = [
        'paperId',
        'title',
        'abstract',
        'authors',
        'venue',
        'year',
        'citationCount',
        'fieldsOfStudy',
        'url',
        'doi',
        'openAccessPdf',
        'publicationDate',
        'references',
        'citations',
      ];

      final queryParams = {
        'fields': fields.join(','),
      };

      final uri = Uri.parse('$_baseUrl/paper/$paperId').replace(queryParameters: queryParams);

      print('📄 Fetching paper details: $uri');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'StudyResourceHub/1.0 (Flutter App)',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ResearchPaperResource.fromSemanticScholar(data);
      } else {
        print('❌ Paper Details Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Paper Details Error: $e');
      return null;
    }
  }

  // Get papers by field of study
  static Future<List<ResearchPaperResource>> getPapersByField({
    required String fieldOfStudy,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await searchPapers(
        query: 'fieldsOfStudy:$fieldOfStudy',
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      print('❌ Papers by Field Error: $e');
      return [];
    }
  }

  // Get trending papers (highly cited recent papers)
  static Future<List<ResearchPaperResource>> getTrendingPapers({
    int limit = 20,
    int minCitations = 10,
  }) async {
    try {
      final currentYear = DateTime.now().year;
      final queries = [
        'year:${currentYear - 1}-$currentYear',
        'year:${currentYear - 2}-${currentYear - 1}',
        'citationCount:[$minCitations TO *]',
      ];

      final allPapers = <ResearchPaperResource>[];

      for (final query in queries) {
        final papers = await searchPapers(
          query: query,
          limit: limit ~/ queries.length,
        );
        allPapers.addAll(papers);
      }

      // Sort by citation count and return unique papers
      final uniquePapers = <String, ResearchPaperResource>{};
      for (final paper in allPapers) {
        if (!uniquePapers.containsKey(paper.id)) {
          uniquePapers[paper.id] = paper;
        }
      }

      final sortedPapers = uniquePapers.values.toList();
      sortedPapers.sort((a, b) => (b.citationCount ?? 0).compareTo(a.citationCount ?? 0));

      return sortedPapers.take(limit).toList();
    } catch (e) {
      print('❌ Trending Papers Error: $e');
      return [];
    }
  }

  // Check API status
  static Future<bool> checkApiStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/paper/search?query=test&limit=1'),
        headers: {
          'User-Agent': 'StudyResourceHub/1.0 (Flutter App)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}