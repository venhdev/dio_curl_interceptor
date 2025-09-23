import 'package:flutter/material.dart';

import '../bubble_overlay.dart';

class CurlViewerHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onReload;
  final VoidCallback? onClose;
  final bool showCloseButton;

  const CurlViewerHeader({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onReload,
    this.onClose,
    this.showCloseButton = false,
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
                  const SizedBox(width: 8),
                  _buildReloadButton(),
                  if (showCloseButton) ...[
                    const SizedBox(width: 8),
                    _buildCloseButton(),
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
            hintText: 'Search by status, cURL, response, URL...',
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

  Widget _buildCloseButton() {
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
}
