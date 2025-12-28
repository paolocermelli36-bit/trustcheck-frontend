import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();

  bool _loading = false;
  Map<String, dynamic>? _response;

  Future<void> _analyze() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _response = null;
    });

    final uri = Uri.parse('http://127.0.0.1:8000/analyze');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query}),
    );

    setState(() {
      _loading = false;
      _response = jsonDecode(res.body);
    });
  }

  Widget _buildBanner() {
    if (_response == null) return const SizedBox.shrink();

    final bool riskSignal = _response!['risk_signal'] == true;
    final int neg = _response!['negative_results'] ?? 0;
    final int tot = _response!['total_results'] ?? 0;

    final Color bg = riskSignal ? Colors.red.shade50 : Colors.green.shade50;
    final Color border = riskSignal ? Colors.red : Colors.green;
    final IconData icon = riskSignal ? Icons.warning_amber : Icons.check_circle;

    final String title = riskSignal
        ? 'RISK SIGNAL DETECTED'
        : 'NO RISK SIGNAL DETECTED';

    final String explanation = riskSignal
        ? 'TrustCheck is not Google.\n\n'
          'It highlights replicable adverse signals within the first $tot Google results '
          'that may trigger automated compliance, onboarding delays, or enhanced due diligence.\n\n'
          '$neg authoritative/adverse sources were identified.'
        : 'No authoritative or adverse signals were identified within the first $tot Google results.\n\n'
          'This does not prove absence of risk, but indicates no immediate automated risk triggers.';

    final String whyBetter =
        'Why TrustCheck instead of Google:\n'
        '• scans up to 100 results automatically\n'
        '• removes noise and duplication\n'
        '• highlights only compliance-relevant signals\n'
        '• provides a repeatable, defensible pre-screening output';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: border),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: border,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(explanation),
          const SizedBox(height: 10),
          Text(
            whyBetter,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_response == null) return const SizedBox.shrink();

    final List results = _response!['results'] ?? [];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final r = results[index];
        final bool neg = r['is_negative'] == true;

        return ListTile(
          title: Text(
            r['title'] ?? '',
            style: TextStyle(
              color: neg ? Colors.red : Colors.black,
              fontWeight: neg ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(r['snippet'] ?? ''),
          trailing: neg
              ? const Icon(Icons.error, color: Colors.red)
              : const SizedBox.shrink(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TrustCheck')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Search name or company',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _analyze(),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loading ? null : _analyze,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Analyze'),
              ),
              _buildBanner(),
              _buildResults(),
            ],
          ),
        ),
      ),
    );
  }
}