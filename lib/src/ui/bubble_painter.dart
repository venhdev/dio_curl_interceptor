import 'package:flutter/material.dart';
import 'bubble_overlay.dart';

/// Custom painter for bubble components to improve rendering performance
/// by avoiding widget tree overhead
class BubblePainter extends CustomPainter {
  final Offset position;
  final Size size;
  final bool isExpanded;
  final bool isResizing;
  final BubbleStyle style;
  final double animationValue;

  const BubblePainter({
    required this.position,
    required this.size,
    required this.isExpanded,
    required this.isResizing,
    required this.style,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (!isExpanded) {
      _paintMinimizedBubble(canvas);
    } else {
      _paintExpandedBubble(canvas);
    }
  }

  void _paintMinimizedBubble(Canvas canvas) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.black, Colors.white],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final rect =
        Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    final radius = Radius.circular(size.width / 2);

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      shadowPaint,
    );

    // Draw main bubble
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      paint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      borderPaint,
    );

    // Draw icon
    _paintIcon(canvas, rect);
  }

  void _paintExpandedBubble(Canvas canvas) {
    final rect =
        Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    final radius = const Radius.circular(20.0);

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      shadowPaint,
    );

    // Draw main background
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.black.withValues(alpha: 0.95),
          Colors.grey.shade900.withValues(alpha: 0.95),
        ],
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      backgroundPaint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      borderPaint,
    );

    // Draw resize indicators if resizing
    if (isResizing) {
      _paintResizeIndicators(canvas, rect);
    }
  }

  void _paintIcon(Canvas canvas, Rect rect) {
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final iconSize = 24.0;
    final center = rect.center;
    final iconRect = Rect.fromCenter(
      center: center,
      width: iconSize,
      height: iconSize,
    );

    // Draw terminal icon (simplified as a rectangle with lines)
    final iconPath = Path();

    // Terminal window frame
    iconPath.addRRect(RRect.fromRectAndRadius(
      iconRect,
      const Radius.circular(4.0),
    ));

    // Terminal content lines
    final lineHeight = 2.0;
    final lineSpacing = 3.0;
    final startY = center.dy - 6.0;

    for (int i = 0; i < 3; i++) {
      final lineY = startY + (i * (lineHeight + lineSpacing));
      iconPath.addRect(Rect.fromLTWH(
        center.dx - 8.0,
        lineY,
        16.0,
        lineHeight,
      ));
    }

    canvas.drawPath(iconPath, iconPaint);
  }

  void _paintResizeIndicators(Canvas canvas, Rect rect) {
    final indicatorPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw resize border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20.0)),
      indicatorPaint,
    );

    // Draw corner indicators
    final cornerSize = 20.0;
    final cornerPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Bottom-right corner
    canvas.drawRect(
      Rect.fromLTWH(
        rect.right - cornerSize,
        rect.bottom - cornerSize,
        cornerSize,
        cornerSize,
      ),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left,
        rect.bottom - cornerSize,
        cornerSize,
        cornerSize,
      ),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(BubblePainter oldDelegate) {
    return position != oldDelegate.position ||
        size != oldDelegate.size ||
        isExpanded != oldDelegate.isExpanded ||
        isResizing != oldDelegate.isResizing ||
        animationValue != oldDelegate.animationValue;
  }
}

/// Custom painter for resize handles
class ResizeHandlePainter extends CustomPainter {
  final List<ResizeHandle> handles;
  final ResizeConfig config;

  const ResizeHandlePainter({
    required this.handles,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!config.showVisualIndicators) return;

    final paint = Paint()
      ..color = config.indicatorColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (final handle in handles) {
      canvas.drawRect(handle.rect, paint);
    }
  }

  @override
  bool shouldRepaint(ResizeHandlePainter oldDelegate) {
    return handles != oldDelegate.handles || config != oldDelegate.config;
  }
}

/// Represents a resize handle
class ResizeHandle {
  final Rect rect;
  final ResizeType type;

  const ResizeHandle({
    required this.rect,
    required this.type,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResizeHandle && other.rect == rect && other.type == type;
  }

  @override
  int get hashCode => Object.hash(rect, type);
}
