import 'package:flutter/material.dart';
import '../../core/helpers/ui_helper.dart';
import '../../core/types.dart';
import '../curl_viewer.dart';

class StatusSummary extends StatelessWidget {
  final Map<ResponseStatus, int> statusCounts;
  final String? selectedStatusChip;
  final Function(String) onStatusChipTapped;

  const StatusSummary({
    super.key,
    required this.statusCounts,
    required this.selectedStatusChip,
    required this.onStatusChipTapped,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Row(
          key: ValueKey(_getCountKey()),
          children: _buildStatusChips(),
        ),
      ),
    );
  }

  String _getCountKey() {
    final informational = statusCounts[ResponseStatus.informational] ?? 0;
    final done = statusCounts[ResponseStatus.success] ?? 0;
    final fail = (statusCounts[ResponseStatus.clientError] ?? 0) + 
                 (statusCounts[ResponseStatus.serverError] ?? 0);
    final redirection = statusCounts[ResponseStatus.redirection] ?? 0;
    return '$informational-$done-$fail-$redirection';
  }

  List<Widget> _buildStatusChips() {
    final chips = <Widget>[];
    
    final informational = statusCounts[ResponseStatus.informational] ?? 0;
    final done = statusCounts[ResponseStatus.success] ?? 0;
    final fail = (statusCounts[ResponseStatus.clientError] ?? 0) + 
                 (statusCounts[ResponseStatus.serverError] ?? 0);
    final redirection = statusCounts[ResponseStatus.redirection] ?? 0;

    if (informational > 0) {
      chips.addAll([
        _buildStatusChip(
          '${UiHelper.getStatusEmoji(100)} $informational',
          UiHelper.getStatusColor(100),
          'informational',
        ),
        const SizedBox(width: 8),
      ]);
    }

    chips.addAll([
      _buildStatusChip(
        '${UiHelper.getStatusEmoji(200)} $done',
        UiHelper.getStatusColor(200),
        'success',
      ),
      const SizedBox(width: 8),
      _buildStatusChip(
        '${UiHelper.getStatusEmoji(400)} $fail',
        UiHelper.getStatusColor(400),
        'error',
      ),
    ]);

    if (redirection > 0) {
      chips.addAll([
        const SizedBox(width: 8),
        _buildStatusChip(
          '${UiHelper.getStatusEmoji(300)} $redirection',
          UiHelper.getStatusColor(300),
          'redirection',
        ),
      ]);
    }

    return chips;
  }

  Widget _buildStatusChip(String text, Color color, String statusType) {
    final isSelected = selectedStatusChip == statusType;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onStatusChipTapped(statusType),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: CurlViewerStyle.padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelected
                  ? [color.withValues(alpha: 0.2), color.withValues(alpha: 0.15)]
                  : [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(CurlViewerStyle.borderRadius),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.5)
                  : color.withValues(alpha: 0.3),
              width: isSelected ? 2.0 : CurlViewerStyle.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isSelected ? 0.2 : 0.1),
                blurRadius: isSelected ? 6 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: CurlViewerStyle.fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
