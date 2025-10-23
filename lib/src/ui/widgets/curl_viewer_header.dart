import 'package:flutter/material.dart';

import '../bubble_overlay.dart';

class CurlViewerHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onReload;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final VoidCallback? onFiltersPressed;
  final VoidCallback? onClearAll;

  const CurlViewerHeader({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onReload,
    this.onClose,
    this.showCloseButton = false,
    this.onFiltersPressed,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: _buildDecoration(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildTerminalIcon(),
                  const SizedBox(width: 8),
                  _buildSearchBar(),
                  if (onFiltersPressed != null || onClearAll != null) ...[
                    const SizedBox(width: 8),
                    _buildDropdownButton(),
                  ],
                  const SizedBox(width: 8),
                  _buildReloadButton(),
                  if (showCloseButton) ...[
                    const SizedBox(width: 8),
                    _buildCloseButton(onClose),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    return BoxDecoration(
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
      borderRadius: BubbleBorderRadius.bubbleRadiusValue,
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
    );
  }

  Widget _buildTerminalIcon() {
    return Container(
      height: 36,
      width: 36,
      padding: const EdgeInsets.all(4),
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
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.terminal, size: 18, color: Colors.white),
    );
  }

  Widget _buildSearchBar() {
    return Expanded(
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.clear,
                          color: Colors.white, size: 14),
                      onPressed: () {
                        searchController.clear();
                      },
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildReloadButton() {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withValues(alpha: 0.2),
            Colors.green.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onReload,
          child: const Icon(Icons.refresh, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDropdownButton() {
    return PopupMenuButton(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.filter_list,
          color: Colors.white), // Giữ nguyên icon và màu sắc
      offset: Offset(0, 40),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: BoxConstraints(maxHeight: 150), // Chiều cao khi mở
      itemBuilder: (context) => [
        if (onFiltersPressed != null)
          PopupMenuItem(
            onTap: onFiltersPressed,
            child: Row(
              children: [
                _buildMenuItemIcon(Icons.filter_alt_outlined,
                    color: Colors.orange),
                SizedBox(width: 8),
                Text('Filters'),
              ],
            ),
          ),
        if (onClearAll != null)
          PopupMenuItem(
            onTap: onClearAll,
            child: Row(
              children: [
                _buildMenuItemIcon(Icons.delete_sweep_outlined,
                    color: Colors.red),
                SizedBox(width: 8),
                Text('Clear All'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMenuItemIcon(IconData iconData, {Color? color}) {
    return Icon(iconData, size: 20, color: color);
  }
}

Widget _buildCloseButton(void Function()? onClose) {
  return Container(
    height: 36,
    width: 36,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.red.withValues(alpha: 0.2),
          Colors.red.withValues(alpha: 0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.red.withValues(alpha: 0.4),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onClose,
        child: const Icon(Icons.close, size: 18, color: Colors.white),
      ),
    ),
  );
}
