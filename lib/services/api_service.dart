import 'dart:convert';
import 'package:http/http.dart' as http;

/// ---------------------------------------------------------------------------
/// MODELLI DATI – TrustCheck 2.1 (NO scoring globale)
/// ---------------------------------------------------------------------------

class SearchResultItem {
  final String title;
  final String snippet;
  final String link;
  final String source;
  final int position; // 1..n
  final bool isNegative;
  final bool isAuthorityOrRegulator;

  SearchResultItem({
    required this.title,
    required this.snippet,
    required this.link,
    required this.source,
    required this.position,
    required this.isNegative,
    required this.isAuthorityOrRegulator,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v == null) return false;
      final s = v.toString().toLowerCase();
      return s == 'true' || s == '1';
    }

    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v == null) return 0;
      return int.tryParse(v.toString()) ?? 0;
    }

    return SearchResultItem(
      title: json['title']?.toString() ?? '',
      snippet: json['snippet']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      source: json['source']?.toString() ?? json['displayLink']?.toString() ?? '',
      position: parseInt(json['position']),
      isNegative: parseBool(json['is_negative'] ?? json['isNegative']),
      isAuthorityOrRegulator: parseBool(
        json['is_authority_or_regulator'] ?? json['isAuthorityOrRegulator'],
      ),
    );
  }
}

class TrustCheckResult {
  final String query;
  final int totalResults;
  final int negativeResults;
  final List<SearchResultItem> results;
  final int elapsedMs;

  TrustCheckResult({
    required this.query,
    required this.totalResults,
    required this.negativeResults,
    required this.results,
    required this.elapsedMs,
  });

  factory TrustCheckResult.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v == null) return 0;
      return int.tryParse(v.toString()) ?? 0;
    }

    final query = json['query']?.toString() ?? '';

    final resultsJson = (json['results'] as List<dynamic>?) ?? const <dynamic>[];
    final results = resultsJson
        .whereType<Map<String, dynamic>>()
        .map(SearchResultItem.fromJson)
        .toList();

    final totalResults = parseInt(json['total_results'] ?? json['totalResults']);
    final negativeResultsFromBackend =
        parseInt(json['negative_results'] ?? json['negativeResults']);
    final elapsedMs = parseInt(json['elapsed_ms'] ?? json['elapsedMs']);

    final computedNegatives = results.where((r) => r.isNegative).length;

    return TrustCheckResult(
      query: query,
      totalResults: totalResults == 0 ? results.length : totalResults,
      negativeResults: negativeResultsFromBackend == 0 ? computedNegatives : negativeResultsFromBackend,
      results: results,
      elapsedMs: elapsedMs,
    );
  }
}

/// ---------------------------------------------------------------------------
/// SERVIZIO HTTP
/// ---------------------------------------------------------------------------

class ApiService {
  static const String baseUrl = 'https://trustcheck-backend-z5ad.onrender.com';

  static Future<TrustCheckResult> analyzeReputation(String query) async {
    final uri = Uri.parse('$baseUrl/analyze');

    try {
      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(<String, dynamic>{'query': query}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TrustCheckResult.fromJson(data);
      } else {
        throw Exception('Errore backend ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Errore di connessione al motore TrustCheck: $e');
    }
  }
}
