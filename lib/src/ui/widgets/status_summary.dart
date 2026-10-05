import 'package:flutter/material.dart';

import '../../core/types.dart';

class StatusSummary extends StatelessWidget {
  const StatusSummary({
    super.key,
    required this.statusCounts,
    required this.selectedStatusChip,
    required this.onStatusChipTapped,
  });

  final Map<ResponseStatus, int> statusCounts;
  final String? selectedStatusChip;
  final ValueChanged<String> onStatusChipTapped;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final options = <_StatusOption>[
      _StatusOption(
        'informational',
        '1xx',
        statusCounts[ResponseStatus.informational] ?? 0,
      ),
      _StatusOption(
        'success',
        '2xx',
        statusCounts[ResponseStatus.success] ?? 0,
      ),
      _StatusOption(
        'redirection',
        '3xx',
        statusCounts[ResponseStatus.redirection] ?? 0,
      ),
      _StatusOption(
        'clientError',
        '4xx',
        statusCounts[ResponseStatus.clientError] ?? 0,
      ),
      _StatusOption(
        'serverError',
        '5xx',
        statusCounts[ResponseStatus.serverError] ?? 0,
      ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('${option.label} · ${option.count}'),
                selected: selectedStatusChip == option.key,
                onSelected: (_) => onStatusChipTapped(option.key),
                selectedColor: colors.primaryContainer,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusOption {
  const _StatusOption(this.key, this.label, this.count);

  final String key;
  final String label;
  final int count;
}
