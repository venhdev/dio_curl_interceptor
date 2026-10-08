/// Individual log entry card widget for the cURL viewer list.
library;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/helpers/ui_helper.dart';
import '../../core/interfaces/color_palette.dart';
import '../../data/models/cached_curl_entry.dart';
import '../curl_detail_viewer.dart';
import '../curl_viewer.dart';
import 'icon_styles.dart';

/// Clean, high-performance summary card for a [CachedCurlEntry] in the cURL log list.
class CurlEntryItem extends StatelessWidget {
  final CachedCurlEntry entry;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onTap;

  const CurlEntryItem({
    super.key,
    required this.entry,
    this.onCopy,
    this.onShare,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: _buildDecoration(context),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap ?? () => CurlDetailViewer.show(context, entry),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 6),
                  _buildUrl(context),
                  const SizedBox(height: 6),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(BuildContext context) {
    final colors = CurlViewerColors.theme;
    final statusCode = entry.statusCode ?? 200;
    final statusPalette = UiHelper.getStatusColorPalette(statusCode);

    return BoxDecoration(
      gradient: LinearGradient(
        colors: [colors.surface, colors.surfaceContainer],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: statusPalette.border,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: statusPalette.shadow,
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: colors.shadowLight,
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip(),
                const SizedBox(width: 4),
                _buildMethodChip(),
                const SizedBox(width: 4),
                _buildDurationChip(),
                const SizedBox(width: 4),
                _buildTimestampChip(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildStatusChip() {
    return _buildInfoChip(
      '${entry.statusCode ?? kNA}',
      UiHelper.getStatusColorPalette(entry.statusCode ?? 200),
    );
  }

  Widget _buildMethodChip() {
    return _buildInfoChip(
      entry.method ?? kNA,
      UiHelper.getMethodColorPalette(entry.method ?? 'GET'),
    );
  }

  Widget _buildDurationChip() {
    return _buildInfoChip(
      '${UiHelper.getDurationEmoji(entry.duration)} ${entry.duration ?? kNA} ms',
      UiHelper.getDurationColorPalette(entry.duration),
    );
  }

  Widget _buildTimestampChip() {
    return _buildInfoChip(
      _formatDateTime(entry.timestamp.toLocal(), includeTime: true),
      CurlViewerColors.neutral,
    );
  }

  Widget _buildInfoChip(String text, ColorPalette colorPalette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorPalette.light, colorPalette.lighter],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorPalette.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorPalette.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colorPalette.dark,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.copy,
          color: UiHelper.getMethodColor('GET'),
          onPressed: onCopy,
          tooltip: 'Copy cURL',
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          icon: Icons.share,
          color: UiHelper.getStatusColor(200),
          onPressed: onShare,
          tooltip: 'Share cURL',
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          icon: Icons.open_in_new,
          color: Theme.of(context).colorScheme.primary,
          onPressed: onTap ?? () => CurlDetailViewer.show(context, entry),
          tooltip: 'Inspect detail',
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(ActionIconStyle.radiusSM),
      child: Container(
        padding: ActionIconStyle.paddingSM,
        decoration: ActionIconStyle.actionButtonDecoration(color),
        child: Icon(icon, size: ActionIconStyle.sizeSM, color: color),
      ),
    );
  }

  Widget _buildUrl(BuildContext context) {
    final colors = CurlViewerColors.theme;
    return Text(
      entry.url ?? kNA,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: colors.onSurface,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colors = CurlViewerColors.theme;
    final hasBody =
        entry.responseBody != null && entry.responseBody!.isNotEmpty;

    return Row(
      children: [
        if (hasBody) ...[
          Icon(Icons.data_object, size: 13, color: colors.onSurfaceSecondary),
          const SizedBox(width: 4),
          Text(
            'JSON Response',
            style: TextStyle(
                fontSize: 11,
                color: colors.onSurfaceSecondary,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 10),
        ],
        if (entry.responseHeaders != null &&
            entry.responseHeaders!.isNotEmpty) ...[
          Icon(Icons.view_list_outlined,
              size: 13, color: colors.onSurfaceSecondary),
          const SizedBox(width: 4),
          Text(
            '${entry.responseHeaders!.length} Headers',
            style: TextStyle(
                fontSize: 11,
                color: colors.onSurfaceSecondary,
                fontWeight: FontWeight.w500),
          ),
        ],
        const Spacer(),
        Text(
          'Inspect',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Icon(
          Icons.chevron_right,
          size: 14,
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime, {bool includeTime = false}) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    if (includeTime) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final second = dateTime.second.toString().padLeft(2, '0');
      return '$day-$month $hour:$minute:$second';
    }
    return '$day-$month';
  }
}
