import 'dart:convert';
import 'package:http/http.dart' as http;

/// TrustCheck v3 — API client + data models
///
/// Goals:
/// - Parse backend v3 output safely.
/// - Expose risk fields explicitly:
///   - riskLevel (high|medium|none)
///   - riskType (authority|judicial|adverse_media|null)
///   - riskAuthority (AGCM/SEC/...|null)
///   - riskReason (string|null)
///   - riskMatched (list)
///
/// No scoring, no counting logic beyond "signals shown".

class ApiService {
  // Keep ONE backend URL here.
  static const String baseUrl = "http://127.0.0.1:8000";

  static Future<TrustCheckResult> analyzeReputation(String query) async {
    final url = Uri.parse("$baseUrl/analyze");
    final body = jsonEncode({"query": query});

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception("Backend error: ${response.body}");
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return TrustCheckResult.fromJson(data);
  }
}

/// ---------------------------
/// DATA MODELS
/// ---------------------------

class TrustCheckResult {
  final String query;
  final int totalResults;     // v3: shown signals only
  final int negativeResults;  // v3: same as totalResults (signals)
  final int elapsedMs;
  final List<SearchResultItem> results;

  TrustCheckResult({
    required this.query,
    required this.totalResults,
    required this.negativeResults,
    required this.elapsedMs,
    required this.results,
  });

  factory TrustCheckResult.fromJson(Map<String, dynamic> json) {
    final q = _asString(json["query"]);
    final elapsed = _asInt(json["elapsed_ms"], fallback: 0);

    final rawResults = (json["results"] is List) ? (json["results"] as List) : const [];
    final parsed = rawResults
        .whereType<Map>()
        .map((m) => SearchResultItem.fromJson(m.cast<String, dynamic>()))
        .toList();

    final total = _asInt(json["total_results"], fallback: parsed.length);
    final negatives = _asInt(json["negative_results"], fallback: parsed.where((r) => r.isNegative).length);

    return TrustCheckResult(
      query: q,
      totalResults: total,
      negativeResults: negatives,
      elapsedMs: elapsed,
      results: parsed,
    );
  }
}

class RiskInfo {
  final String riskLevel;      // high|medium|none
  final String? riskType;      // authority|judicial|adverse_media|null
  final String? authority;     // AGCM/SEC/...|null
  final String? reason;        // 1 short sentence
  final List<String> matched;  // keywords matched

  RiskInfo({
    required this.riskLevel,
    required this.riskType,
    required this.authority,
    required this.reason,
    required this.matched,
  });

  factory RiskInfo.none() {
    return RiskInfo(
      riskLevel: "none",
      riskType: null,
      authority: null,
      reason: null,
      matched: const [],
    );
  }

  factory RiskInfo.fromJson(dynamic v) {
    if (v == null || v is! Map) return RiskInfo.none();
    final m = v.cast<String, dynamic>();

    final rl = _asString(m["risk_level"]).toLowerCase();
    final rt = _asString(m["risk_type"]).toLowerCase();
    final auth = _asString(m["authority"]);
    final reason = _asString(m["reason"]);

    final rawMatched = (m["matched"] is List) ? (m["matched"] as List) : const [];
    final matched = rawMatched.map((x) => _asString(x)).where((s) => s.isNotEmpty).toList();

    return RiskInfo(
      riskLevel: (rl.isEmpty ? "none" : rl),
      riskType: rt.isEmpty ? null : rt,
      authority: auth.isEmpty ? null : auth,
      reason: reason.isEmpty ? null : reason,
      matched: matched,
    );
  }

  bool get isHigh => riskLevel == "high";
  bool get isMedium => riskLevel == "medium";
  bool get isNone => riskLevel == "none";
}

class SearchResultItem {
  final String title;
  final String snippet;
  final String link;
  final String source;
  final int position;

  /// v3: isNegative == true means this item is a SIGNAL (HIGH or MEDIUM)
  final bool isNegative;

  /// v3: "high" | "medium" | "none"
  final String severity;

  /// v3: HIGH-only (authority or judicial)
  final bool isAuthorityOrRegulator;

  /// v3: explicit risk payload (preferred, not inferred)
  final RiskInfo risk;

  SearchResultItem({
    required this.title,
    required this.snippet,
    required this.link,
    required this.source,
    required this.position,
    required this.isNegative,
    required this.severity,
    required this.isAuthorityOrRegulator,
    required this.risk,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    final title = _asString(json["title"]);
    final snippet = _asString(json["snippet"]);
    final link = _asString(json["link"]);
    final source = _asString(json["source"]);
    final position = _asInt(json["position"], fallback: 0);

    // Direct fields (backend sends them)
    final isNegDirect = _asBool(json["is_negative"], fallback: false);
    final sevDirect = _asString(json["severity"]).toLowerCase();
    final authDirect = _asBool(json["is_authority_or_regulator"], fallback: false);

    // Nested v3 risk dict
    final risk = RiskInfo.fromJson(json["risk"]);

    // Determine final flags with safe fallbacks
    bool isNegative = isNegDirect;
    String severity = sevDirect.isNotEmpty ? sevDirect : "";
    bool isAuthority = authDirect;

    if (!risk.isNone) {
      isNegative = true;
      if (risk.isHigh) {
        severity = "high";
        // HIGH can be authority or judicial
        isAuthority = (risk.riskType == "authority" || risk.riskType == "judicial" || risk.riskType == null);
      } else if (risk.isMedium) {
        severity = "medium";
        isAuthority = false;
      }
    }

    if (severity.isEmpty) {
      severity = isNegative ? (isAuthority ? "high" : "medium") : "none";
    }

    return SearchResultItem(
      title: title,
      snippet: snippet,
      link: link,
      source: source,
      position: position,
      isNegative: isNegative,
      severity: severity,
      isAuthorityOrRegulator: isAuthority,
      risk: risk,
    );
  }
}

/// ---------------------------
/// SAFE CAST HELPERS
/// ---------------------------

String _asString(dynamic v) {
  if (v == null) return "";
  if (v is String) return v;
  return v.toString();
}

int _asInt(dynamic v, {required int fallback}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) {
    final x = int.tryParse(v.trim());
    return x ?? fallback;
  }
  return fallback;
}

bool _asBool(dynamic v, {required bool fallback}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) {
    final s = v.trim().toLowerCase();
    if (s == "true" || s == "1" || s == "yes") return true;
    if (s == "false" || s == "0" || s == "no") return false;
  }
  return fallback;
}