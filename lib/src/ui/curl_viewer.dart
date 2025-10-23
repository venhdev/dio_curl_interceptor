import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';

import '../core/helpers/ui_helper.dart';
import '../core/types.dart';
import '../core/interfaces/color_palette.dart';
import '../data/models/cached_curl_entry.dart';
import 'bubble_overlay.dart';
import 'controllers/curl_viewer_controller.dart';
import 'widgets/curl_entry_item.dart';
import 'widgets/status_summary.dart';
import 'widgets/curl_viewer_header.dart';
import 'widgets/filter_rule_editor.dart';
import '../options/filter_options.dart';
import '../services/filter_management_service.dart';

/// Global configuration style for CurlViewer
/// Standardized styling system to ensure consistent appearance across different applications
class CurlViewerStyle {
  // Private constructor to prevent instantiation
  CurlViewerStyle._();

  // Dimensions
  static const double borderRadius = 12.0;
  static const double height = 32.0;
  static const double iconSize = 16.0;
  static const double fontSize = 12.0;
  static const double borderWidth = 1.5;
  static const double smallSpacing = 4.0;
  static const double mediumSpacing = 8.0;
  static const double largeSpacing = 16.0;
  static const double extraLargeSpacing = 24.0;

  // Paddings
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );
  static const EdgeInsets contentPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPadding = EdgeInsets.all(12);
  static const EdgeInsets dialogPadding = EdgeInsets.all(16);

  // Text Styles
  static TextStyle get titleStyle =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2);

  static TextStyle get subtitleStyle =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.2);

  static TextStyle get bodyStyle =>
      const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, height: 1.4);

  static TextStyle get captionStyle =>
      const TextStyle(fontSize: 10, fontWeight: FontWeight.normal, height: 1.2);

  // Button Styles
  static ButtonStyle get primaryButtonStyle => ButtonStyle(
    padding: WidgetStateProperty.all(buttonPadding),
    minimumSize: WidgetStateProperty.all(const Size(64, height)),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
    ),
  );

  static ButtonStyle get secondaryButtonStyle => ButtonStyle(
    padding: WidgetStateProperty.all(buttonPadding),
    minimumSize: WidgetStateProperty.all(const Size(64, height)),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(
          width: borderWidth,
          color: CurlViewerColors.theme.outline,
        ),
      ),
    ),
  );

  // Input Decoration
  static InputDecoration get inputDecoration => InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(width: borderWidth),
    ),
    contentPadding: padding,
  );
}

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
  // STATIC THEME COLORS - Optimized for performance (no Theme.of lookups)
  // ============================================================================

  /// Get static theme colors (no BuildContext needed for better performance)
  static const theme = CurlViewerThemeColors();
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
  Color get backgroundLight => Colors.blue[25] ?? Colors.blue[50]!;
  Color get border => Colors.blue[200]!;
  Color get borderStrong => Colors.blue[400]!;
  Color get shadow => Colors.blue.withValues(alpha: 0.1);
  Color get shadowStrong => Colors.blue.withValues(alpha: 0.2);
}

/// Neutral elements colors (grey palette)
class _NeutralColors implements ColorPalette {
  const _NeutralColors();

  @override
  Color get primary => Colors.grey[600]!;
  @override
  Color get secondary => Colors.grey[400]!;
  @override
  Color get light => Colors.grey[100]!;
  @override
  Color get lighter => Colors.grey[50]!;
  @override
  Color get dark => Colors.grey[700]!;
  @override
  Color get background => Colors.grey[50]!;
  Color get backgroundLight => Colors.grey[25] ?? Colors.grey[50]!;
  @override
  Color get border => Colors.grey[200]!;
  Color get borderStrong => Colors.grey[400]!;
  @override
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

/// Static colors that don't depend on theme for better performance
class CurlViewerThemeColors {
  const CurlViewerThemeColors();

  // Background colors - using lighter theme colors for better readability
  Color get surface => const Color(0xFFF5F5F5);
  Color get surfaceContainer => const Color(0xFFEBEBEB);

  // Text colors - dark text on light background
  Color get onSurface => const Color(0xFF212121);
  Color get onSurfaceVariant => const Color(0xFF424242);
  Color get onSurfaceSecondary => const Color(0xFF616161);
  Color get onSurfaceTertiary => const Color(0xFF757575);

  // Border and outline colors
  Color get outline => const Color(0xFFBDBDBD);
  Color get outlineLight => const Color(0xFFE0E0E0);
  Color get outlineStrong => const Color(0xFF9E9E9E);

  // Shadow colors
  Color get shadow => const Color(0x1A000000);
  Color get shadowLight => const Color(0x0D000000);
  Color get shadowMedium => const Color(0x1A000000);
  Color get shadowStrong => const Color(0x4D000000);

  // Primary theme colors
  Color get primary => const Color(0xFF2196F3);
  Color get primaryContainer => const Color(0xFF1976D2);
  Color get onPrimary => const Color(0xFFFFFFFF);
  Color get onPrimaryContainer => const Color(0xFFE3F2FD);
}

/// Display type for the CurlViewer
enum CurlViewerDisplayType { dialog, bottomSheet, fullScreen, bubble }

/// Shows the CurlViewer in different display modes
void showCurlViewer(
  BuildContext context, {
  CurlViewerDisplayType displayType = CurlViewerDisplayType.dialog,
  VoidCallback? onClose,
  bool showCloseButton = false,
  bool enablePersistence = false,
}) async {
  switch (displayType) {
    case CurlViewerDisplayType.dialog:
      showDialog(
        context: context,
        builder: (_) => CurlViewer(
          displayType: displayType,
          onClose: onClose,
          showCloseButton: showCloseButton,
          enablePersistence: enablePersistence,
        ),
      );
      break;
    case CurlViewerDisplayType.bottomSheet:
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => CurlViewer(
          displayType: displayType,
          onClose: onClose,
          showCloseButton: showCloseButton,
          enablePersistence: enablePersistence,
        ),
      );
      break;
    case CurlViewerDisplayType.fullScreen:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CurlViewer(
            displayType: displayType,
            onClose: onClose,
            showCloseButton: showCloseButton,
            enablePersistence: enablePersistence,
          ),
        ),
      );
      break;
    case CurlViewerDisplayType.bubble:
      // For bubble display type, we need to use CurlBubble widget
      // This function is mainly for backward compatibility
      // For bubble usage, developers should use CurlBubble widget directly
      throw UnsupportedError(
        'Bubble display type is not supported in showCurlViewer. '
        'Use CurlBubble widget directly in your app\'s Stack instead.',
      );
  }
}

class CurlViewer extends StatefulWidget {
  const CurlViewer({
    super.key,
    this.displayType = CurlViewerDisplayType.dialog,
    this.onClose,
    this.showCloseButton = false,
    this.controller,
    this.enablePersistence = false,
  });

  final CurlViewerDisplayType displayType;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final CurlViewerController? controller;
  final bool enablePersistence;

  @override
  State<CurlViewer> createState() => _CurlViewerState();
}

class _CurlViewerState extends State<CurlViewer> {
  late CurlViewerController _controller;
  late FilterManagementService _filterService;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        CurlViewerController(enablePersistence: widget.enablePersistence);
    _filterService = FilterManagementService();
    _controller.initialize();

    // Sync filter changes with the filter service
    _controller.activeFilters.addListener(_onFiltersChanged);
  }

  @override
  void dispose() {
    // Remove listener
    _controller.activeFilters.removeListener(_onFiltersChanged);

    // Only dispose if we created the controller
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFiltersChanged() {
    // Update the filter service when filters change
    final filterOptions = _controller.getCurrentFilterOptions();
    _filterService.updateFilters(filterOptions);
  }

  void _onStatusChanged(int? val) {
    ResponseStatus? status;
    if (val == 1) {
      status = ResponseStatus.informational;
    } else if (val == 2) {
      status = ResponseStatus.success;
    } else if (val == 3) {
      status = ResponseStatus.redirection;
    } else if (val == 4) {
      status = ResponseStatus.clientError;
    } else if (val == 5) {
      status = ResponseStatus.serverError;
    }
    _controller.updateStatusGroup(status);
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CurlViewerStyle.borderRadius),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: CurlViewerStyle.dialogPadding,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    color: CurlViewerColors.theme.primary,
                    size: CurlViewerStyle.iconSize * 1.5,
                  ),
                  SizedBox(width: CurlViewerStyle.mediumSpacing),
                  Text(
                    'Filter Rules',
                    style: CurlViewerStyle.titleStyle.copyWith(
                      color: CurlViewerColors.theme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      size: CurlViewerStyle.iconSize,
                    ),
                    padding: CurlViewerStyle.padding,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: CurlViewerStyle.largeSpacing),
              Expanded(child: _buildFiltersContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersContent() {
    return ValueListenableBuilder<List<FilterRule>>(
      valueListenable: _controller.activeFilters,
      builder: (context, filters, child) {
        return Column(
          children: [
            // Add new filter button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddFilterDialog(),
                icon: const Icon(Icons.add, size: CurlViewerStyle.iconSize),
                label: Text(
                  'Add Filter Rule',
                  style: CurlViewerStyle.bodyStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: CurlViewerStyle.primaryButtonStyle.copyWith(
                  backgroundColor: WidgetStateProperty.all(
                    CurlViewerColors.theme.primary,
                  ),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
              ),
            ),
            SizedBox(height: CurlViewerStyle.largeSpacing),
            // Filters list
            Expanded(
              child: filters.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_alt_outlined,
                            size: 64,
                            color: CurlViewerColors.theme.onSurfaceVariant,
                          ),
                          SizedBox(height: CurlViewerStyle.largeSpacing),
                          Text(
                            'No filter rules configured',
                            style: CurlViewerStyle.subtitleStyle.copyWith(
                              color: CurlViewerColors.theme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: CurlViewerStyle.smallSpacing),
                          Text(
                            'Add a filter rule to block specific API requests',
                            style: CurlViewerStyle.bodyStyle.copyWith(
                              color: CurlViewerColors.theme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filters.length,
                      itemBuilder: (context, index) {
                        final filter = filters[index];
                        return Card(
                          margin: EdgeInsets.only(
                            bottom: CurlViewerStyle.mediumSpacing,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              CurlViewerStyle.borderRadius,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.filter_alt,
                              color: CurlViewerColors.theme.primary,
                              size: CurlViewerStyle.iconSize,
                            ),
                            title: Text(
                              filter.pathPattern,
                              style: CurlViewerStyle.subtitleStyle.copyWith(
                                color: CurlViewerColors.theme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              '${filter.matchType.name} • ${filter.statusCode}',
                              style: CurlViewerStyle.bodyStyle.copyWith(
                                color: CurlViewerColors.theme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      _showTestFilterDialog(filter),
                                  icon: const Icon(
                                    Icons.play_arrow,
                                    size: CurlViewerStyle.iconSize,
                                  ),
                                  tooltip: 'Test Filter',
                                  padding: CurlViewerStyle.padding,
                                  constraints: const BoxConstraints(),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _showEditFilterDialog(index, filter),
                                  icon: const Icon(
                                    Icons.edit,
                                    size: CurlViewerStyle.iconSize,
                                  ),
                                  tooltip: 'Edit',
                                  padding: CurlViewerStyle.padding,
                                  constraints: const BoxConstraints(),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _controller.removeFilter(index),
                                  icon: const Icon(
                                    Icons.delete,
                                    size: CurlViewerStyle.iconSize,
                                  ),
                                  tooltip: 'Delete',
                                  padding: CurlViewerStyle.padding,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showAddFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: FilterRuleEditor(
            onSave: (rule) {
              if (_controller.validateFilter(rule)) {
                _controller.addFilter(rule);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Filter rule added successfully'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _controller.filterValidationError.value ??
                          'Invalid filter rule',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _showEditFilterDialog(int index, FilterRule rule) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: FilterRuleEditor(
            initialRule: rule,
            onSave: (updatedRule) {
              if (_controller.validateFilter(updatedRule)) {
                _controller.updateFilter(index, updatedRule);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Filter rule updated successfully'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _controller.filterValidationError.value ??
                          'Invalid filter rule',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _showTestFilterDialog(FilterRule rule) {
    final testUrlController = TextEditingController(text: '/api/test');
    final testMethodController = TextEditingController(text: 'GET');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CurlViewerStyle.borderRadius),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          padding: CurlViewerStyle.dialogPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.play_arrow,
                    color: CurlViewerColors.theme.primary,
                    size: CurlViewerStyle.iconSize * 1.5,
                  ),
                  SizedBox(width: CurlViewerStyle.mediumSpacing),
                  Text(
                    'Test Filter Rule',
                    style: CurlViewerStyle.titleStyle.copyWith(
                      color: CurlViewerColors.theme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      size: CurlViewerStyle.iconSize,
                    ),
                    padding: CurlViewerStyle.padding,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: CurlViewerStyle.largeSpacing),
              Text(
                'Test this filter rule against a sample request:',
                style: CurlViewerStyle.bodyStyle.copyWith(
                  color: CurlViewerColors.theme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: CurlViewerStyle.largeSpacing),
              TextField(
                controller: testUrlController,
                decoration: CurlViewerStyle.inputDecoration.copyWith(
                  labelText: 'Test URL Path',
                  hintText: '/api/users/123',
                ),
              ),
              SizedBox(height: CurlViewerStyle.largeSpacing),
              TextField(
                controller: testMethodController,
                decoration: CurlViewerStyle.inputDecoration.copyWith(
                  labelText: 'HTTP Method',
                  hintText: 'GET',
                ),
              ),
              SizedBox(height: CurlViewerStyle.extraLargeSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: CurlViewerStyle.secondaryButtonStyle,
                    child: Text('Cancel', style: CurlViewerStyle.bodyStyle),
                  ),
                  SizedBox(width: CurlViewerStyle.mediumSpacing),
                  ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final testRequest = RequestOptions(
                        path: testUrlController.text,
                        method: testMethodController.text,
                      );

                      final result = await _filterService.testFilterRule(
                        rule,
                        testRequest,
                      );

                      if (!mounted) return;
                      navigator.pop();
                      _showTestResultDialog(result);
                    },
                    child: const Text('Test'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTestResultDialog(FilterTestResult result) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    result.matches ? Icons.check_circle : Icons.cancel,
                    color: result.matches ? Colors.green : Colors.red,
                    size: CurlViewerStyle.iconSize * 1.5,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Test Result',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CurlViewerColors.theme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: result.matches
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: result.matches ? Colors.green : Colors.red,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.matches
                          ? 'Filter would BLOCK this request'
                          : 'Filter would ALLOW this request',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: result.matches ? Colors.green : Colors.red,
                      ),
                    ),
                    if (result.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${result.errorMessage}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    if (result.response != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Response Status: ${result.response!.statusCode}',
                        style: TextStyle(
                          color: CurlViewerColors.theme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Response Data: ${result.response!.data}',
                        style: TextStyle(
                          color: CurlViewerColors.theme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onStatusChipTapped(String statusType) {
    if (_controller.selectedStatusChip.value == statusType) {
      // If already selected, deselect it
      _controller.updateSelectedStatusChip(null);
      _controller.updateStatusGroup(null);
    } else {
      // Select the new status chip
      _controller.updateSelectedStatusChip(statusType);
      ResponseStatus? status;
      switch (statusType) {
        case 'informational':
          status = ResponseStatus.informational;
          break;
        case 'success':
          status = ResponseStatus.success;
          break;
        case 'error':
          status = ResponseStatus.clientError;
          break;
        case 'redirection':
          status = ResponseStatus.redirection;
          break;
      }
      _controller.updateStatusGroup(status);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _controller.updateDateRange(picked.start, picked.end);
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
      await SharePlus.instance.share(ShareParams(text: shareText));
    } catch (e) {
      // Handle sharing errors gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Builds a shareable text representation of the cURL entry
  String _buildShareableText(CachedCurlEntry entry) {
    return entry.curlCommand;
  }

  Widget _buildContent() {
    return ValueListenableBuilder<List<CachedCurlEntry>>(
      valueListenable: _controller.entries,
      builder: (context, entries, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _controller.isLoading,
          builder: (context, isLoading, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    _buildSummaryAndControls(),
                    _buildMainContent(),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return ValueListenableBuilder<String>(
      valueListenable: _controller.searchQuery,
      builder: (context, searchQuery, child) {
        return CurlViewerHeader(
          searchController: _controller.searchController,
          searchQuery: searchQuery,
          onReload: () => _controller.loadEntries(reset: true),
          onClose: widget.onClose ?? (() => Navigator.pop(context)),
          showCloseButton: widget.showCloseButton,
          onFiltersPressed: _showFiltersDialog,
          onClearAll: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Xác nhận xóa'),
                  content: const Text(
                    'Bạn có chắc chắn muốn xóa tất cả các mục cURL đã lưu không?',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Xóa'),
                    ),
                  ],
                );
              },
            );
            if (confirmed == true) {
              await _controller.clearAllEntries();
            }
          },
        );
      },
    );
  }

  Widget _buildSummaryAndControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusFilter(),
            const SizedBox(width: 8),
            ValueListenableBuilder<Map<ResponseStatus, int>>(
              valueListenable: _controller.statusCounts,
              builder: (context, statusCounts, child) {
                return ValueListenableBuilder<String?>(
                  valueListenable: _controller.selectedStatusChip,
                  builder: (context, selectedStatusChip, child) {
                    return StatusSummary(
                      statusCounts: statusCounts,
                      selectedStatusChip: selectedStatusChip,
                      onStatusChipTapped: (statusType) {
                        _onStatusChipTapped(statusType);
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(width: 8),
            _buildDateRangePicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return ValueListenableBuilder<bool>(
      valueListenable: _controller.isLoading,
      builder: (context, isLoading, child) {
        if (isLoading && _controller.entries.value.isEmpty) {
          return _buildLoadingIndicator();
        }

        return ValueListenableBuilder<List<CachedCurlEntry>>(
          valueListenable: _controller.entries,
          builder: (context, entries, child) {
            if (entries.isEmpty && !isLoading) {
              return Expanded(child: _buildEmptyState());
            }

            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CurlViewerColors.theme.surface,
                      CurlViewerColors.theme.surfaceContainer,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(child: _buildEntriesList()),
                    if (widget.displayType != CurlViewerDisplayType.bubble)
                      _buildBottomActionButtons(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEntriesList() {
    return ValueListenableBuilder<List<CachedCurlEntry>>(
      valueListenable: _controller.entries,
      builder: (context, entries, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _controller.isLoadingMore,
          builder: (context, isLoadingMore, child) {
            return ListView.builder(
              padding: EdgeInsets.zero,
              controller: _controller.scrollController,
              itemCount: entries.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == entries.length) {
                  return _buildLoadingMoreIndicator();
                }
                return CurlEntryItem(
                  entry: entries[index],
                  onCopy: () async {
                    await Clipboard.setData(
                      ClipboardData(text: entries[index].curlCommand),
                    );
                  },
                  onShare: () => _shareCurlCommand(entries[index]),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No cURL entries found',
        style: TextStyle(
          fontSize: 16,
          color: CurlViewerColors.theme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return ValueListenableBuilder<ResponseStatus?>(
      valueListenable: _controller.statusGroup,
      builder: (context, statusGroup, child) {
        return DropdownMenu<int>(
          width: 150,
          initialSelection: statusGroup == null
              ? null
              : statusGroup == ResponseStatus.informational
              ? 1
              : statusGroup == ResponseStatus.success
              ? 2
              : statusGroup == ResponseStatus.redirection
              ? 3
              : statusGroup == ResponseStatus.clientError
              ? 4
              : statusGroup == ResponseStatus.serverError
              ? 5
              : null,
          hintText: 'All Status',
          textStyle: TextStyle(
            color: CurlViewerColors.theme.onSurface,
            fontSize: 12,
          ),
          dropdownMenuEntries: const [
            DropdownMenuEntry<int>(value: 1, label: 'Informational (1xx)'),
            DropdownMenuEntry<int>(value: 2, label: 'Success (2xx)'),
            DropdownMenuEntry<int>(value: 3, label: 'Redirection (3xx)'),
            DropdownMenuEntry<int>(value: 4, label: 'Client Error (4xx)'),
            DropdownMenuEntry<int>(value: 5, label: 'Server Error (5xx)'),
          ],
          onSelected: _onStatusChanged,
          inputDecorationTheme: InputDecorationTheme(
            hintStyle: TextStyle(
              color: CurlViewerColors.theme.onSurfaceVariant,
              fontSize: 12,
            ),
            filled: true,
            isCollapsed: true,
            isDense: true,
            fillColor: CurlViewerColors.theme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: CurlViewerColors.theme.outline),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateRangePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CurlViewerColors.theme.surfaceContainer,
            CurlViewerColors.theme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CurlViewerColors.theme.outline, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: CurlViewerColors.theme.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ValueListenableBuilder<DateTime?>(
        valueListenable: _controller.startDate,
        builder: (context, startDate, child) {
          return ValueListenableBuilder<DateTime?>(
            valueListenable: _controller.endDate,
            builder: (context, endDate, child) {
              return GestureDetector(
                onTap: _pickDateRange,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: CurlViewerColors.theme.onSurfaceVariant,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      startDate == null
                          ? 'All Dates'
                          : '${_formatDateTime(startDate)} - ${_formatDateTime(endDate!)}',
                      style: TextStyle(
                        color: CurlViewerColors.theme.onSurface,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildBottomActionButtons() {
    final colors = CurlViewerColors.theme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.surface, colors.surfaceContainer],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(top: BorderSide(color: colors.outlineLight, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: colors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 200) {
            return const SizedBox.shrink();
          }

          if (constraints.maxWidth < 300) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UiHelper.getStatusColor(500),
                      side: BorderSide(color: UiHelper.getStatusColor(500)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All'),
                    onPressed: () async {
                      await _controller.clearAllEntries();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UiHelper.getStatusColor(200),
                      side: BorderSide(color: UiHelper.getStatusColor(200)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reload'),
                    onPressed: () => _controller.loadEntries(reset: true),
                  ),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UiHelper.getStatusColor(500),
                      side: BorderSide(color: UiHelper.getStatusColor(500)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All'),
                    onPressed: () async {
                      await _controller.clearAllEntries();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UiHelper.getStatusColor(200),
                      side: BorderSide(color: UiHelper.getStatusColor(200)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reload'),
                    onPressed: () => _controller.loadEntries(reset: true),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.displayType) {
      case CurlViewerDisplayType.dialog:
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BubbleBorderRadius.dialogRadiusValue,
          ),
          insetPadding: const EdgeInsets.all(16),
          elevation: 10,
          child: ClipRRect(
            borderRadius: BubbleBorderRadius.dialogRadiusValue,
            child: _buildContent(),
          ),
        );
      case CurlViewerDisplayType.bottomSheet:
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            borderRadius: BubbleBorderRadius.bottomSheetRadius,
            boxShadow: [
              BoxShadow(
                color: CurlViewerColors.theme.shadowStrong,
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BubbleBorderRadius.bottomSheetRadius,
            child: _buildContent(),
          ),
        );
      case CurlViewerDisplayType.fullScreen:
        return Scaffold(body: _buildContent());
      case CurlViewerDisplayType.bubble:
        // For bubble display type, just return the content without additional wrapper
        return _buildContent();
    }
  }
}
