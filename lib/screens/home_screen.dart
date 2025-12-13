import 'package:flutter/material.dart';
import 'package:microbo_reputation_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TrustCheckFormScreen extends StatefulWidget {
  const TrustCheckFormScreen({super.key});

  @override
  State<TrustCheckFormScreen> createState() => _TrustCheckFormScreenState();
}

class _TrustCheckFormScreenState extends State<TrustCheckFormScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() => _errorMessage = 'Please enter an individual or company name.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.analyzeReputation(query);
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrustCheckResultScreen(result: result),
        ),
      );
    } catch (_) {
      setState(() => _errorMessage = 'The analysis could not be completed. Please try again later.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        title: const Text('TrustCheck'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Online Reputation Exposure Audit',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Outside-in visibility of adverse online references.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _controller,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Individual or Company Name',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _runAnalysis(),
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _controller.text.trim().isEmpty || _isLoading
                            ? null
                            : _runAnalysis,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : const Text(
                                'RUN EXPOSURE CHECK',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TrustCheck v2.1 – MicroboLabs – Paolo Alberto Cermelli © 2025',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// RESULT SCREEN + MICROBO MODE (NO global scoring)
/// ---------------------------------------------------------------------------

class TrustCheckResultScreen extends StatefulWidget {
  final TrustCheckResult result;

  const TrustCheckResultScreen({super.key, required this.result});

  @override
  State<TrustCheckResultScreen> createState() => _TrustCheckResultScreenState();
}

class _TrustCheckResultScreenState extends State<TrustCheckResultScreen> {
  int _microboTapCount = 0;
  bool _microboUnlocked = false;

  void _onTitleTap() {
    setState(() {
      _microboTapCount++;
      if (_microboTapCount >= 7) _microboUnlocked = true;
    });

    if (_microboTapCount == 7) {
      _showMicroboDialog();
    }
  }

  Future<void> _showMicroboDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'MICROBO MODE',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/microbo.png',
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Microbo has reviewed the exposure.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLink(String url) async {
    final raw = url.trim();
    if (raw.isEmpty) return;

    Uri uri;
    try {
      uri = Uri.parse(raw);
      if (!uri.hasScheme) uri = Uri.parse('https://$raw');
    } catch (_) {
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final theme = Theme.of(context);

    final total = result.totalResults;
    final adverse = result.negativeResults;
    final elapsed = result.elapsedMs;

    // Adverse first, then by position
    final sortedResults = [...result.results]
      ..sort((a, b) {
        if (a.isNegative != b.isNegative) {
          // true first
          return a.isNegative ? -1 : 1;
        }
        return a.position.compareTo(b.position);
      });

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _onTitleTap,
          child: const Text('TrustCheck'),
        ),
      ),
      floatingActionButton: _microboUnlocked
          ? FloatingActionButton(
              backgroundColor: Colors.pinkAccent,
              onPressed: _showMicroboDialog,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset('assets/microbo.png', fit: BoxFit.cover),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  result.query,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$adverse adverse references out of $total analyzed${elapsed > 0 ? ' • ${elapsed} ms' : ''}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),

                if (sortedResults.isEmpty)
                  Text(
                    'No adverse references detected in the analyzed results.',
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  Column(
                    children: sortedResults
                        .map(
                          (r) => _ResultCard(
                            item: r,
                            onOpen: () => _openLink(r.link),
                          ),
                        )
                        .toList(),
                  ),

                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.search),
                    label: const Text('Start new audit'),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  'TrustCheck v2.1 – MicroboLabs – Paolo Alberto Cermelli © 2025',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// RESULT CARD (clickable) + chips
/// ---------------------------------------------------------------------------

class _ResultCard extends StatelessWidget {
  final SearchResultItem item;
  final VoidCallback onOpen;

  const _ResultCard({
    super.key,
    required this.item,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: item.isNegative ? Colors.red.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blueGrey.shade50,
                child: Text(
                  item.position.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.link,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (item.source.isNotEmpty)
                          Chip(
                            label: Text(item.source),
                            backgroundColor: Colors.grey.shade200,
                          ),
                        if (item.isNegative)
                          Chip(
                            label: const Text('ADVERSE'),
                            backgroundColor: Colors.red.shade100,
                          ),
                        if (item.isAuthorityOrRegulator)
                          Chip(
                            label: const Text('Authority / Regulator'),
                            backgroundColor: Colors.orange.shade100,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
