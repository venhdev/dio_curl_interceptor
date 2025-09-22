# Phase 2: Replace setState calls with ValueNotifier updates

## 🎯 **Objective**
Replace all `setState` calls in `_CurlViewerState` with ValueNotifier updates and implement reactive UI updates using ValueListenableBuilder.

## 📋 **Current setState Usage Analysis**

### **Existing setState Calls in _CurlViewerState:**
```dart
// Line 262-264: Loading state
setState(() => isLoading = true);

// Line 266: Loading more state  
setState(() => isLoadingMore = true);

// Line 284-290: Data loading completion
setState(() {
  entries.addAll(newEntries);
  loadedCount = entries.length;
  totalCount = count;
  isLoading = false;
  isLoadingMore = false;
});

// Line 334-358: Status chip selection
setState(() {
  if (_selectedStatusChip == statusType) {
    _selectedStatusChip = null;
    _statusGroup = null;
  } else {
    // ... status selection logic
  }
});

// Line 367-371: Date range selection
if (picked != null) {
  _startDate = picked.start;
  _endDate = picked.end;
  _loadEntries(reset: true);
}
```

## 🏗️ **Implementation Plan**

### **Step 1: Remove setState Calls**

**Replace all setState calls with controller method calls:**

```dart
// OLD: setState(() => isLoading = true);
// NEW: _controller.isLoading.value = true;

// OLD: setState(() => isLoadingMore = true);
// NEW: _controller.isLoadingMore.value = true;

// OLD: setState(() { entries.addAll(newEntries); ... });
// NEW: _controller.loadEntries(reset: true);

// OLD: setState(() { _selectedStatusChip = statusType; ... });
// NEW: _controller.updateSelectedStatusChip(statusType);
```

### **Step 2: Implement ValueListenableBuilder for Reactive UI**

**File:** `lib/src/ui/curl_viewer.dart` (modifications)

```dart
class _CurlViewerState extends State<CurlViewer> {
  late CurlViewerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? CurlViewerController();
    _controller.initialize();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
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
      // ... other display types
    }
  }

  Widget _buildContent() {
    final colors = CurlViewerColors.theme(context);
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
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        // ... existing decoration
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTerminalIcon(),
                const SizedBox(width: 8),
                _buildSearchBar(),
                const SizedBox(width: 8),
                _buildReloadButton(),
                if (widget.showCloseButton) ...[
                  const SizedBox(width: 8),
                  _buildCloseButton(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Expanded(
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          // ... existing decoration
        ),
        child: TextField(
          controller: _controller.searchController,
          decoration: InputDecoration(
            hintText: 'Search by status, cURL, response, URL...',
            hintStyle: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
            suffixIcon: ValueListenableBuilder<String>(
              valueListenable: _controller.searchQuery,
              builder: (context, searchQuery, child) {
                return searchQuery.isNotEmpty
                    ? Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.clear, color: Colors.white, size: 14),
                          onPressed: () {
                            _controller.searchController.clear();
                            _controller.updateSearch('');
                          },
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          style: TextStyle(color: Colors.white, fontSize: 12),
          onChanged: (value) => _controller.updateSearch(value),
          onSubmitted: (_) => _controller.updateSearch(_controller.searchController.text),
        ),
      ),
    );
  }

  Widget _buildSummaryAndControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusChips(),
            const SizedBox(width: 8),
            _buildStatusFilter(),
            const SizedBox(width: 8),
            _buildDateRangePicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    return ValueListenableBuilder<Map<ResponseStatus, int>>(
      valueListenable: _controller.statusCounts,
      builder: (context, counts, child) {
        final informational = counts[ResponseStatus.informational] ?? 0;
        final done = counts[ResponseStatus.success] ?? 0;
        final fail = (counts[ResponseStatus.clientError] ?? 0) + (counts[ResponseStatus.serverError] ?? 0);
        final redirection = counts[ResponseStatus.redirection] ?? 0;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Row(
            key: ValueKey('$informational-$done-$fail-$redirection'),
            children: [
              if (informational > 0) ...[
                _buildStatusChip(
                  '${UiHelper.getStatusEmoji(100)} $informational',
                  UiHelper.getStatusColor(100),
                  onTap: () => _controller.updateSelectedStatusChip('informational'),
                  isSelected: _controller.selectedStatusChip.value == 'informational',
                ),
                const SizedBox(width: 8),
              ],
              _buildStatusChip(
                '${UiHelper.getStatusEmoji(200)} $done',
                UiHelper.getStatusColor(200),
                onTap: () => _controller.updateSelectedStatusChip('success'),
                isSelected: _controller.selectedStatusChip.value == 'success',
              ),
              const SizedBox(width: 8),
              _buildStatusChip(
                '${UiHelper.getStatusEmoji(400)} $fail',
                UiHelper.getStatusColor(400),
                onTap: () => _controller.updateSelectedStatusChip('error'),
                isSelected: _controller.selectedStatusChip.value == 'error',
              ),
              if (redirection > 0) ...[
                const SizedBox(width: 8),
                _buildStatusChip(
                  '${UiHelper.getStatusEmoji(300)} $redirection',
                  UiHelper.getStatusColor(300),
                  onTap: () => _controller.updateSelectedStatusChip('redirection'),
                  isSelected: _controller.selectedStatusChip.value == 'redirection',
                ),
              ],
            ],
          ),
        );
      },
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
              child: _buildEntriesList(),
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
                return _buildEntryItem(entries[index]);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEntryItem(CachedCurlEntry entry) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        // ... existing decoration
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          // ... existing ExpansionTile configuration
          title: _buildEntryTitle(entry),
          subtitle: _buildEntrySubtitle(entry),
          children: _buildEntryChildren(entry),
        ),
      ),
    );
  }

  // ... other helper methods remain the same
}
```

### **Step 3: Update Method Implementations**

**Replace all methods that used setState:**

```dart
// OLD: void _onSearchChanged(String value) { ... }
// NEW: Handled by controller automatically

// OLD: void _performSearch() { ... }
// NEW: _controller.updateSearch(_controller.searchController.text);

// OLD: void _onStatusChanged(int? val) { ... }
// NEW: _controller.updateStatusGroup(_getStatusFromValue(val));

// OLD: void _onStatusChipTapped(String statusType) { ... }
// NEW: _controller.updateSelectedStatusChip(statusType);

// OLD: Future<void> _pickDateRange() async { ... }
// NEW: _controller.updateDateRange(picked.start, picked.end);
```

## ✅ **Success Criteria**

- [ ] All setState calls removed
- [ ] All state updates go through controller
- [ ] UI updates reactively to ValueNotifier changes
- [ ] No performance regression
- [ ] All existing functionality preserved
- [ ] Smooth animations and transitions

## 🧪 **Testing Strategy**

1. **State Update Tests**: Verify ValueNotifier updates trigger UI changes
2. **Performance Tests**: Measure UI update performance
3. **Memory Tests**: Check for memory leaks
4. **Integration Tests**: Test full user interactions

## 📝 **Migration Notes**

- All UI updates now reactive
- No manual setState calls needed
- Controller handles all state management
- UI automatically updates when state changes
- Better separation of concerns

## 🚀 **Next Phase**

After completing Phase 2, proceed to Phase 3 to wrap expensive widgets with ValueListenableBuilder for optimal performance.
