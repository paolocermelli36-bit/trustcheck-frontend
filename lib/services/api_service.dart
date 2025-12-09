import 'dart:convert';
import 'package:http/http.dart' as http;

/// ---------------------------------------------------------------------------
/// MODELLI DATI
/// ---------------------------------------------------------------------------

/// Risultato singolo (tutti i link, fino a 100)
class SearchResultItem {
  final String title;
  final String snippet;
  final String link;
  final String source;
  final int position; // 1..100
  final bool isNegative;
  final String severity; // "none" | "low" | "medium" | "high"
  final bool isAuthorityOrRegulator;

  SearchResultItem({
    required this.title,
    required this.snippet,
    required this.link,
    required this.source,
    required this.position,
    required this.isNegative,
    required this.severity,
    required this.isAuthorityOrRegulator,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      title: json['title']?.toString() ?? '',
      snippet: json['snippet']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      position: _parseInt(json['position']),
      isNegative: json['is_negative'] == true,
      severity: json['severity']?.toString() ?? 'none',
      isAuthorityOrRegulator: json['is_authority_or_regulator'] == true,
    );
  }
}

/// Negativo singolo (sottinsieme dei risultati)
class NegativeItem {
  final String title;
  final String snippet;
  final String link;
  final String source;
  final int position;
  final String severity;
  final bool isAuthorityOrRegulator;

  /// compatibilità UI: alcune versioni della schermata
  /// usano n.categories → qui la esponiamo, anche se di default è vuota.
  final List<String> categories;

  NegativeItem({
    required this.title,
    required this.snippet,
    required this.link,
    required this.source,
    required this.position,
    required this.severity,
    required this.isAuthorityOrRegulator,
    required this.categories,
  });

  factory NegativeItem.fromJson(Map<String, dynamic> json) {
    final categoriesJson = json['categories'] as List<dynamic>? ?? const [];
    return NegativeItem(
      title: json['title']?.toString() ?? '',
      snippet: json['snippet']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      position: _parseInt(json['position']),
      severity: json['severity']?.toString() ?? 'low',
      isAuthorityOrRegulator: json['is_authority_or_regulator'] == true,
      categories: categoriesJson.map((e) => e.toString()).toList(),
    );
  }
}

/// Risultato complessivo di TrustCheck
class TrustCheckResult {
  final String query;

  /// score 0..100 dal backend
  final int score;

  /// livello di rischio dal backend ("VERY LOW" | "LOW" | "MEDIUM" | "HIGH")
  final String risk;

  final int totalResults;
  final int negativeResults;

  /// categorie generali (es. ["financial", "legal", "other"])
  final List<String> categories;

  /// lista dei soli link negativi (per "Top negative links")
  final List<NegativeItem> negatives;

  /// lista di TUTTI i risultati (per la lista completa scrollabile)
  final List<SearchResultItem> results;

  final int elapsedMs;

  /// campi aggiunti per compatibilità con la UI attuale
  /// (Key signals + Summary)
  final String summary;
  final List<String> flags;

  TrustCheckResult({
    required this.query,
    required this.score,
    required this.risk,
    required this.totalResults,
    required this.negativeResults,
    required this.categories,
    required this.negatives,
    required this.results,
    required this.elapsedMs,
    required this.summary,
    required this.flags,
  });

  /// Getter di compatibilità per la UI esistente
  /// (la schermata usa ancora riskLevel / negativeLinks)
  String get riskLevel => risk;
  int get negativeLinks => negativeResults;

  factory TrustCheckResult.fromJson(Map<String, dynamic> json) {
    final query = json['query']?.toString() ?? '';
    final score = _parseInt(json['score']);
    final risk = json['risk']?.toString() ?? 'VERY LOW';
    final totalResults = _parseInt(json['total_results']);
    final negativeResults = _parseInt(json['negative_results']);

    final categoriesJson = json['categories'] as List<dynamic>? ?? const [];
    final negativesJson = json['negatives'] as List<dynamic>? ?? const [];
    final resultsJson = json['results'] as List<dynamic>? ?? const [];
    final flagsJson = json['flags'] as List<dynamic>? ?? const [];

    final parsedCategories = categoriesJson.map((e) => e.toString()).toList();

    final parsedNegatives = negativesJson
        .map((e) => NegativeItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final parsedResults = resultsJson
        .map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final elapsedMs = _parseInt(json['elapsed_ms']);

    // summary: se il backend lo fornisce, usiamo quello; altrimenti generiamo un testo base
    final backendSummary = json['summary']?.toString();
    final autoSummary = _buildDefaultSummary(
      query: query,
      risk: risk,
      score: score,
      totalResults: totalResults,
      negativeResults: negativeResults,
    );
    final summary =
        (backendSummary != null && backendSummary.trim().isNotEmpty)
            ? backendSummary
            : autoSummary;

    // flags: se il backend li fornisce, usiamo quelli; altrimenti generiamo in base a score/negativi
    final parsedFlags = flagsJson.isNotEmpty
        ? flagsJson.map((e) => e.toString()).toList()
        : _buildDefaultFlags(
            risk: risk,
            score: score,
            totalResults: totalResults,
            negativeResults: negativeResults,
          );

    return TrustCheckResult(
      query: query,
      score: score,
      risk: risk,
      totalResults: totalResults,
      negativeResults: negativeResults,
      categories: parsedCategories,
      negatives: parsedNegatives,
      results: parsedResults,
      elapsedMs: elapsedMs,
      summary: summary,
      flags: parsedFlags,
    );
  }
}

/// helper robusto per interi
int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

/// summary di default, se il backend non ne manda uno
String _buildDefaultSummary({
  required String query,
  required String risk,
  required int score,
  required int totalResults,
  required int negativeResults,
}) {
  if (totalResults == 0) {
    return "Per la query '$query' non sono stati trovati risultati sufficienti per una valutazione reputazionale.";
  }

  if (negativeResults == 0) {
    return "Analisi per '$query': non emergono risultati chiaramente negativi nelle prime pagine di Google. "
        "Il livello di rischio stimato è $risk (score $score/100).";
  }

  return "Analisi per '$query': livello di rischio $risk (score $score/100), "
      "$negativeResults risultati potenzialmente negativi su $totalResults "
      "nelle prime pagine di Google.";
}

/// flags di default, se il backend non ne manda
List<String> _buildDefaultFlags({
  required String risk,
  required int score,
  required int totalResults,
  required int negativeResults,
}) {
  final flags = <String>[];

  if (totalResults == 0) {
    flags.add("Dati insufficienti per una valutazione affidabile.");
    return flags;
  }

  if (negativeResults == 0) {
    flags.add("Nessun risultato chiaramente negativo individuato nelle prime pagine.");
    return flags;
  }

  // base su numero di negativi
  final ratio = totalResults > 0 ? (negativeResults / totalResults) : 0.0;

  if (ratio >= 0.3) {
    flags.add("Elevata concentrazione di risultati negativi in SERP.");
  } else if (ratio >= 0.1) {
    flags.add("Presenza significativa di risultati negativi visibili.");
  } else {
    flags.add("Segnali negativi presenti ma non predominanti.");
  }

  // dettaglio su score/risk
  if (risk == "HIGH") {
    flags.add("Narrativa negativa forte e potenzialmente impattante su banche e partner.");
  } else if (risk == "MEDIUM") {
    flags.add("Narrativa negativa non trascurabile, da monitorare con attenzione.");
  } else if (risk == "LOW") {
    flags.add("Impatto reputazionale moderato, con alcuni segnali da tenere sotto controllo.");
  } else {
    flags.add("Profilo complessivamente a rischio molto basso.");
  }

  return flags;
}

/// ---------------------------------------------------------------------------
/// SERVIZIO API TRUSTCHECK
/// ---------------------------------------------------------------------------
class ApiService {
  /// URL base del backend TrustCheck Turbo 2.1
  ///
  /// - In locale:  http://127.0.0.1:8000
  /// - In produzione (Render, ecc.): sostituire con l’URL pubblico HTTPS.
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// Esegue l’analisi reputazionale (unica modalità).
  static Future<TrustCheckResult> runTrustCheck(String query) async {
    final uri = Uri.parse('$baseUrl/analyze');

    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return TrustCheckResult.fromJson(data);
    } else {
      throw Exception(
        'Errore backend ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}',
      );
    }
  }

  /// Alias per compatibilità con la UI:
  /// la schermata chiama ancora ApiService.analyzeReputation(query)
  static Future<TrustCheckResult> analyzeReputation(String query) {
    return runTrustCheck(query);
  }
}
