import 'dart:async';

// import 'package:codekit/codekit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:type_caster/type_caster.dart';

import '../core/constants.dart';
import '../data/curl_response_cache.dart';

/// Reusable color palette for CurlViewer component
/// 
/// This class provides a centralized way to manage all colors used in the CurlViewer.
/// Colors are organized by semantic meaning to make them easy to understand and maintain.
class CurlViewerColors {
  // Private constructor to prevent instantiation
  CurlViewerColors._();

  // ============================================================================
  // STATUS COLORS - Success/Failure indicators
  // ============================================================================
  
  /// Success status colors (2xx HTTP status codes)
  static const success = _SuccessColors();
  
  /// Error status colors (4xx/5xx HTTP status codes)
  static const error = _ErrorColors();

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

/// Success status colors (green palette)
class _SuccessColors {
  const _SuccessColors();
  
  Color get primary => Colors.green[600]!;
  Color get secondary => Colors.green[400]!;
  Color get light => Colors.green[100]!;
  Color get lighter => Colors.green[50]!;
  Color get dark => Colors.green[700]!;
  Color get background => Colors.green.withValues(alpha: 0.1);
  Color get backgroundLight => Colors.green.withValues(alpha: 0.05);
  Color get border => Colors.green.withValues(alpha: 0.3);
  Color get borderStrong => Colors.green.withValues(alpha: 0.4);
  Color get shadow => Colors.green.withValues(alpha: 0.1);
}

/// Error status colors (red palette)
class _ErrorColors {
  const _ErrorColors();
  
  Color get primary => Colors.red[600]!;
  Color get secondary => Colors.red[400]!;
  Color get light => Colors.red[100]!;
  Color get lighter => Colors.red[50]!;
  Color get dark => Colors.red[700]!;
  Color get background => Colors.red.withValues(alpha: 0.1);
  Color get backgroundLight => Colors.red.withValues(alpha: 0.05);
  Color get border => Colors.red.withValues(alpha: 0.3);
  Color get borderStrong => Colors.red.withValues(alpha: 0.4);
  Color get shadow => Colors.red.withValues(alpha: 0.1);
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
    } else if (val == 2) {
      _statusGroup = HttpStatusGroup.success;
    } else if (val == 4) {
      _statusGroup = HttpStatusGroup.clientError;
    } else if (val == 5) {
      _statusGroup = HttpStatusGroup.serverError;
    }
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

  Widget _buildStatusChip(String text, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surface,
                colors.surfaceContainer,
                colors.primary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              top: widget.displayType == CurlViewerDisplayType.dialog ? const Radius.circular(20) : Radius.zero,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadowStrong,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.terminal, size: 20, color: colors.onSurface),
                ),
                const SizedBox(width: 12),
                Text(
                  'Cached cURL Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withValues(alpha: 0.8),
                        colors.primary.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.outlineLight),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$totalCount entries',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            automaticallyImplyLeading: widget.displayType == CurlViewerDisplayType.fullScreen,
            backgroundColor: Colors.transparent,
            foregroundColor: colors.onSurface,
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
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by status, cURL, response, URL...',
                            hintStyle: TextStyle(fontSize: 14, color: colors.onSurfaceTertiary, fontWeight: FontWeight.w400),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: CurlViewerColors.interactive.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.search, color: CurlViewerColors.interactive.primary, size: 18),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: CurlViewerColors.error.lighter,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.clear, color: CurlViewerColors.error.primary, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        _performSearch();
                                      },
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          onChanged: _onSearchChanged,
                          onSubmitted: (_) => _performSearch(),
                        ),
                      ),
                      Container(
                        height: 48,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.outlineLight),
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
                              : (_statusGroup == HttpStatusGroup.success
                                  ? 2
                                  : (_statusGroup == HttpStatusGroup.clientError ? 4 : 5)),
                          onSelected: _onStatusChanged,
                          width: 120,
                          inputDecorationTheme: InputDecorationTheme(
                            isCollapsed: true,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: InputBorder.none,
                            filled: false,
                          ),
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(value: null, label: 'All Status'),
                            DropdownMenuEntry(value: 2, label: '2xx Success'),
                            DropdownMenuEntry(value: 4, label: '4xx Client Error'),
                            DropdownMenuEntry(value: 5, label: '5xx Server Error'),
                          ],
                          hintText: 'Filter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              // Enhanced summary and controls with modern design
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primaryContainer.withValues(alpha: 0.3),
                      colors.primaryContainer.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Enhanced summary count with animations
                      Builder(
                        builder: (context) {
                          int done =
                              entries.where((e) => (e.statusCode ?? 0) >= 200 && (e.statusCode ?? 0) < 300).length;
                          int fail = entries.where((e) => (e.statusCode ?? 0) >= 400).length;
                          int pending = entries.length - done - fail;
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Row(
                              key: ValueKey('$done-$fail-$pending'),
                              children: [
                                _buildStatusChip('✅ $done', Colors.green),
                                const SizedBox(width: 12),
                                _buildStatusChip('❌ $fail', Colors.red),
                                if (pending > 0) ...[
                                  const SizedBox(width: 12),
                                  _buildStatusChip('⏳ $pending', Colors.orange),
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
                          border: Border.all(color: colors.outlineLight, width: 1.5),
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
                                        Icon(Icons.date_range, size: 18, color: CurlViewerColors.interactive.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Pick Date Range',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: CurlViewerColors.interactive.primary,
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
                                        Icon(Icons.date_range, size: 16, color: CurlViewerColors.interactive.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_startDate != null ? _formatDateTime(_startDate!) : ''} ~ ${_endDate != null ? _formatDateTime(_endDate!) : ''}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: CurlViewerColors.interactive.primary,
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
                        CurlViewerColors.interactive.light,
                        CurlViewerColors.interactive.lighter,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: CurlViewerColors.interactive.shadowStrong,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      CurlViewerColors.interactive.primary,
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
                                  color: CurlViewerColors.interactive.lighter,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: CurlViewerColors.interactive.shadowStrong,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    CurlViewerColors.interactive.primary,
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
                      final formattedTime = _formatDateTime(entry.timestamp.toLocal(), includeTime: true);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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
                            color: (entry.statusCode ?? 200) >= 400
                                ? CurlViewerColors.error.border
                                : CurlViewerColors.success.border,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (entry.statusCode ?? 200) >= 400
                                  ? CurlViewerColors.error.shadow
                                  : CurlViewerColors.success.shadow,
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
                            tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            iconColor: (entry.statusCode ?? 200) >= 400 ? CurlViewerColors.error.primary : CurlViewerColors.success.primary,
                            collapsedIconColor: (entry.statusCode ?? 200) >= 400 ? CurlViewerColors.error.secondary : CurlViewerColors.success.secondary,
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: (entry.statusCode ?? 200) >= 400
                                          ? [
                                              CurlViewerColors.error.background,
                                              CurlViewerColors.error.backgroundLight,
                                            ]
                                          : [
                                              CurlViewerColors.success.background,
                                              CurlViewerColors.success.backgroundLight,
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: (entry.statusCode ?? 200) >= 400
                                          ? CurlViewerColors.error.borderStrong
                                          : CurlViewerColors.success.borderStrong,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (entry.statusCode ?? 200) >= 400
                                            ? CurlViewerColors.error.shadow
                                            : CurlViewerColors.success.shadow,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${entry.statusCode ?? 'N/A'}',
                                    style: TextStyle(
                                      color: (entry.statusCode ?? 200) >= 400 ? CurlViewerColors.error.dark : CurlViewerColors.success.dark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        CurlViewerColors.interactive.light,
                                        CurlViewerColors.interactive.lighter,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: CurlViewerColors.interactive.border,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CurlViewerColors.interactive.shadow,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    entry.method ?? 'N/A',
                                    style: TextStyle(
                                      color: CurlViewerColors.interactive.dark,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                                entry.url ?? 'N/A',
                                style: TextStyle(fontSize: 12, color: colors.onSurfaceSecondary),
                              ),
                            ),
                            expandedAlignment: Alignment.centerLeft,
                            children: [
                              if (entry.url != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: DefaultTextStyle.of(context).style,
                                        children: [
                                          TextSpan(
                                            text: entry.method ?? kNA,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: ' - [${entry.duration ?? kNA} ms]',
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
                                  const Text('cURL:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    tooltip: 'Copy cURL',
                                    onPressed: () async {
                                      await Clipboard.setData(ClipboardData(text: entry.curlCommand));
                                    },
                                  ),
                                ],
                              ),
                              SelectableText(entry.curlCommand),
                              const SizedBox(height: 4),
                              if (entry.responseHeaders != null && entry.responseHeaders!.isNotEmpty)
                                ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  dense: true,
                                  title: const Text('Response Headers:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: SelectableText(stringify(entry.responseHeaders, indent: '  ')),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              const Text('Response Body:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            foregroundColor: CurlViewerColors.error.primary,
                            side: BorderSide(color: CurlViewerColors.error.secondary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: CurlViewerColors.error.lighter,
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
                                        color: CurlViewerColors.warning.background,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.warning, color: CurlViewerColors.warning.primary, size: 20),
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
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: CurlViewerColors.error.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text(
                                      'Clear All',
                                      style: TextStyle(fontWeight: FontWeight.w600),
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
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
