import 'package:flutter/material.dart';
import '../../options/filter_options.dart';
import '../curl_viewer.dart';

/// A widget for editing individual filter rules
class FilterRuleEditor extends StatefulWidget {
  const FilterRuleEditor({
    super.key,
    this.initialRule,
    this.onSave,
    this.onCancel,
  });

  /// Initial filter rule to edit (null for new rule)
  final FilterRule? initialRule;

  /// Callback when save is pressed
  final void Function(FilterRule rule)? onSave;

  /// Callback when cancel is pressed
  final VoidCallback? onCancel;

  @override
  State<FilterRuleEditor> createState() => _FilterRuleEditorState();
}

class _FilterRuleEditorState extends State<FilterRuleEditor> {
  late final TextEditingController _pathController;
  late final TextEditingController _statusCodeController;
  late final TextEditingController _responseDataController;

  PathMatchType _selectedMatchType = PathMatchType.exact;
  List<String> _selectedMethods = [];
  Map<String, dynamic> _headers = {};

  final List<String> _availableMethods = [
    'GET',
    'POST',
    'PUT',
    'DELETE',
    'PATCH',
    'HEAD',
    'OPTIONS'
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with initial values
    _pathController =
        TextEditingController(text: widget.initialRule?.pathPattern ?? '');
    _statusCodeController = TextEditingController(
        text: widget.initialRule?.statusCode.toString() ?? '403');
    _responseDataController = TextEditingController(
        text: widget.initialRule?.responseData?.toString() ?? '');

    _selectedMatchType = widget.initialRule?.matchType ?? PathMatchType.exact;
    _selectedMethods = List<String>.from(widget.initialRule?.methods ?? []);
    _headers = Map<String, dynamic>.from(widget.initialRule?.headers ?? {});
  }

  @override
  void dispose() {
    _pathController.dispose();
    _statusCodeController.dispose();
    _responseDataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CurlViewerColors.theme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(CurlViewerStyle.borderRadius),
        border: Border.all(
          color: theme.outline,
          width: CurlViewerStyle.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 16),
          _buildPathPatternField(theme),
          const SizedBox(height: 16),
          _buildMatchTypeDropdown(theme),
          const SizedBox(height: 16),
          _buildMethodsSelection(theme),
          const SizedBox(height: 16),
          _buildStatusCodeField(theme),
          const SizedBox(height: 16),
          _buildResponseDataField(theme),
          const SizedBox(height: 16),
          _buildHeadersSection(theme),
          const SizedBox(height: 24),
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(CurlViewerThemeColors theme) {
    return Row(
      children: [
        Icon(
          Icons.filter_alt,
          color: theme.primary,
          size: CurlViewerStyle.iconSize,
        ),
        const SizedBox(width: 8),
        Text(
          widget.initialRule == null ? 'Add Filter Rule' : 'Edit Filter Rule',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPathPatternField(CurlViewerThemeColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Path Pattern',
          style: TextStyle(
            fontSize: CurlViewerStyle.fontSize,
            fontWeight: FontWeight.w500,
            color: theme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _pathController,
          decoration: InputDecoration(
            hintText: 'e.g., /api/users, /api/*, /api/v\\d+/.*',
            hintStyle: TextStyle(
              color: theme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CurlViewerStyle.borderRadius),
              borderSide: BorderSide(
                color: theme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CurlViewerStyle.borderRadius),
              borderSide: BorderSide(
                color: theme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchTypeDropdown(CurlViewerThemeColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match Type',
          style: TextStyle(
            fontSize: CurlViewerStyle.fontSize,
            fontWeight: FontWeight.w500,
            color: theme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<PathMatchType>(
          initialValue: _selectedMatchType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CurlViewerStyle.borderRadius),
              borderSide: BorderSide(
                color: theme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CurlViewerStyle.borderRadius),
              borderSide: BorderSide(
                color: theme.primary,
              ),
            ),
          ),
          items: PathMatchType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getMatchTypeDescription(type)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMatchType = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildMethodsSelection(CurlViewerThemeColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HTTP Methods (optional)',
          style: TextStyle(
            fontSize: CurlViewerStyle.fontSize,
            fontWeight: FontWeight.w500,
            color: theme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableMethods.map((method) {
            final isSelected = _selectedMethods.contains(method);
            return FilterChip(
              label: Text(method),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedMethods.add(method);
                  } else {
                    _selectedMethods.remove(method);
                  }
                });
              },
              selectedColor: theme.primary.withValues(alpha: 0.2),
              checkmarkColor: theme.primary,
            );
          }).toList(),
        ),
        if (_selectedMethods.isEmpty)
          Text(
            'Leave empty to apply to all methods',
            style: TextStyle(
              fontSize: 12,
              color: theme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildStatusCodeField(CurlViewerThemeColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Code',
          style: TextStyle(
            fontSize: CurlViewerStyle.fontSize,
            fontWeight: FontWeight.w500,
            color: theme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _statusCodeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '403',
            hintStyle: TextStyle(
              color: theme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CurlViewerStyle.borderRadius),
              borderSide: BorderSide(
                color: theme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CurlViewerStyle.borderRadius),
              borderSide: BorderSide(
                color: theme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseDataField(CurlViewerThemeColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Response Data (optional)',
          style: TextStyle(
            fontSize: CurlViewerStyle.fontSize,
            fontWeight: FontWeight.w500,
            color: theme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _responseDataController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '{"message": "Request blocked"}',
            hintStyle: TextStyle(
              color: theme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CurlViewerStyle.borderRadius),
              borderSide: BorderSide(
                color: theme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CurlViewerStyle.borderRadius),
              borderSide: BorderSide(
                color: theme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeadersSection(CurlViewerThemeColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Custom Headers (optional)',
              style: TextStyle(
                fontSize: CurlViewerStyle.fontSize,
                fontWeight: FontWeight.w500,
                color: theme.onSurface,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                Icons.add,
                size: CurlViewerStyle.iconSize,
                color: theme.primary,
              ),
              onPressed: _addHeader,
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_headers.isEmpty)
          Container(
            padding: CurlViewerStyle.padding,
            decoration: BoxDecoration(
              color: theme.surfaceContainer,
              borderRadius: BorderRadius.circular(CurlViewerStyle.borderRadius),
              border: Border.all(
                color: theme.outline,
              ),
            ),
            child: Text(
              'No custom headers',
              style: TextStyle(
                color: theme.onSurfaceVariant,
              ),
            ),
          )
        else
          ..._headers.entries
              .map((entry) => _buildHeaderItem(entry.key, entry.value, theme)),
      ],
    );
  }

  Widget _buildHeaderItem(
      String key, dynamic value, CurlViewerThemeColors theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.surfaceContainer,
        borderRadius: BorderRadius.circular(CurlViewerStyle.borderRadius),
        border: Border.all(
          color: theme.outline,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$key: $value',
              style: TextStyle(
                fontSize: CurlViewerStyle.fontSize,
                color: theme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete,
              size: CurlViewerStyle.iconSize,
              color: theme.primary,
            ),
            onPressed: () => _removeHeader(key),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CurlViewerThemeColors theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text(
            'Cancel',
            style: TextStyle(
              color: theme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saveFilter,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CurlViewerStyle.borderRadius),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _getMatchTypeDescription(PathMatchType type) {
    switch (type) {
      case PathMatchType.exact:
        return 'Exact Match';
      case PathMatchType.regex:
        return 'Regular Expression';
      case PathMatchType.glob:
        return 'Glob Pattern';
    }
  }

  void _addHeader() {
    showDialog(
      context: context,
      builder: (context) => _HeaderDialog(
        onAdd: (key, value) {
          setState(() {
            _headers[key] = value;
          });
        },
      ),
    );
  }

  void _removeHeader(String key) {
    setState(() {
      _headers.remove(key);
    });
  }

  void _saveFilter() {
    final pathPattern = _pathController.text.trim();
    if (pathPattern.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Path pattern cannot be empty')),
      );
      return;
    }

    final statusCode = int.tryParse(_statusCodeController.text) ?? 403;
    if (statusCode < 100 || statusCode > 599) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Status code must be between 100 and 599')),
      );
      return;
    }

    dynamic responseData;
    final responseDataText = _responseDataController.text.trim();
    if (responseDataText.isNotEmpty) {
      try {
        // Try to parse as JSON first
        responseData = responseDataText;
      } catch (e) {
        // If not JSON, use as string
        responseData = responseDataText;
      }
    }

    final rule = FilterRule(
      pathPattern: pathPattern,
      matchType: _selectedMatchType,
      methods: _selectedMethods.isEmpty ? null : _selectedMethods,
      statusCode: statusCode,
      responseData: responseData,
      headers: _headers.isEmpty ? null : _headers,
    );

    widget.onSave?.call(rule);
  }
}

class _HeaderDialog extends StatefulWidget {
  const _HeaderDialog({required this.onAdd});

  final void Function(String key, String value) onAdd;

  @override
  State<_HeaderDialog> createState() => _HeaderDialogState();
}

class _HeaderDialogState extends State<_HeaderDialog> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Header'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _keyController,
            decoration: const InputDecoration(
              labelText: 'Header Name',
              hintText: 'X-Custom-Header',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            decoration: const InputDecoration(
              labelText: 'Header Value',
              hintText: 'custom-value',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final key = _keyController.text.trim();
            final value = _valueController.text.trim();
            if (key.isNotEmpty && value.isNotEmpty) {
              widget.onAdd(key, value);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
