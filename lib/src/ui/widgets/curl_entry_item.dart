import 'package:flutter/material.dart';
import 'package:type_caster/type_caster.dart';

import '../../core/constants.dart';
import '../../core/helpers/ui_helper.dart';
import '../../core/interfaces/color_palette.dart';
import '../../data/models/cached_curl_entry.dart';
import '../curl_viewer.dart';

class CurlEntryItem extends StatelessWidget {
  final CachedCurlEntry entry;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  const CurlEntryItem({
    super.key,
    required this.entry,
    this.onCopy,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: _buildDecoration(context),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            dense: true,
            showTrailingIcon: false,
            tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            iconColor: UiHelper.getStatusColor(entry.statusCode ?? 200),
            collapsedIconColor:
                UiHelper.getStatusColorPalette(entry.statusCode ?? 200)
                    .secondary,
            title: _buildTitle(context),
            subtitle: _buildSubtitle(context),
            children: _buildChildren(context),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(BuildContext context) {
    final colors = CurlViewerColors.theme;
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [colors.surface, colors.surfaceContainer],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: UiHelper.getStatusColorPalette(entry.statusCode ?? 200).border,
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: UiHelper.getStatusColorPalette(entry.statusCode ?? 200).shadow,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: colors.shadowLight,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
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
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
        _buildActionButtons(),
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
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.copy,
          color: UiHelper.getMethodColor('GET'),
          onPressed: onCopy,
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          icon: Icons.share,
          color: UiHelper.getStatusColor(200),
          onPressed: onShare,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final colors = CurlViewerColors.theme;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        entry.url ?? kNA,
        style: TextStyle(
          fontSize: 12,
          color: colors.onSurfaceSecondary,
        ),
      ),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    return [
      _buildCurlSection(),
      if (entry.responseHeaders != null && entry.responseHeaders!.isNotEmpty)
        _buildResponseHeadersSection(),
      _buildResponseBodySection(),
    ];
  }

  Widget _buildCurlSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(thickness: 1, height: 1)),
            const Text('cURL', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.copy,
                  size: 16, color: UiHelper.getMethodColor('GET')),
              onPressed: onCopy,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
            Expanded(child: Divider(thickness: 1, height: 1)),
          ],
        ),
        const SizedBox(height: 4),
        SelectableText(entry.curlCommand, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildResponseHeadersSection() {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      dense: true,
      title: const Text('Response Headers:',
          style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SelectableText(
            stringify(entry.responseHeaders, indent: '  '),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseBodySection() {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      dense: true,
      title: const Text('Response Body:',
          style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SelectableText(
            entry.responseBody ?? '<no body>',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime, {bool includeTime = false}) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    if (includeTime) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final second = dateTime.second.toString().padLeft(2, '0');
      return '$year-$month-$day $hour:$minute:$second';
    }
    return '$year-$month-$day';
  }
}
