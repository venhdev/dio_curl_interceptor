import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/helpers/ui_helper.dart';
import '../../data/models/cached_curl_entry.dart';

class CurlEntryItem extends StatefulWidget {
  const CurlEntryItem({
    super.key,
    required this.entry,
    required this.onOpen,
    this.onCopy,
    this.onShare,
  });

  final CachedCurlEntry entry;
  final VoidCallback onOpen;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  @override
  State<CurlEntryItem> createState() => _CurlEntryItemState();
}

class _CurlEntryItemState extends State<CurlEntryItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final scheme = Theme.of(context).colorScheme;
    final statusColor = UiHelper.getStatusColor(entry.statusCode ?? 0);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.onOpen,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _label('${entry.statusCode ?? kNA}', statusColor),
                            _label(entry.method ?? kNA, scheme.primary),
                            if (entry.duration != null)
                              _label('${entry.duration} ms', scheme.secondary),
                            Text(
                              entry.timestamp.toLocal().toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.url ?? kNA,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: _expanded ? 'Hide actions' : 'Show actions',
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ),
            ],
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: widget.onCopy,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy cURL'),
                  ),
                  TextButton.icon(
                    onPressed: widget.onShare,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      );
}
