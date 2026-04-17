import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

typedef ColorPair = (Color, Color);

extension ColorPairExt on ColorPair {
  Color get past => $1;
  Color get future => $2;
}

/// Resolves the active package theme from the surrounding Flutter [Theme].
class TimelineTheme {
  static TimelineTableStyle of(BuildContext context) {
    return Theme.of(context).extension<TimelineThemeData>()?.tableStyle ??
        const TimelineTableStyle();
  }
}

/// App-wide timeline defaults stored in `ThemeData.extensions`.
class TimelineThemeData extends ThemeExtension<TimelineThemeData>
    with EquatableMixin {
  final TimelineTableStyle tableStyle;

  const TimelineThemeData({
    this.tableStyle = const TimelineTableStyle(),
  });

  @override
  TimelineThemeData copyWith({
    TimelineTableStyle? tableStyle,
  }) {
    return TimelineThemeData(
      tableStyle: tableStyle ?? this.tableStyle,
    );
  }

  @override
  TimelineThemeData lerp(
    covariant ThemeExtension<TimelineThemeData>? other,
    double t,
  ) {
    if (other is! TimelineThemeData) return this;
    return t < 0.5 ? this : other;
  }

  @override
  List<Object?> get props => [tableStyle];
}

/// Visual styling for the current-time indicator.
class TimelineCurrentTimeIndicatorStyle extends Equatable {
  final double width;
  final Color color;

  final bool _hasWidth;
  final bool _hasColor;

  const TimelineCurrentTimeIndicatorStyle({
    double? width,
    Color? color,
  }) : this._(
          width: width ?? 2.0,
          color: color ?? const Color(0xfff91a98),
          hasWidth: width != null,
          hasColor: color != null,
        );

  const TimelineCurrentTimeIndicatorStyle._({
    required this.width,
    required this.color,
    required bool hasWidth,
    required bool hasColor,
  })  : _hasWidth = hasWidth,
        _hasColor = hasColor;

  TimelineCurrentTimeIndicatorStyle copyWith({
    double? width,
    Color? color,
  }) {
    return TimelineCurrentTimeIndicatorStyle._(
      width: width ?? this.width,
      color: color ?? this.color,
      hasWidth: width != null || _hasWidth,
      hasColor: color != null || _hasColor,
    );
  }

  TimelineCurrentTimeIndicatorStyle merge(
    TimelineCurrentTimeIndicatorStyle base,
  ) {
    return TimelineCurrentTimeIndicatorStyle._(
      width: _hasWidth ? width : base.width,
      color: _hasColor ? color : base.color,
      hasWidth: _hasWidth || base._hasWidth,
      hasColor: _hasColor || base._hasColor,
    );
  }

  @override
  List<Object?> get props => [width, color];
}

/// Styling for the pinned timeline header area.
class TimelinePinnedHeaderStyle extends Equatable {
  final Color activeIconColor;
  final Color inactiveIconColor;
  final TextStyle labelStyle;
  final Color dividerColor;

  final bool _hasActiveIconColor;
  final bool _hasInactiveIconColor;
  final bool _hasLabelStyle;
  final bool _hasDividerColor;

  const TimelinePinnedHeaderStyle({
    Color? activeIconColor,
    Color? inactiveIconColor,
    TextStyle? labelStyle,
    Color? dividerColor,
  }) : this._(
          activeIconColor: activeIconColor ?? const Color(0xff757575),
          inactiveIconColor: inactiveIconColor ?? const Color(0xffbdbdbd),
          labelStyle:
              labelStyle ?? const TextStyle(fontWeight: FontWeight.bold),
          dividerColor: dividerColor ?? const Color(0xff9e9e9e),
          hasActiveIconColor: activeIconColor != null,
          hasInactiveIconColor: inactiveIconColor != null,
          hasLabelStyle: labelStyle != null,
          hasDividerColor: dividerColor != null,
        );

  const TimelinePinnedHeaderStyle._({
    required this.activeIconColor,
    required this.inactiveIconColor,
    required this.labelStyle,
    required this.dividerColor,
    required bool hasActiveIconColor,
    required bool hasInactiveIconColor,
    required bool hasLabelStyle,
    required bool hasDividerColor,
  })  : _hasActiveIconColor = hasActiveIconColor,
        _hasInactiveIconColor = hasInactiveIconColor,
        _hasLabelStyle = hasLabelStyle,
        _hasDividerColor = hasDividerColor;

  TimelinePinnedHeaderStyle copyWith({
    Color? activeIconColor,
    Color? inactiveIconColor,
    TextStyle? labelStyle,
    Color? dividerColor,
  }) {
    return TimelinePinnedHeaderStyle._(
      activeIconColor: activeIconColor ?? this.activeIconColor,
      inactiveIconColor: inactiveIconColor ?? this.inactiveIconColor,
      labelStyle: labelStyle ?? this.labelStyle,
      dividerColor: dividerColor ?? this.dividerColor,
      hasActiveIconColor: activeIconColor != null || _hasActiveIconColor,
      hasInactiveIconColor: inactiveIconColor != null || _hasInactiveIconColor,
      hasLabelStyle: labelStyle != null || _hasLabelStyle,
      hasDividerColor: dividerColor != null || _hasDividerColor,
    );
  }

  TimelinePinnedHeaderStyle merge(TimelinePinnedHeaderStyle base) {
    return TimelinePinnedHeaderStyle._(
      activeIconColor:
          _hasActiveIconColor ? activeIconColor : base.activeIconColor,
      inactiveIconColor:
          _hasInactiveIconColor ? inactiveIconColor : base.inactiveIconColor,
      labelStyle: _hasLabelStyle ? labelStyle : base.labelStyle,
      dividerColor: _hasDividerColor ? dividerColor : base.dividerColor,
      hasActiveIconColor: _hasActiveIconColor || base._hasActiveIconColor,
      hasInactiveIconColor: _hasInactiveIconColor || base._hasInactiveIconColor,
      hasLabelStyle: _hasLabelStyle || base._hasLabelStyle,
      hasDividerColor: _hasDividerColor || base._hasDividerColor,
    );
  }

  @override
  List<Object?> get props => [
        activeIconColor,
        inactiveIconColor,
        labelStyle,
        dividerColor,
      ];
}

/// Shared visual tokens for timeline cells and package-owned event rendering.
class TimelineCellStyle extends Equatable {
  final ColorPair emptyCellBackground;
  final ColorPair eventCellBackground;
  final ColorPair activeEventCellBackground;
  final ColorPair gridline;
  final double gridLineWidth;
  final double horizontalEventMargin;
  final double verticalEventMargin;
  final TextStyle labelStyle;
  final Color hoverBorderColor;
  final double hoverBorderWidth;
  final Color focusBorderColor;
  final double focusBorderWidth;
  final Color hoverOverlayColor;
  final Color focusOverlayColor;
  final Color splashColor;
  final Color highlightColor;
  final Color hoverShadowColor;
  final double hoverShadowBlurRadius;
  final Offset hoverShadowOffset;

  final bool _hasLabelStyle;
  final bool _hasEmptyCellBackground;
  final bool _hasEventCellBackground;
  final bool _hasActiveEventCellBackground;
  final bool _hasGridline;
  final bool _hasHorizontalEventMargin;
  final bool _hasVerticalEventMargin;
  final bool _hasGridLineWidth;
  final bool _hasHoverBorderColor;
  final bool _hasHoverBorderWidth;
  final bool _hasFocusBorderColor;
  final bool _hasFocusBorderWidth;
  final bool _hasHoverOverlayColor;
  final bool _hasFocusOverlayColor;
  final bool _hasSplashColor;
  final bool _hasHighlightColor;
  final bool _hasHoverShadowColor;
  final bool _hasHoverShadowBlurRadius;
  final bool _hasHoverShadowOffset;

  const TimelineCellStyle({
    TextStyle? labelStyle,
    ColorPair? emptyCellBackground,
    ColorPair? eventCellBackground,
    ColorPair? activeEventCellBackground,
    ColorPair? gridline,
    double? horizontalEventMargin,
    double? verticalEventMargin,
    double? gridLineWidth,
    Color? hoverBorderColor,
    double? hoverBorderWidth,
    Color? focusBorderColor,
    double? focusBorderWidth,
    Color? hoverOverlayColor,
    Color? focusOverlayColor,
    Color? splashColor,
    Color? highlightColor,
    Color? hoverShadowColor,
    double? hoverShadowBlurRadius,
    Offset? hoverShadowOffset,
  }) : this._(
          labelStyle:
              labelStyle ?? const TextStyle(fontSize: 12, color: Colors.white),
          emptyCellBackground: emptyCellBackground ??
              const (Color(0xffeee6e9), Color(0xfffbf9f9)),
          eventCellBackground: eventCellBackground ??
              const (Color.fromARGB(255, 92, 168, 94), Color(0xff6bcf72)),
          activeEventCellBackground: activeEventCellBackground ??
              const (
                Color.fromARGB(255, 76, 181, 80),
                Color.fromARGB(255, 103, 231, 112),
              ),
          gridline: gridline ??
              const (
                Color.fromARGB(255, 211, 202, 205),
                Color(0xffeae6e6),
              ),
          horizontalEventMargin: horizontalEventMargin ?? 1.0,
          verticalEventMargin: verticalEventMargin ?? 8.0,
          gridLineWidth: gridLineWidth ?? 1.0,
          hoverBorderColor: hoverBorderColor ?? const Color(0xb8ffffff),
          hoverBorderWidth: hoverBorderWidth ?? 1.0,
          focusBorderColor: focusBorderColor ?? Colors.white,
          focusBorderWidth: focusBorderWidth ?? 2.0,
          hoverOverlayColor: hoverOverlayColor ?? const Color(0x0fffffff),
          focusOverlayColor: focusOverlayColor ?? const Color(0x14ffffff),
          splashColor: splashColor ?? const Color(0x1fffffff),
          highlightColor: highlightColor ?? const Color(0x14ffffff),
          hoverShadowColor: hoverShadowColor ?? const Color(0x24000000),
          hoverShadowBlurRadius: hoverShadowBlurRadius ?? 10.0,
          hoverShadowOffset: hoverShadowOffset ?? const Offset(0, 3),
          hasLabelStyle: labelStyle != null,
          hasEmptyCellBackground: emptyCellBackground != null,
          hasEventCellBackground: eventCellBackground != null,
          hasActiveEventCellBackground: activeEventCellBackground != null,
          hasGridline: gridline != null,
          hasHorizontalEventMargin: horizontalEventMargin != null,
          hasVerticalEventMargin: verticalEventMargin != null,
          hasGridLineWidth: gridLineWidth != null,
          hasHoverBorderColor: hoverBorderColor != null,
          hasHoverBorderWidth: hoverBorderWidth != null,
          hasFocusBorderColor: focusBorderColor != null,
          hasFocusBorderWidth: focusBorderWidth != null,
          hasHoverOverlayColor: hoverOverlayColor != null,
          hasFocusOverlayColor: focusOverlayColor != null,
          hasSplashColor: splashColor != null,
          hasHighlightColor: highlightColor != null,
          hasHoverShadowColor: hoverShadowColor != null,
          hasHoverShadowBlurRadius: hoverShadowBlurRadius != null,
          hasHoverShadowOffset: hoverShadowOffset != null,
        );

  const TimelineCellStyle._({
    required this.labelStyle,
    required this.emptyCellBackground,
    required this.eventCellBackground,
    required this.activeEventCellBackground,
    required this.gridline,
    required this.horizontalEventMargin,
    required this.verticalEventMargin,
    required this.gridLineWidth,
    required this.hoverBorderColor,
    required this.hoverBorderWidth,
    required this.focusBorderColor,
    required this.focusBorderWidth,
    required this.hoverOverlayColor,
    required this.focusOverlayColor,
    required this.splashColor,
    required this.highlightColor,
    required this.hoverShadowColor,
    required this.hoverShadowBlurRadius,
    required this.hoverShadowOffset,
    required bool hasLabelStyle,
    required bool hasEmptyCellBackground,
    required bool hasEventCellBackground,
    required bool hasActiveEventCellBackground,
    required bool hasGridline,
    required bool hasHorizontalEventMargin,
    required bool hasVerticalEventMargin,
    required bool hasGridLineWidth,
    required bool hasHoverBorderColor,
    required bool hasHoverBorderWidth,
    required bool hasFocusBorderColor,
    required bool hasFocusBorderWidth,
    required bool hasHoverOverlayColor,
    required bool hasFocusOverlayColor,
    required bool hasSplashColor,
    required bool hasHighlightColor,
    required bool hasHoverShadowColor,
    required bool hasHoverShadowBlurRadius,
    required bool hasHoverShadowOffset,
  })  : _hasLabelStyle = hasLabelStyle,
        _hasEmptyCellBackground = hasEmptyCellBackground,
        _hasEventCellBackground = hasEventCellBackground,
        _hasActiveEventCellBackground = hasActiveEventCellBackground,
        _hasGridline = hasGridline,
        _hasHorizontalEventMargin = hasHorizontalEventMargin,
        _hasVerticalEventMargin = hasVerticalEventMargin,
        _hasGridLineWidth = hasGridLineWidth,
        _hasHoverBorderColor = hasHoverBorderColor,
        _hasHoverBorderWidth = hasHoverBorderWidth,
        _hasFocusBorderColor = hasFocusBorderColor,
        _hasFocusBorderWidth = hasFocusBorderWidth,
        _hasHoverOverlayColor = hasHoverOverlayColor,
        _hasFocusOverlayColor = hasFocusOverlayColor,
        _hasSplashColor = hasSplashColor,
        _hasHighlightColor = hasHighlightColor,
        _hasHoverShadowColor = hasHoverShadowColor,
        _hasHoverShadowBlurRadius = hasHoverShadowBlurRadius,
        _hasHoverShadowOffset = hasHoverShadowOffset;

  TimelineCellStyle copyWith({
    TextStyle? labelStyle,
    ColorPair? emptyCellBackground,
    ColorPair? eventCellBackground,
    ColorPair? activeEventCellBackground,
    ColorPair? gridline,
    double? horizontalEventMargin,
    double? verticalEventMargin,
    double? gridLineWidth,
    Color? hoverBorderColor,
    double? hoverBorderWidth,
    Color? focusBorderColor,
    double? focusBorderWidth,
    Color? hoverOverlayColor,
    Color? focusOverlayColor,
    Color? splashColor,
    Color? highlightColor,
    Color? hoverShadowColor,
    double? hoverShadowBlurRadius,
    Offset? hoverShadowOffset,
  }) {
    return TimelineCellStyle._(
      labelStyle: labelStyle ?? this.labelStyle,
      emptyCellBackground: emptyCellBackground ?? this.emptyCellBackground,
      eventCellBackground: eventCellBackground ?? this.eventCellBackground,
      activeEventCellBackground:
          activeEventCellBackground ?? this.activeEventCellBackground,
      gridline: gridline ?? this.gridline,
      horizontalEventMargin:
          horizontalEventMargin ?? this.horizontalEventMargin,
      verticalEventMargin: verticalEventMargin ?? this.verticalEventMargin,
      gridLineWidth: gridLineWidth ?? this.gridLineWidth,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
      focusBorderColor: focusBorderColor ?? this.focusBorderColor,
      focusBorderWidth: focusBorderWidth ?? this.focusBorderWidth,
      hoverOverlayColor: hoverOverlayColor ?? this.hoverOverlayColor,
      focusOverlayColor: focusOverlayColor ?? this.focusOverlayColor,
      splashColor: splashColor ?? this.splashColor,
      highlightColor: highlightColor ?? this.highlightColor,
      hoverShadowColor: hoverShadowColor ?? this.hoverShadowColor,
      hoverShadowBlurRadius:
          hoverShadowBlurRadius ?? this.hoverShadowBlurRadius,
      hoverShadowOffset: hoverShadowOffset ?? this.hoverShadowOffset,
      hasLabelStyle: labelStyle != null || _hasLabelStyle,
      hasEmptyCellBackground:
          emptyCellBackground != null || _hasEmptyCellBackground,
      hasEventCellBackground:
          eventCellBackground != null || _hasEventCellBackground,
      hasActiveEventCellBackground:
          activeEventCellBackground != null || _hasActiveEventCellBackground,
      hasGridline: gridline != null || _hasGridline,
      hasHorizontalEventMargin:
          horizontalEventMargin != null || _hasHorizontalEventMargin,
      hasVerticalEventMargin:
          verticalEventMargin != null || _hasVerticalEventMargin,
      hasGridLineWidth: gridLineWidth != null || _hasGridLineWidth,
      hasHoverBorderColor: hoverBorderColor != null || _hasHoverBorderColor,
      hasHoverBorderWidth: hoverBorderWidth != null || _hasHoverBorderWidth,
      hasFocusBorderColor: focusBorderColor != null || _hasFocusBorderColor,
      hasFocusBorderWidth: focusBorderWidth != null || _hasFocusBorderWidth,
      hasHoverOverlayColor: hoverOverlayColor != null || _hasHoverOverlayColor,
      hasFocusOverlayColor: focusOverlayColor != null || _hasFocusOverlayColor,
      hasSplashColor: splashColor != null || _hasSplashColor,
      hasHighlightColor: highlightColor != null || _hasHighlightColor,
      hasHoverShadowColor: hoverShadowColor != null || _hasHoverShadowColor,
      hasHoverShadowBlurRadius:
          hoverShadowBlurRadius != null || _hasHoverShadowBlurRadius,
      hasHoverShadowOffset: hoverShadowOffset != null || _hasHoverShadowOffset,
    );
  }

  TimelineCellStyle merge(TimelineCellStyle base) {
    return TimelineCellStyle._(
      labelStyle: _hasLabelStyle ? labelStyle : base.labelStyle,
      emptyCellBackground: _hasEmptyCellBackground
          ? emptyCellBackground
          : base.emptyCellBackground,
      eventCellBackground: _hasEventCellBackground
          ? eventCellBackground
          : base.eventCellBackground,
      activeEventCellBackground: _hasActiveEventCellBackground
          ? activeEventCellBackground
          : base.activeEventCellBackground,
      gridline: _hasGridline ? gridline : base.gridline,
      horizontalEventMargin: _hasHorizontalEventMargin
          ? horizontalEventMargin
          : base.horizontalEventMargin,
      verticalEventMargin: _hasVerticalEventMargin
          ? verticalEventMargin
          : base.verticalEventMargin,
      gridLineWidth: _hasGridLineWidth ? gridLineWidth : base.gridLineWidth,
      hoverBorderColor:
          _hasHoverBorderColor ? hoverBorderColor : base.hoverBorderColor,
      hoverBorderWidth:
          _hasHoverBorderWidth ? hoverBorderWidth : base.hoverBorderWidth,
      focusBorderColor:
          _hasFocusBorderColor ? focusBorderColor : base.focusBorderColor,
      focusBorderWidth:
          _hasFocusBorderWidth ? focusBorderWidth : base.focusBorderWidth,
      hoverOverlayColor:
          _hasHoverOverlayColor ? hoverOverlayColor : base.hoverOverlayColor,
      focusOverlayColor:
          _hasFocusOverlayColor ? focusOverlayColor : base.focusOverlayColor,
      splashColor: _hasSplashColor ? splashColor : base.splashColor,
      highlightColor: _hasHighlightColor ? highlightColor : base.highlightColor,
      hoverShadowColor:
          _hasHoverShadowColor ? hoverShadowColor : base.hoverShadowColor,
      hoverShadowBlurRadius: _hasHoverShadowBlurRadius
          ? hoverShadowBlurRadius
          : base.hoverShadowBlurRadius,
      hoverShadowOffset:
          _hasHoverShadowOffset ? hoverShadowOffset : base.hoverShadowOffset,
      hasLabelStyle: _hasLabelStyle || base._hasLabelStyle,
      hasEmptyCellBackground:
          _hasEmptyCellBackground || base._hasEmptyCellBackground,
      hasEventCellBackground:
          _hasEventCellBackground || base._hasEventCellBackground,
      hasActiveEventCellBackground:
          _hasActiveEventCellBackground || base._hasActiveEventCellBackground,
      hasGridline: _hasGridline || base._hasGridline,
      hasHorizontalEventMargin:
          _hasHorizontalEventMargin || base._hasHorizontalEventMargin,
      hasVerticalEventMargin:
          _hasVerticalEventMargin || base._hasVerticalEventMargin,
      hasGridLineWidth: _hasGridLineWidth || base._hasGridLineWidth,
      hasHoverBorderColor: _hasHoverBorderColor || base._hasHoverBorderColor,
      hasHoverBorderWidth: _hasHoverBorderWidth || base._hasHoverBorderWidth,
      hasFocusBorderColor: _hasFocusBorderColor || base._hasFocusBorderColor,
      hasFocusBorderWidth: _hasFocusBorderWidth || base._hasFocusBorderWidth,
      hasHoverOverlayColor: _hasHoverOverlayColor || base._hasHoverOverlayColor,
      hasFocusOverlayColor: _hasFocusOverlayColor || base._hasFocusOverlayColor,
      hasSplashColor: _hasSplashColor || base._hasSplashColor,
      hasHighlightColor: _hasHighlightColor || base._hasHighlightColor,
      hasHoverShadowColor: _hasHoverShadowColor || base._hasHoverShadowColor,
      hasHoverShadowBlurRadius:
          _hasHoverShadowBlurRadius || base._hasHoverShadowBlurRadius,
      hasHoverShadowOffset: _hasHoverShadowOffset || base._hasHoverShadowOffset,
    );
  }

  @override
  List<Object?> get props => [
        emptyCellBackground,
        eventCellBackground,
        activeEventCellBackground,
        gridline,
        gridLineWidth,
        horizontalEventMargin,
        verticalEventMargin,
        labelStyle,
        hoverBorderColor,
        hoverBorderWidth,
        focusBorderColor,
        focusBorderWidth,
        hoverOverlayColor,
        focusOverlayColor,
        splashColor,
        highlightColor,
        hoverShadowColor,
        hoverShadowBlurRadius,
        hoverShadowOffset,
      ];
}

/// Resolved visual styling for a [TimelineTable].
class TimelineTableStyle extends Equatable {
  static const Object _unsetDecoration = Object();

  final double headerRowHeight;
  final double rowHeight;
  final double pinnedColumnWidth;
  final TimelineCellStyle cellStyle;
  final TimelineCurrentTimeIndicatorStyle currentTimeIndicatorStyle;

  @Deprecated(
    'Use currentTimeIndicatorStyle.width instead. '
    'This compatibility field will be removed in a future release.',
  )
  final double currentTimeIndicatorWidth;

  @Deprecated(
    'Use currentTimeIndicatorStyle.color instead. '
    'This compatibility field will be removed in a future release.',
  )
  final Color currentTimeIndicatorColor;

  final TimelinePinnedHeaderStyle pinnedHeaderStyle;
  final SpanDecoration? columnHeaderDecoration;
  final SpanDecoration? rowHeaderDecoration;

  final bool _hasHeaderRowHeight;
  final bool _hasRowHeight;
  final bool _hasPinnedColumnWidth;
  final bool _hasCellStyle;
  final bool _hasCurrentTimeIndicatorStyle;
  final bool _hasCurrentTimeIndicatorWidth;
  final bool _hasCurrentTimeIndicatorColor;
  final bool _hasPinnedHeaderStyle;
  final bool _hasColumnHeaderDecoration;
  final bool _hasRowHeaderDecoration;

  const TimelineTableStyle({
    double? headerRowHeight,
    double? rowHeight,
    double? pinnedColumnWidth,
    TimelineCellStyle? cellStyle,
    TimelineCurrentTimeIndicatorStyle? currentTimeIndicatorStyle,
    @Deprecated(
      'Use currentTimeIndicatorStyle.width instead. '
      'This compatibility field will be removed in a future release.',
    )
    double? currentTimeIndicatorWidth,
    @Deprecated(
      'Use currentTimeIndicatorStyle.color instead. '
      'This compatibility field will be removed in a future release.',
    )
    Color? currentTimeIndicatorColor,
    TimelinePinnedHeaderStyle? pinnedHeaderStyle,
    Object? columnHeaderDecoration = _unsetDecoration,
    Object? rowHeaderDecoration = _unsetDecoration,
  }) : this._(
          headerRowHeight: headerRowHeight ?? 48.0,
          rowHeight: rowHeight ?? 64.0,
          pinnedColumnWidth: pinnedColumnWidth ?? 128.0,
          cellStyle: cellStyle ?? const TimelineCellStyle(),
          currentTimeIndicatorStyle: currentTimeIndicatorStyle ??
              const TimelineCurrentTimeIndicatorStyle(),
          currentTimeIndicatorWidth: currentTimeIndicatorWidth ?? 2.0,
          currentTimeIndicatorColor:
              currentTimeIndicatorColor ?? const Color(0xfff91a98),
          pinnedHeaderStyle:
              pinnedHeaderStyle ?? const TimelinePinnedHeaderStyle(),
          columnHeaderDecoration:
              identical(columnHeaderDecoration, _unsetDecoration)
                  ? const SpanDecoration(
                      color: null,
                      border: TableSpanBorder(
                        trailing: BorderSide(
                          width: 1,
                          color: Color(0xff9e9e9e),
                        ),
                      ),
                    )
                  : columnHeaderDecoration as SpanDecoration?,
          rowHeaderDecoration: identical(rowHeaderDecoration, _unsetDecoration)
              ? const SpanDecoration(
                  color: null,
                  border: TableSpanBorder(
                    trailing: BorderSide(
                      width: 1,
                      color: Color(0xff9e9e9e),
                    ),
                  ),
                )
              : rowHeaderDecoration as SpanDecoration?,
          hasHeaderRowHeight: headerRowHeight != null,
          hasRowHeight: rowHeight != null,
          hasPinnedColumnWidth: pinnedColumnWidth != null,
          hasCellStyle: cellStyle != null,
          hasCurrentTimeIndicatorStyle: currentTimeIndicatorStyle != null,
          hasCurrentTimeIndicatorWidth: currentTimeIndicatorWidth != null,
          hasCurrentTimeIndicatorColor: currentTimeIndicatorColor != null,
          hasPinnedHeaderStyle: pinnedHeaderStyle != null,
          hasColumnHeaderDecoration:
              !identical(columnHeaderDecoration, _unsetDecoration),
          hasRowHeaderDecoration:
              !identical(rowHeaderDecoration, _unsetDecoration),
        );

  const TimelineTableStyle._({
    required this.headerRowHeight,
    required this.rowHeight,
    required this.pinnedColumnWidth,
    required this.cellStyle,
    required this.currentTimeIndicatorStyle,
    required this.currentTimeIndicatorWidth,
    required this.currentTimeIndicatorColor,
    required this.pinnedHeaderStyle,
    required this.columnHeaderDecoration,
    required this.rowHeaderDecoration,
    required bool hasHeaderRowHeight,
    required bool hasRowHeight,
    required bool hasPinnedColumnWidth,
    required bool hasCellStyle,
    required bool hasCurrentTimeIndicatorStyle,
    required bool hasCurrentTimeIndicatorWidth,
    required bool hasCurrentTimeIndicatorColor,
    required bool hasPinnedHeaderStyle,
    required bool hasColumnHeaderDecoration,
    required bool hasRowHeaderDecoration,
  })  : _hasHeaderRowHeight = hasHeaderRowHeight,
        _hasRowHeight = hasRowHeight,
        _hasPinnedColumnWidth = hasPinnedColumnWidth,
        _hasCellStyle = hasCellStyle,
        _hasCurrentTimeIndicatorStyle = hasCurrentTimeIndicatorStyle,
        _hasCurrentTimeIndicatorWidth = hasCurrentTimeIndicatorWidth,
        _hasCurrentTimeIndicatorColor = hasCurrentTimeIndicatorColor,
        _hasPinnedHeaderStyle = hasPinnedHeaderStyle,
        _hasColumnHeaderDecoration = hasColumnHeaderDecoration,
        _hasRowHeaderDecoration = hasRowHeaderDecoration;

  TimelineTableStyle copyWith({
    double? headerRowHeight,
    double? rowHeight,
    double? pinnedColumnWidth,
    TimelineCellStyle? cellStyle,
    TimelineCurrentTimeIndicatorStyle? currentTimeIndicatorStyle,
    @Deprecated(
      'Use currentTimeIndicatorStyle.width instead. '
      'This compatibility field will be removed in a future release.',
    )
    double? currentTimeIndicatorWidth,
    @Deprecated(
      'Use currentTimeIndicatorStyle.color instead. '
      'This compatibility field will be removed in a future release.',
    )
    Color? currentTimeIndicatorColor,
    TimelinePinnedHeaderStyle? pinnedHeaderStyle,
    Object? columnHeaderDecoration = _unsetDecoration,
    Object? rowHeaderDecoration = _unsetDecoration,
  }) {
    final nextIndicatorStyle =
        currentTimeIndicatorStyle ?? this.currentTimeIndicatorStyle;
    final nextIndicatorWidth =
        currentTimeIndicatorWidth ?? this.currentTimeIndicatorWidth;
    final nextIndicatorColor =
        currentTimeIndicatorColor ?? this.currentTimeIndicatorColor;
    final resolvedIndicatorStyle = _applyLegacyIndicatorFields(
      base: nextIndicatorStyle,
      widthOverride:
          currentTimeIndicatorWidth != null || _hasCurrentTimeIndicatorWidth
              ? nextIndicatorWidth
              : null,
      colorOverride:
          currentTimeIndicatorColor != null || _hasCurrentTimeIndicatorColor
              ? nextIndicatorColor
              : null,
    );

    return TimelineTableStyle._(
      headerRowHeight: headerRowHeight ?? this.headerRowHeight,
      rowHeight: rowHeight ?? this.rowHeight,
      pinnedColumnWidth: pinnedColumnWidth ?? this.pinnedColumnWidth,
      cellStyle: cellStyle ?? this.cellStyle,
      currentTimeIndicatorStyle: resolvedIndicatorStyle,
      currentTimeIndicatorWidth: resolvedIndicatorStyle.width,
      currentTimeIndicatorColor: resolvedIndicatorStyle.color,
      pinnedHeaderStyle: pinnedHeaderStyle ?? this.pinnedHeaderStyle,
      columnHeaderDecoration:
          identical(columnHeaderDecoration, _unsetDecoration)
              ? this.columnHeaderDecoration
              : columnHeaderDecoration as SpanDecoration?,
      rowHeaderDecoration: identical(rowHeaderDecoration, _unsetDecoration)
          ? this.rowHeaderDecoration
          : rowHeaderDecoration as SpanDecoration?,
      hasHeaderRowHeight: headerRowHeight != null || _hasHeaderRowHeight,
      hasRowHeight: rowHeight != null || _hasRowHeight,
      hasPinnedColumnWidth: pinnedColumnWidth != null || _hasPinnedColumnWidth,
      hasCellStyle: cellStyle != null || _hasCellStyle,
      hasCurrentTimeIndicatorStyle:
          currentTimeIndicatorStyle != null || _hasCurrentTimeIndicatorStyle,
      hasCurrentTimeIndicatorWidth:
          currentTimeIndicatorWidth != null || _hasCurrentTimeIndicatorWidth,
      hasCurrentTimeIndicatorColor:
          currentTimeIndicatorColor != null || _hasCurrentTimeIndicatorColor,
      hasPinnedHeaderStyle: pinnedHeaderStyle != null || _hasPinnedHeaderStyle,
      hasColumnHeaderDecoration:
          !identical(columnHeaderDecoration, _unsetDecoration) ||
              _hasColumnHeaderDecoration,
      hasRowHeaderDecoration:
          !identical(rowHeaderDecoration, _unsetDecoration) ||
              _hasRowHeaderDecoration,
    );
  }

  TimelineTableStyle merge(TimelineTableStyle base) {
    final baseIndicator = _applyLegacyIndicatorFields(
      base: base.currentTimeIndicatorStyle,
      widthOverride: base._hasCurrentTimeIndicatorWidth
          ? base.currentTimeIndicatorWidth
          : null,
      colorOverride: base._hasCurrentTimeIndicatorColor
          ? base.currentTimeIndicatorColor
          : null,
    );
    final overrideIndicator = _hasCurrentTimeIndicatorStyle
        ? currentTimeIndicatorStyle.merge(baseIndicator)
        : baseIndicator;
    final resolvedIndicator = _applyLegacyIndicatorFields(
      base: overrideIndicator,
      widthOverride:
          _hasCurrentTimeIndicatorWidth ? currentTimeIndicatorWidth : null,
      colorOverride:
          _hasCurrentTimeIndicatorColor ? currentTimeIndicatorColor : null,
    );

    return TimelineTableStyle._(
      headerRowHeight:
          _hasHeaderRowHeight ? headerRowHeight : base.headerRowHeight,
      rowHeight: _hasRowHeight ? rowHeight : base.rowHeight,
      pinnedColumnWidth:
          _hasPinnedColumnWidth ? pinnedColumnWidth : base.pinnedColumnWidth,
      cellStyle:
          _hasCellStyle ? cellStyle.merge(base.cellStyle) : base.cellStyle,
      currentTimeIndicatorStyle: resolvedIndicator,
      currentTimeIndicatorWidth: resolvedIndicator.width,
      currentTimeIndicatorColor: resolvedIndicator.color,
      pinnedHeaderStyle: _hasPinnedHeaderStyle
          ? pinnedHeaderStyle.merge(base.pinnedHeaderStyle)
          : base.pinnedHeaderStyle,
      columnHeaderDecoration: _hasColumnHeaderDecoration
          ? columnHeaderDecoration
          : base.columnHeaderDecoration,
      rowHeaderDecoration: _hasRowHeaderDecoration
          ? rowHeaderDecoration
          : base.rowHeaderDecoration,
      hasHeaderRowHeight: _hasHeaderRowHeight || base._hasHeaderRowHeight,
      hasRowHeight: _hasRowHeight || base._hasRowHeight,
      hasPinnedColumnWidth: _hasPinnedColumnWidth || base._hasPinnedColumnWidth,
      hasCellStyle: _hasCellStyle || base._hasCellStyle,
      hasCurrentTimeIndicatorStyle:
          _hasCurrentTimeIndicatorStyle || base._hasCurrentTimeIndicatorStyle,
      hasCurrentTimeIndicatorWidth:
          _hasCurrentTimeIndicatorWidth || base._hasCurrentTimeIndicatorWidth,
      hasCurrentTimeIndicatorColor:
          _hasCurrentTimeIndicatorColor || base._hasCurrentTimeIndicatorColor,
      hasPinnedHeaderStyle: _hasPinnedHeaderStyle || base._hasPinnedHeaderStyle,
      hasColumnHeaderDecoration:
          _hasColumnHeaderDecoration || base._hasColumnHeaderDecoration,
      hasRowHeaderDecoration:
          _hasRowHeaderDecoration || base._hasRowHeaderDecoration,
    );
  }

  static TimelineCurrentTimeIndicatorStyle _applyLegacyIndicatorFields({
    required TimelineCurrentTimeIndicatorStyle base,
    double? widthOverride,
    Color? colorOverride,
  }) {
    return base.copyWith(
      width: base._hasWidth ? null : widthOverride,
      color: base._hasColor ? null : colorOverride,
    );
  }

  @override
  List<Object?> get props => [
        headerRowHeight,
        rowHeight,
        pinnedColumnWidth,
        cellStyle,
        currentTimeIndicatorStyle,
        currentTimeIndicatorWidth,
        currentTimeIndicatorColor,
        pinnedHeaderStyle,
        columnHeaderDecoration,
        rowHeaderDecoration,
      ];
}
