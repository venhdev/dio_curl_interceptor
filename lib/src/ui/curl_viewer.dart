import 'dart:async';

// import 'package:codekit/codekit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:type_caster/type_caster.dart';

import '../core/constants.dart';
import '../core/helpers.dart';
import '../data/curl_response_cache.dart';

/// Reusable color palette for CurlViewer component
///
/// This class provides a centralized way to manage all colors used in the CurlViewer.
/// Colors are organized by semantic meaning to make them easy to understand and maintain.
class CurlViewerColors {
  // Private constructor to prevent instantiation
  CurlViewerColors._();

  // ============================================================================
  // FUNCTIONAL COLORS - UI elements and interactions
  // ============================================================================

  /// Interactive elements (buttons, links, search)
  static const interactive = _InteractiveColors();

  /// Neutral elements (metadata, timestamps, close buttons)
  static const neutral = _NeutralColors();

  /// Warning elements (confirmation dialogs, alerts)
  static const warning = _WarningColors();

  // ============================================================================
  // THEME-AWARE COLORS - Adapt to light/dark themes
  // ============================================================================

  /// Get theme-aware colors for the given context
  static CurlViewerThemeColors theme(BuildContext context) =>
      CurlViewerThemeColors(context);
}

/// Interactive elements colors (blue palette)
class _InteractiveColors {
  const _InteractiveColors();

  Color get primary => Colors.blue[600]!;
  Color get secondary => Colors.blue[400]!;
  Color get light => Colors.blue[100]!;
  Color get lighter => Colors.blue[50]!;
  Color get dark => Colors.blue[800]!;
  Color get background => Colors.blue[50]!;
  Color get border => Colors.blue[200]!;
  Color get shadow => Colors.blue.withValues(alpha: 0.1);
  Color get shadowStrong => Colors.blue.withValues(alpha: 0.2);
}

/// Neutral elements colors (grey palette)
class _NeutralColors {
  const _NeutralColors();

  Color get primary => Colors.grey[600]!;
  Color get secondary => Colors.grey[400]!;
  Color get light => Colors.grey[100]!;
  Color get lighter => Colors.grey[50]!;
  Color get dark => Colors.grey[700]!;
  Color get background => Colors.grey[50]!;
  Color get border => Colors.grey[200]!;
  Color get shadow => Colors.grey.withValues(alpha: 0.1);
  Color get shadowStrong => Colors.grey.withValues(alpha: 0.2);
}

/// Warning elements colors (orange palette)
class _WarningColors {
  const _WarningColors();

  Color get primary => Colors.orange[600]!;
  Color get secondary => Colors.orange[400]!;
  Color get light => Colors.orange[100]!;
  Color get lighter => Colors.orange[50]!;
  Color get dark => Colors.orange[700]!;
  Color get background => Colors.orange[100]!;
  Color get border => Colors.orange[200]!;
  Color get shadow => Colors.orange.withValues(alpha: 0.1);
}

/// Theme-aware colors that adapt to light/dark themes
class CurlViewerThemeColors {
  final BuildContext _context;

  CurlViewerThemeColors(this._context);

  ColorScheme get _scheme => Theme.of(_context).colorScheme;

  // Background colors
  Color get surface => _scheme.surface;
  Color get surfaceContainer => _scheme.surfaceContainerHighest;

  // Text colors
  Color get onSurface => _scheme.onSurface;
  Color get onSurfaceVariant => _scheme.onSurfaceVariant;
  Color get onSurfaceSecondary => _scheme.onSurface.withValues(alpha: 0.7);
  Color get onSurfaceTertiary => _scheme.onSurface.withValues(alpha: 0.6);

  // Border and outline colors
  Color get outline => _scheme.outline;
  Color get outlineLight => _scheme.outline.withValues(alpha: 0.3);
  Color get outlineStrong => _scheme.outline.withValues(alpha: 0.5);

  // Shadow colors
  Color get shadow => _scheme.shadow;
  Color get shadowLight => _scheme.shadow.withValues(alpha: 0.05);
  Color get shadowMedium => _scheme.shadow.withValues(alpha: 0.1);
  Color get shadowStrong => _scheme.shadow.withValues(alpha: 0.3);

  // Primary theme colors
  Color get primary => _scheme.primary;
  Color get primaryContainer => _scheme.primaryContainer;
  Color get onPrimary => _scheme.onPrimary;
  Color get onPrimaryContainer => _scheme.onPrimaryContainer;
}

/// Display type for the CurlViewer
enum CurlViewerDisplayType {
  dialog,
  bottomSheet,
  fullScreen,
}

/// Shows the CurlViewer in different display modes
void showCurlViewer(
  BuildContext context, {
  CurlViewerDisplayType displayType = CurlViewerDisplayType.dialog,
}) async {
  switch (displayType) {
    case CurlViewerDisplayType.dialog:
      showDialog(
        context: context,
        builder: (_) => const CurlViewer(),
      );
      break;
    case CurlViewerDisplayType.bottomSheet:
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const CurlViewer(),
      );
      break;
    case CurlViewerDisplayType.fullScreen:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CurlViewer(),
        ),
      );
      break;
  }
}

class CurlViewer extends StatefulWidget {
  const CurlViewer({
    super.key,
    this.displayType = CurlViewerDisplayType.dialog,
  });

  final CurlViewerDisplayType displayType;

  @override
  State<CurlViewer> createState() => _CurlViewerState();
}

class _CurlViewerState extends State<CurlViewer> {
  static const int pageSize = 50;
  List<CachedCurlEntry> entries = [];
  int totalCount = 0;
  int loadedCount = 0;
  bool isLoading = false;
  bool isLoadingMore = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchTimer;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  HttpStatusGroup? _statusGroup;
  String? _selectedStatusChip;

  @override
  void initState() {
    super.initState();
    _loadEntries(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEntries({bool reset = false}) async {
    if (isLoading || isLoadingMore) return;

    if (reset) {
      setState(() => isLoading = true);
      entries = [];
      loadedCount = 0;
    } else {
      setState(() => isLoadingMore = true);
    }

    final newEntries = CachedCurlStorage.loadFiltered(
      search: _searchQuery,
      startDate: _startDate,
      endDate: _endDate,
      statusGroup: _statusGroup,
      offset: loadedCount,
      limit: pageSize,
    );

    final count = CachedCurlStorage.countFiltered(
      search: _searchQuery,
      startDate: _startDate,
      endDate: _endDate,
      statusGroup: _statusGroup,
    );
    setState(() {
      entries.addAll(newEntries);
      loadedCount = entries.length;
      totalCount = count;
      isLoading = false;
      isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (loadedCount < totalCount && !isLoadingMore) {
        _loadEntries();
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(seconds: 1), () {
      _searchQuery = value;
      _loadEntries(reset: true);
    });
  }

  void _performSearch() {
    _searchTimer?.cancel();
    _searchQuery = _searchController.text;
    _loadEntries(reset: true);
  }

  void _onStatusChanged(int? val) {
    if (val == null) {
      _statusGroup = null;
    } else if (val == 1) {
      _statusGroup = HttpStatusGroup.informational;
    } else if (val == 2) {
      _statusGroup = HttpStatusGroup.success;
    } else if (val == 3) {
      _statusGroup = HttpStatusGroup.redirection;
    } else if (val == 4) {
      _statusGroup = HttpStatusGroup.clientError;
    } else if (val == 5) {
      _statusGroup = HttpStatusGroup.serverError;
    }
    _loadEntries(reset: true);
  }

  void _onStatusChipTapped(String statusType) {
    setState(() {
      if (_selectedStatusChip == statusType) {
        // If already selected, deselect it
        _selectedStatusChip = null;
        _statusGroup = null;
      } else {
        // Select the new status chip
        _selectedStatusChip = statusType;
        switch (statusType) {
          case 'informational':
            _statusGroup = HttpStatusGroup.informational;
            break;
          case 'success':
            _statusGroup = HttpStatusGroup.success;
            break;
          case 'error':
            _statusGroup = HttpStatusGroup.clientError;
            break;
          case 'redirection':
            _statusGroup = HttpStatusGroup.redirection;
            break;
        }
      }
    });
    _loadEntries(reset: true);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _startDate = picked.start;
      _endDate = picked.end;
      _loadEntries(reset: true);
    }
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

  /// Shares the cURL command using the device's native sharing capabilities
  Future<void> _shareCurlCommand(CachedCurlEntry entry) async {
    try {
      final shareText = _buildShareableText(entry);
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'cURL Command - ${entry.method} ${entry.url}',
        ),
      );
    } catch (e) {
      // Log error if sharing fails
      print('Failed to share: $e');
    }
  }

  /// Builds a formatted, shareable text containing the cURL command and metadata
  String _buildShareableText(CachedCurlEntry entry) {
    final buffer = StringBuffer();

    // Add header with metadata
    buffer.writeln('=== cURL Command ===');
    buffer.writeln('Method: ${entry.method ?? kNA}');
    buffer.writeln('URL: ${entry.url ?? kNA}');
    buffer.writeln('Status: ${entry.statusCode ?? kNA}');
    buffer.writeln('Duration: ${entry.duration ?? kNA} ms');
    buffer.writeln(
        'Timestamp: ${_formatDateTime(entry.timestamp.toLocal(), includeTime: true)}');
    buffer.writeln();

    // Add the actual cURL command
    buffer.writeln('Command:');
    buffer.writeln(entry.curlCommand);

    return buffer.toString();
  }

  Widget _buildStatusChip(String text, Color color,
      {VoidCallback? onTap, bool isSelected = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelected
                  ? [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.15),
                    ]
                  : [
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.05),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.5)
                  : color.withValues(alpha: 0.3),
              width: isSelected ? 2.0 : 1.5,
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final colors = CurlViewerColors.theme(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.3, 0.7, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.9),
                Colors.black.withValues(alpha: 0.7),
                Colors.grey.shade800.withValues(alpha: 0.6),
                Colors.grey.shade900.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              top: widget.displayType == CurlViewerDisplayType.dialog
                  ? const Radius.circular(20)
                  : Radius.zero,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.grey.shade700.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 3,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.terminal, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  'Cached cURL Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0.15),
                        Colors.grey.shade300.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Text(
                    '$totalCount entries',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            automaticallyImplyLeading:
                widget.displayType == CurlViewerDisplayType.fullScreen,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced search bar with modern styling
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.surface,
                      colors.surfaceContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.outlineLight, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadowLight,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by status, cURL, response, URL...',
                    hintStyle: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceTertiary,
                        fontWeight: FontWeight.w400),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: UiHelper.getMethodColorPalette('GET').background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.search,
                          color: UiHelper.getMethodColor('GET'), size: 18),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  UiHelper.getStatusColorPalette(400).lighter,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.clear,
                                  color: UiHelper.getStatusColor(400),
                                  size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch();
                              },
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => _performSearch(),
                ),
              ),

              const SizedBox(height: 8),
              // Enhanced summary and controls with modern design
              Container(
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Status filter dropdown - positioned in summary row
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.surface,
                              colors.surfaceContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: colors.outlineLight, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadowLight,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownMenu<int?>(
                          initialSelection: _statusGroup == null
                              ? null
                              : (_statusGroup == HttpStatusGroup.informational
                                  ? 1
                                  : (_statusGroup == HttpStatusGroup.success
                                      ? 2
                                      : (_statusGroup ==
                                              HttpStatusGroup.redirection
                                          ? 3
                                          : (_statusGroup ==
                                                  HttpStatusGroup.clientError
                                              ? 4
                                              : 5)))),
                          onSelected: _onStatusChanged,
                          // width: 160,
                          inputDecorationTheme: InputDecorationTheme(
                            isCollapsed: true,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: InputBorder.none,
                            filled: false,
                          ),
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(value: null, label: 'All Status'),
                            DropdownMenuEntry(
                                value: 1, label: '1xx Informational'),
                            DropdownMenuEntry(value: 2, label: '2xx Success'),
                            DropdownMenuEntry(
                                value: 3, label: '3xx Redirection'),
                            DropdownMenuEntry(
                                value: 4, label: '4xx Client Error'),
                            DropdownMenuEntry(
                                value: 5, label: '5xx Server Error'),
                          ],
                          hintText: 'Filter',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Enhanced summary count with animations using optimized counting
                      Builder(
                        builder: (context) {
                          // Use the optimized countByStatusGroup method for better performance
                          final counts = CachedCurlStorage.countByStatusGroup(
                            search: _searchQuery,
                            startDate: _startDate,
                            endDate: _endDate,
                          );

                          final informational =
                              counts[HttpStatusGroup.informational]!;
                          final done = counts[HttpStatusGroup.success]!;
                          final fail = counts[HttpStatusGroup.clientError]! +
                              counts[HttpStatusGroup.serverError]!;
                          final redirection =
                              counts[HttpStatusGroup.redirection]!;

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Row(
                              key: ValueKey(
                                  '$informational-$done-$fail-$redirection'),
                              children: [
                                if (informational > 0) ...[
                                  _buildStatusChip(
                                    '${UiHelper.getStatusEmoji(100)} $informational',
                                    UiHelper.getStatusColor(100),
                                    onTap: () =>
                                        _onStatusChipTapped('informational'),
                                    isSelected:
                                        _selectedStatusChip == 'informational',
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                _buildStatusChip(
                                  '${UiHelper.getStatusEmoji(200)} $done',
                                  UiHelper.getStatusColor(200),
                                  onTap: () => _onStatusChipTapped('success'),
                                  isSelected: _selectedStatusChip == 'success',
                                ),
                                const SizedBox(width: 12),
                                _buildStatusChip(
                                  '${UiHelper.getStatusEmoji(400)} $fail',
                                  UiHelper.getStatusColor(400),
                                  onTap: () => _onStatusChipTapped('error'),
                                  isSelected: _selectedStatusChip == 'error',
                                ),
                                if (redirection > 0) ...[
                                  const SizedBox(width: 12),
                                  _buildStatusChip(
                                    '${UiHelper.getStatusEmoji(300)} $redirection',
                                    UiHelper.getStatusColor(300),
                                    onTap: () =>
                                        _onStatusChipTapped('redirection'),
                                    isSelected:
                                        _selectedStatusChip == 'redirection',
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      // Enhanced date range picker with modern styling
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.surface,
                              colors.surfaceContainer,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: colors.outlineLight, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadowLight,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _startDate == null && _endDate == null
                            ? Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _pickDateRange,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.date_range,
                                            size: 18,
                                            color:
                                                UiHelper.getMethodColor('GET')),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Date Range',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                UiHelper.getMethodColor('GET'),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _pickDateRange,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.date_range,
                                            size: 16,
                                            color:
                                                UiHelper.getMethodColor('GET')),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_startDate != null ? _formatDateTime(_startDate!) : ''} ~ ${_endDate != null ? _formatDateTime(_endDate!) : ''}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                UiHelper.getMethodColor('GET'),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isLoading && entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        UiHelper.getMethodColorPalette('GET').light,
                        UiHelper.getMethodColorPalette('GET').lighter,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: UiHelper.getMethodColorPalette('GET').shadow,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      UiHelper.getMethodColor('GET'),
                    ),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading cached logs...',
                  style: TextStyle(
                    fontSize: 18,
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we fetch your data',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (entries.isEmpty && !isLoading)
          Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadowMedium,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.search_off,
                    size: 48,
                    color: colors.onSurfaceTertiary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No logs match your filters',
                  style: TextStyle(
                    fontSize: 18,
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search criteria or date range',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: entries.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == entries.length) {
                        // Enhanced loading indicator at the bottom
                        return Container(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: UiHelper.getMethodColorPalette('GET')
                                      .lighter,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          UiHelper.getMethodColorPalette('GET')
                                              .shadow,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    UiHelper.getMethodColor('GET'),
                                  ),
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Loading more entries...',
                                style: TextStyle(
                                  color: colors.onSurfaceSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final entry = entries[index];
                      final formattedTime = _formatDateTime(
                          entry.timestamp.toLocal(),
                          includeTime: true);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.surface,
                              colors.surfaceContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: UiHelper.getStatusColorPalette(
                                    entry.statusCode ?? 200)
                                .border,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: UiHelper.getStatusColorPalette(
                                      entry.statusCode ?? 200)
                                  .shadow,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: colors.shadowLight,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            dense: true,
                            tilePadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            collapsedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            childrenPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            iconColor: UiHelper.getStatusColor(
                                entry.statusCode ?? 200),
                            collapsedIconColor: UiHelper.getStatusColorPalette(
                                    entry.statusCode ?? 200)
                                .secondary,
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        UiHelper.getStatusColorPalette(
                                                entry.statusCode ?? 200)
                                            .background,
                                        UiHelper.getStatusColorPalette(
                                                entry.statusCode ?? 200)
                                            .backgroundLight,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: UiHelper.getStatusColorPalette(
                                              entry.statusCode ?? 200)
                                          .borderStrong,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: UiHelper.getStatusColorPalette(
                                                entry.statusCode ?? 200)
                                            .shadow,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${entry.statusCode ?? kNA}',
                                    style: TextStyle(
                                      color: UiHelper.getStatusColorPalette(
                                              entry.statusCode ?? 200)
                                          .dark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        UiHelper.getMethodColorPalette(
                                                entry.method ?? 'GET')
                                            .light,
                                        UiHelper.getMethodColorPalette(
                                                entry.method ?? 'GET')
                                            .lighter,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: UiHelper.getMethodColorPalette(
                                              entry.method ?? 'GET')
                                          .border,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: UiHelper.getMethodColorPalette(
                                                entry.method ?? 'GET')
                                            .shadow,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    entry.method ?? kNA,
                                    style: TextStyle(
                                      color: UiHelper.getMethodColorPalette(
                                              entry.method ?? 'GET')
                                          .dark,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        CurlViewerColors.neutral.light,
                                        CurlViewerColors.neutral.lighter,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: CurlViewerColors.neutral.border,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CurlViewerColors.neutral.shadow,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    formattedTime,
                                    style: TextStyle(
                                      color: CurlViewerColors.neutral.dark,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                entry.url ?? kNA,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurfaceSecondary),
                              ),
                            ),
                            expandedAlignment: Alignment.centerLeft,
                            children: [
                              if (entry.url != null)
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style:
                                            DefaultTextStyle.of(context).style,
                                        children: [
                                          TextSpan(
                                            text: entry.method ?? kNA,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text:
                                                ' - [${entry.duration ?? kNA} ms]',
                                          ),
                                        ],
                                      ),
                                    ),
                                    SelectableText(entry.url!),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              Row(
                                children: [
                                  const Text('cURL:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color:
                                          UiHelper.getMethodColorPalette('GET')
                                              .lighter,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: UiHelper.getMethodColorPalette(
                                                'GET')
                                            .border,
                                        width: 1,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.copy,
                                          size: 18,
                                          color:
                                              UiHelper.getMethodColor('GET')),
                                      tooltip: 'Copy cURL',
                                      onPressed: () async {
                                        await Clipboard.setData(ClipboardData(
                                            text: entry.curlCommand));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: UiHelper.getStatusColorPalette(200)
                                          .lighter,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            UiHelper.getStatusColorPalette(200)
                                                .border,
                                        width: 1,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.share,
                                          size: 18,
                                          color: UiHelper.getStatusColor(200)),
                                      tooltip: 'Share cURL',
                                      onPressed: () => _shareCurlCommand(entry),
                                    ),
                                  ),
                                ],
                              ),
                              SelectableText(entry.curlCommand),
                              const SizedBox(height: 4),
                              if (entry.responseHeaders != null &&
                                  entry.responseHeaders!.isNotEmpty)
                                ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  dense: true,
                                  title: const Text('Response Headers:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: SelectableText(stringify(
                                          entry.responseHeaders,
                                          indent: '  ')),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              const Text('Response Body:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SelectableText(entry.responseBody ?? '<no body>'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.surface,
                        colors.surfaceContainer,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border(
                      top: BorderSide(color: colors.outlineLight, width: 1.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadowLight,
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: UiHelper.getStatusColor(500),
                            side: BorderSide(
                                color: UiHelper.getStatusColorPalette(500)
                                    .secondary,
                                width: 1.5),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor:
                                UiHelper.getStatusColorPalette(500).lighter,
                          ),
                          onPressed: () async {
                            final confirmed = await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            UiHelper.getStatusColorPalette(400)
                                                .background,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.warning,
                                          color: UiHelper.getStatusColor(400),
                                          size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Clear Logs',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                content: const Text(
                                  'Are you sure you want to clear all cached logs? This action cannot be undone.',
                                  style: TextStyle(fontSize: 14, height: 1.4),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          UiHelper.getStatusColor(500),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Clear All',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await CachedCurlStorage.clear();
                              _loadEntries(reset: true);
                            }
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text(
                            'Clear All',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CurlViewerColors.neutral.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.displayType) {
      case CurlViewerDisplayType.dialog:
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.all(16),
          elevation: 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _buildContent(),
          ),
        );
      case CurlViewerDisplayType.bottomSheet:
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: CurlViewerColors.theme(context).shadowStrong,
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: _buildContent(),
          ),
        );
      case CurlViewerDisplayType.fullScreen:
        return Scaffold(
          body: _buildContent(),
        );
    }
  }
}
