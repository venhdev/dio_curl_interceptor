import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/helpers/ui_helper.dart';
import '../core/types.dart';
import '../core/interfaces/color_palette.dart';
import '../data/models/cached_curl_entry.dart';
import 'bubble_overlay.dart';
import 'controllers/curl_viewer_controller.dart';
import 'widgets/curl_entry_item.dart';
import 'widgets/status_summary.dart';
import 'widgets/curl_viewer_header.dart';

/// Global configuration style for CurlViewer
class CurlViewerStyle {
  // Private constructor to prevent instantiation
  CurlViewerStyle._();

  // Border radius for all elements
  static const double borderRadius = 12.0;

  // Height for all elements
  static const double height = 32.0;

  // Padding for all elements
  static const EdgeInsets padding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 6);

  // Icon size for all elements
  static const double iconSize = 16.0;

  // Font size for all elements
  static const double fontSize = 12.0;

  // Border width for all elements
  static const double borderWidth = 1.5;
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
  Color get backgroundLight => Colors.blue[25] ?? Colors.blue[50]!;
  Color get border => Colors.blue[200]!;
  Color get borderStrong => Colors.blue[400]!;
  Color get shadow => Colors.blue.withOpacity(0.1);
  Color get shadowStrong => Colors.blue.withOpacity(0.2);
}

/// Neutral elements colors (grey palette)
class _NeutralColors implements ColorPalette {
  const _NeutralColors();

  Color get primary => Colors.grey[600]!;
  Color get secondary => Colors.grey[400]!;
  Color get light => Colors.grey[100]!;
  Color get lighter => Colors.grey[50]!;
  Color get dark => Colors.grey[700]!;
  Color get background => Colors.grey[50]!;
  Color get backgroundLight => Colors.grey[25] ?? Colors.grey[50]!;
  Color get border => Colors.grey[200]!;
  Color get borderStrong => Colors.grey[400]!;
  Color get shadow => Colors.grey.withOpacity(0.1);
  Color get shadowStrong => Colors.grey.withOpacity(0.2);
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
  Color get shadow => Colors.orange.withOpacity(0.1);
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
  Color get onSurfaceSecondary => _scheme.onSurface.withOpacity(0.7);
  Color get onSurfaceTertiary => _scheme.onSurface.withOpacity(0.6);

  // Border and outline colors
  Color get outline => _scheme.outline;
  Color get outlineLight => _scheme.outline.withOpacity(0.3);
  Color get outlineStrong => _scheme.outline.withOpacity(0.5);

  // Shadow colors
  Color get shadow => _scheme.shadow;
  Color get shadowLight => _scheme.shadow.withOpacity(0.05);
  Color get shadowMedium => _scheme.shadow.withOpacity(0.1);
  Color get shadowStrong => _scheme.shadow.withOpacity(0.3);

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
  bubble,
}

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

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? CurlViewerController(enablePersistence: widget.enablePersistence);
    _controller.initialize();
  }

  @override
  void dispose() {
    // Only dispose if we created the controller
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
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
      await Share.share(shareText);
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
    final buffer = StringBuffer();
    buffer.writeln('cURL Command:');
    buffer.writeln(entry.curlCommand);
    buffer.writeln();
    buffer.writeln('Status: ${entry.statusCode ?? 'N/A'}');
    buffer.writeln('Method: ${entry.method ?? 'N/A'}');
    buffer.writeln('Duration: ${entry.duration ?? 'N/A'} ms');
    buffer.writeln('URL: ${entry.url ?? 'N/A'}');
    buffer.writeln('Timestamp: ${_formatDateTime(entry.timestamp, includeTime: true)}');
    
    if (entry.responseBody != null && entry.responseBody!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Response Body:');
      buffer.writeln(entry.responseBody);
    }
    
    return buffer.toString();
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
            _buildStatusFilter(),
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
              return _buildEmptyState();
            }
            
            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CurlViewerColors.theme(context).surface,
                      CurlViewerColors.theme(context).surfaceContainer,
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
                    await Clipboard.setData(ClipboardData(text: entries[index].curlCommand));
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
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Text(
          'No cURL entries found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ValueListenableBuilder<ResponseStatus?>(
        valueListenable: _controller.statusGroup,
        builder: (context, statusGroup, child) {
          return DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: statusGroup == null
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
              hint: Text(
                'All Status',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              dropdownColor: Colors.grey.shade800,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              items: const [
                DropdownMenuItem<int>(value: 1, child: Text('Informational (1xx)')),
                DropdownMenuItem<int>(value: 2, child: Text('Success (2xx)')),
                DropdownMenuItem<int>(value: 3, child: Text('Redirection (3xx)')),
                DropdownMenuItem<int>(value: 4, child: Text('Client Error (4xx)')),
                DropdownMenuItem<int>(value: 5, child: Text('Server Error (5xx)')),
              ],
              onChanged: _onStatusChanged,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      startDate == null
                          ? 'All Dates'
                          : '${_formatDateTime(startDate)} - ${_formatDateTime(endDate!)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
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
    final colors = CurlViewerColors.theme(context);
    return Container(
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                color: CurlViewerColors.theme(context).shadowStrong,
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
        return Scaffold(
          body: _buildContent(),
        );
      case CurlViewerDisplayType.bubble:
        // For bubble display type, just return the content without additional wrapper
        return _buildContent();
    }
  }
}
