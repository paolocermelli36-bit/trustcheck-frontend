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
      setState(() {
        // Forza il rebuild per aggiornare lo stato del bottone
      });
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
      setState(() {
        _errorMessage = 'Inserisci un nome o un\'azienda.';
      });
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
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore durante l\'analisi. Riprova più tardi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                      'Web Reputation Scanner',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Analisi reputazionale in tempo reale.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _controller,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Nome / Azienda',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _runAnalysis(),
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            _controller.text.trim().isEmpty || _isLoading
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'ANALIZZA ORA',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TrustCheck v1.0 – MicroboLabs – Paolo Alberto Cermelli © 2025',
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
/// SCHERMATA RISULTATO + MICROBO MODE
/// ---------------------------------------------------------------------------

class TrustCheckResultScreen extends StatefulWidget {
  final TrustCheckResult result;

  const TrustCheckResultScreen({super.key, required this.result});

  @override
  State<TrustCheckResultScreen> createState() =>
      _TrustCheckResultScreenState();
}

class _TrustCheckResultScreenState extends State<TrustCheckResultScreen> {
  int _microboTapCount = 0;
  bool _microboUnlocked = false;

  Color _riskColor(TrustCheckResult result) {
    switch (result.risk.toUpperCase()) {
      case 'HIGH':
        return Colors.red.shade600;
      case 'MEDIUM':
        return Colors.orange.shade600;
      case 'LOW':
        return Colors.amber.shade700;
      default:
        return Colors.green.shade600;
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  void _onTitleTap() {
    setState(() {
      _microboTapCount++;
      if (_microboTapCount >= 7) {
        _microboUnlocked = true;
      }
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
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
                  '🦠 Il Microbo ti osserva e approva.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Chiudi'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final theme = Theme.of(context);
    final riskColor = _riskColor(result);

    final total = result.totalResults;
    final negs = result.negativeResults;
    final elapsed = result.elapsedMs;

    final negatives = result.negatives;
    final allResults = result.results;

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
                child: Image.asset(
                  'assets/microbo.png',
                  fit: BoxFit.cover,
                ),
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
                const SizedBox(height: 4),
                Text(
                  'Online reputation snapshot',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                // Card livello rischio
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield_rounded,
                              size: 32,
                              color: riskColor,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    result.risk,
                                    style:
                                        theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: riskColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$negs risultati negativi su $total risultati analizzati. ($elapsed ms)',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 120,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${result.score} / 100',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: (result.score / 100)
                                          .clamp(0.0, 1.0),
                                      minHeight: 6,
                                      backgroundColor: Colors.grey[300],
                                      valueColor:
                                          AlwaysStoppedAnimation(riskColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All links below are ready to open. Risk level is approximate – please review the sources and make your own evaluation.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Categorie
                if (result.categories.isNotEmpty) ...[
                  Text(
                    'Categorie rilevanti',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.categories
                        .map(
                          (c) => Chip(
                            label: Text(c),
                            backgroundColor: Colors.indigo.shade50,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Key signals
                if (result.flags.isNotEmpty) ...[
                  Text(
                    'Key signals',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.flags
                        .map(
                          (f) => Chip(
                            label: Text(f),
                            backgroundColor: Colors.grey[200],
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Summary
                Text(
                  'Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.summary,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                // Top negative links (max 3)
                if (negatives.isNotEmpty) ...[
                  Text(
                    'Top negative links',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: negatives
                        .take(3)
                        .map(
                          (n) => _NegativeCard(
                            title: n.title,
                            snippet: n.snippet,
                            link: n.link,
                            source: n.source,
                            position: n.position,
                            severity: n.severity,
                            isAuthority: n.isAuthorityOrRegulator,
                            onOpen: () => _openLink(n.link),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 32),
                ],

                // Tutti i risultati (max 100)
                if (allResults.isNotEmpty) ...[
                  Text(
                    'Tutti i risultati (max 100)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: allResults
                        .map(
                          (r) => _ResultCard(
                            item: r,
                            onOpen: () => _openLink(r.link),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 32),
                ],

                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.search),
                    label: const Text('Nuova analisi'),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  'TrustCheck v1.0 – MicroboLabs – Paolo Alberto Cermelli © 2025',
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
/// CARD TOP NEGATIVE
/// ---------------------------------------------------------------------------

class _NegativeCard extends StatelessWidget {
  final String title;
  final String snippet;
  final String link;
  final String source;
  final int position;
  final String severity;
  final bool isAuthority;
  final VoidCallback onOpen;

  const _NegativeCard({
    required this.title,
    required this.snippet,
    required this.link,
    required this.source,
    required this.position,
    required this.severity,
    required this.isAuthority,
    required this.onOpen,
  });

  Color _severityColor() {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red.shade50;
      case 'medium':
        return Colors.orange.shade50;
      case 'low':
        return Colors.yellow.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: _severityColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blueGrey.shade50,
                child: Text(
                  position.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snippet,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      link,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (source.isNotEmpty)
                          Chip(
                            label: Text(source),
                            backgroundColor: Colors.grey.shade200,
                          ),
                        Chip(
                          label: Text('Severity: $severity'),
                          backgroundColor: Colors.grey.shade200,
                        ),
                        if (isAuthority)
                          Chip(
                            label: const Text('Authority / Regulator'),
                            backgroundColor: Colors.red.shade100,
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

/// ---------------------------------------------------------------------------
/// CARD TUTTI I RISULTATI
/// ---------------------------------------------------------------------------

class _ResultCard extends StatelessWidget {
  final SearchResultItem item;
  final VoidCallback onOpen;

  const _ResultCard({
    required this.item,
    required this.onOpen,
  });

  Color _bgColor() {
    if (!item.isNegative) {
      return Colors.white;
    }
    switch (item.severity.toLowerCase()) {
      case 'high':
        return Colors.red.shade50;
      case 'medium':
        return Colors.orange.shade50;
      case 'low':
        return Colors.yellow.shade50;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: _bgColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
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
                        color: Colors.blue.shade700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                            label: Text('Negative – ${item.severity}'),
                            backgroundColor: Colors.grey.shade200,
                          ),
                        if (item.isAuthorityOrRegulator)
                          Chip(
                            label: const Text('Authority / Regulator'),
                            backgroundColor: Colors.red.shade100,
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
