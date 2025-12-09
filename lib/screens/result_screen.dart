import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TrustCheckResultScreen extends StatelessWidget {
  final TrustCheckResult result;

  const TrustCheckResultScreen({super.key, required this.result});

  Color _riskColor() {
    switch (result.riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = _riskColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TrustCheck result'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // titolo query
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

                // card rischio
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 32,
                          color: riskColor,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.riskLevel,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: riskColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${result.negativeLinks} negative links detected in Google\'s first pages.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${result.elapsedMs} ms',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // key signals
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

                // summary
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

                const SizedBox(height: 32),

                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Nuova analisi'),
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