import 'package:http/http.dart' as http;
import 'dart:convert';

// URL del backend locale (FastAPI)
const backendBaseUrl = "https://trustcheck-api.onrender.com";

// Funzione che manda il nome/azienda al backend
Future<Map<String, dynamic>> analyzeReputation(String query) async {
  final url = Uri.parse('$backendBaseUrl/analyze');

  final body = jsonEncode({
    "query": query,
    "max_results": 5,
  });

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: body,
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Errore dal backend: ${response.body}");
  }
}
