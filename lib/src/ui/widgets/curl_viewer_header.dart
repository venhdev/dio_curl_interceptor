import 'package:flutter/material.dart';

class CurlViewerHeader extends StatelessWidget {
  const CurlViewerHeader({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onReload,
    required this.onClearFilters,
    required this.onDateRange,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onReload;
  final VoidCallback onClearFilters;
  final VoidCallback onDateRange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search logs',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: searchController.clear,
                        icon: const Icon(Icons.clear),
                      ),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Choose date range',
            onPressed: onDateRange,
            icon: const Icon(Icons.date_range),
          ),
          IconButton(
            tooltip: 'Reload logs',
            onPressed: onReload,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (_) => onClearFilters(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear', child: Text('Clear filters')),
            ],
          ),
        ],
      ),
    );
  }
}
