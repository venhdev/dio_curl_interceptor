import 'package:flutter/material.dart';
import 'package:type_caster/type_caster.dart';

import '../../data/models/cached_curl_entry.dart';

class CurlEntryDetailPage extends StatelessWidget {
  final CachedCurlEntry entry;
  final VoidCallback onBack;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const CurlEntryDetailPage({
    super.key,
    required this.entry,
    required this.onBack,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to logs',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Request details'),
        actions: [
          IconButton(
            tooltip: 'Copy cURL',
            onPressed: onCopy,
            icon: const Icon(Icons.copy),
          ),
          IconButton(
            tooltip: 'Share cURL',
            onPressed: onShare,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailSection(
            title: 'Request',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailValue(label: 'URL', value: entry.url),
                _DetailValue(label: 'Method', value: entry.method),
                _DetailValue(label: 'cURL', value: entry.curlCommand),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DetailSection(
            title: 'Response',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailValue(
                  label: 'Status',
                  value: entry.statusCode?.toString(),
                ),
                _DetailValue(
                  label: 'Duration',
                  value: entry.duration == null ? null : '${entry.duration} ms',
                ),
                _DetailValue(
                  label: 'Timestamp',
                  value: entry.timestamp.toLocal().toString(),
                ),
                _DetailValue(
                  label: 'Headers',
                  value: entry.responseHeaders == null
                      ? null
                      : stringify(entry.responseHeaders, indent: '  '),
                ),
                _DetailValue(label: 'Body', value: entry.responseBody),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy),
            label: const Text('Copy cURL'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailValue extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = value?.isNotEmpty == true ? value! : '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          SelectableText(text),
        ],
      ),
    );
  }
}
