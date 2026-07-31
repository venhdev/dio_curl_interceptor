/// Centralized icon style constants for consistent sizing, spacing, and radii
/// across all UI widgets. Single source of truth — no behavior, just values.
class ActionIconStyle {
  // ============================================================================
  // ICON SIZES
  // ============================================================================

  /// Extra small — compact clear buttons, dense layouts
  static const double sizeXS = 14;

  /// Small — action buttons in list items (copy, share)
  static const double sizeSM = 16;

  /// Medium — header buttons (reload, close, terminal)
  static const double sizeMD = 18;

  /// Large — popup menu items, prominent actions
  static const double sizeLG = 20;

  // ============================================================================
  // BORDER RADII
  // ============================================================================

  /// Small — action buttons (copy, share, clear)
  static const double radiusSM = 6;

  /// Medium — header icon buttons (reload, filter, close)
  static const double radiusMD = 12;

  /// Large — status chips, expanded touch targets
  static const double radiusLG = 16;

  // ============================================================================
  // PADDING / INSETS
  // ============================================================================

  /// Small — action buttons in list items
  static const EdgeInsets paddingSM = EdgeInsets.all(6);

  /// Medium — header icon buttons
  static const EdgeInsets paddingMD = EdgeInsets.all(8);

  /// Large — status chips, expanded touch targets
  static const EdgeInsets paddingLG = EdgeInsets.all(12);

  // ============================================================================
  // COMMON DECORATIONS (for Container wrappers)
  // ============================================================================

  /// Subtle background + border for action buttons (copy, share)
  static BoxDecoration actionButtonDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radiusSM),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      );

  /// Transparent with ripple area for header buttons (reload, close)
  static BoxDecoration headerButtonDecoration() => BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radiusMD),
      );

  /// Subtle background for status chips
  static BoxDecoration chipDecoration(ColorPalette palette) => BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.light, palette.lighter],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radiusSM),
        border: Border.all(color: palette.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      );
}