import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/timeline_event.dart';
import '../theme/timeline_style.dart';
import '../types/time_state.dart';

typedef TimelineEventCellContentBuilder<TEvent extends TimelineEvent> = Widget
    Function(
  BuildContext context,
  TimelineEventCellDetails<TEvent> details,
);

/// Resolved event styling and time-state data passed to [EventCellView] builders.
class TimelineEventCellDetails<TEvent extends TimelineEvent> {
  final TEvent event;
  final DateTime now;
  final DateTime displayStart;
  final TimelineCellStyle style;
  final TimeState timeState;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;

  const TimelineEventCellDetails({
    required this.event,
    required this.now,
    required this.displayStart,
    required this.style,
    required this.timeState,
    required this.backgroundColor,
    required this.backgroundGradient,
  });

  bool get isActive => timeState.isPresent;
}

/// Package-owned helper widget for rendering a timeline event cell.
///
/// This is the default event cell used by [TimelineTable], and it can also be
/// reused inside custom `eventCellBuilder` implementations.
class EventCellView<TEvent extends TimelineEvent> extends StatefulWidget {
  final TEvent event;
  final DateTime now;
  final DateTime displayStart;
  final TimelineCellStyle style;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final TimelineEventCellContentBuilder<TEvent>? leadingBuilder;
  final TimelineEventCellContentBuilder<TEvent>? labelBuilder;
  final TimelineEventCellContentBuilder<TEvent>? trailingBuilder;
  final TimelineEventCellContentBuilder<TEvent>? childBuilder;

  const EventCellView({
    super.key,
    required this.event,
    required this.now,
    required this.displayStart,
    required this.style,
    required this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.leadingBuilder,
    this.labelBuilder,
    this.trailingBuilder,
    this.childBuilder,
  });

  @override
  State<EventCellView<TEvent>> createState() => _EventCellViewState<TEvent>();
}

class _EventCellViewState<TEvent extends TimelineEvent>
    extends State<EventCellView<TEvent>> {
  bool _isHovered = false;
  bool _isFocused = false;

  bool get _isInteractive => widget.onTap != null || widget.onLongPress != null;

  @override
  Widget build(BuildContext context) {
    final resolvedBackground = _resolveBackground(
      event: widget.event,
      now: widget.now,
      displayStart: widget.displayStart,
      style: widget.style,
    );

    final details = TimelineEventCellDetails<TEvent>(
      event: widget.event,
      now: widget.now,
      displayStart: widget.displayStart,
      style: widget.style,
      timeState: widget.event.getCurrentTimeState(widget.now),
      backgroundColor: resolvedBackground.$1,
      backgroundGradient: resolvedBackground.$2,
    );

    final borderColor = _isFocused
        ? widget.style.focusBorderColor
        : _isHovered
            ? widget.style.hoverBorderColor
            : Colors.transparent;
    final borderWidth = _isFocused
        ? widget.style.focusBorderWidth
        : (_isHovered ? widget.style.hoverBorderWidth : 0.0);

    return Semantics(
      button: _isInteractive,
      enabled: _isInteractive,
      focusable: _isInteractive,
      label: _buildSemanticsLabel(details),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            key: ValueKey('eventCellSurface_${widget.event.id}'),
            decoration: BoxDecoration(
              color: details.backgroundColor,
              gradient: details.backgroundGradient,
              borderRadius: widget.borderRadius,
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.style.hoverShadowColor,
                        blurRadius: widget.style.hoverShadowBlurRadius,
                        offset: widget.style.hoverShadowOffset,
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: widget.borderRadius,
              ),
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              onHover: _isInteractive
                  ? (value) {
                      if (_isHovered == value) return;
                      setState(() => _isHovered = value);
                    }
                  : null,
              onFocusChange: _isInteractive
                  ? (value) {
                      if (_isFocused == value) return;
                      setState(() => _isFocused = value);
                    }
                  : null,
              hoverColor: widget.style.hoverOverlayColor,
              focusColor: widget.style.focusOverlayColor,
              splashColor: widget.style.splashColor,
              highlightColor: widget.style.highlightColor,
              canRequestFocus: _isInteractive,
              child: Padding(
                padding: widget.padding,
                child: widget.childBuilder != null
                    ? widget.childBuilder!(context, details)
                    : _buildDefaultContent(context, details),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultContent(
      BuildContext context, TimelineEventCellDetails<TEvent> details) {
    final children = <Widget>[];

    if (widget.leadingBuilder != null) {
      children.add(widget.leadingBuilder!(context, details));
    }

    if (widget.labelBuilder != null) {
      children.add(widget.labelBuilder!(context, details));
    } else if (widget.event.label.isNotEmpty) {
      children.add(
        Expanded(
          child: Text(
            widget.event.label,
            style: widget.style.labelStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (widget.trailingBuilder != null) {
      children.add(
        Flexible(
          fit: FlexFit.loose,
          child: widget.trailingBuilder!(context, details),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }

  String _buildSemanticsLabel(TimelineEventCellDetails<TEvent> details) {
    final formatter = DateFormat('MMM d, yyyy HH:mm');
    final status = switch (details.timeState) {
      TimeState.past => 'completed',
      TimeState.present => 'active now',
      TimeState.future => 'upcoming',
    };
    final start = formatter.format(widget.event.startTime.toLocal());
    final end = formatter.format(widget.event.endTime.toLocal());
    return '${widget.event.label}, $status, $start to $end';
  }

  static (Color?, Gradient?) _resolveBackground<TEvent extends TimelineEvent>({
    required TEvent event,
    required DateTime now,
    required DateTime displayStart,
    required TimelineCellStyle style,
  }) {
    Color? eventBgColor;
    Gradient? eventBgGradient;
    var background = style.eventCellBackground;
    final timeState = event.getCurrentTimeState(now);

    if (timeState.isFuture) {
      eventBgColor = background.future;
    } else if (timeState.isPast) {
      eventBgColor = background.past;
    } else {
      background = style.activeEventCellBackground;
      if (background.past == background.future) {
        eventBgColor = background.past;
      } else {
        final totalMs = event.endTime.difference(displayStart).inMilliseconds;
        final elapsedMs = now.difference(displayStart).inMilliseconds;
        final elapsedFraction = elapsedMs / totalMs;
        final stop1 = elapsedFraction;
        final stop2 = (elapsedFraction + 0.001).clamp(0.0, 1.0);
        eventBgGradient = LinearGradient(
          colors: [background.past, background.future],
          stops: [stop1, stop2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      }
    }

    return (eventBgColor, eventBgGradient);
  }
}
