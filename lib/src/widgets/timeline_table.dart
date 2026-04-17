import 'dart:async';
import 'dart:math' show max, min;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show SchedulerPhase;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../models/timeline_config.dart';
import '../models/timeline_data.dart';
import '../models/timeline_event.dart';
import '../models/timeline_row.dart';
import '../theme/timeline_style.dart';
import '../types/time_state.dart';
import 'event_cell_view.dart';
import 'painters/cell_background_painter.dart';
import 'painters/event_cell_gridline_painter.dart';
import 'painters/gridline_painter.dart';

/// Default time source used by [TimelineTable.nowBuilder].
DateTime timelineSystemNow() => DateTime.now().toUtc();

/// Provides the current time used by the timeline.
typedef TimelineNowBuilder = DateTime Function();
typedef TimelineEventWidgetBuilder<TEvent extends TimelineEvent,
        TRow extends TimelineRow<TEvent>>
    = Widget Function(
  BuildContext context,
  TimelineEventBuildDetails<TEvent, TRow> details,
);
typedef TimelineGroupHeaderBuilder<TEvent extends TimelineEvent,
        TRow extends TimelineRow<TEvent>>
    = Widget Function(
  BuildContext context,
  TimelineGroupHeaderDetails<TEvent, TRow> details,
);
typedef TimelineRowHeaderBuilder<TEvent extends TimelineEvent,
        TRow extends TimelineRow<TEvent>>
    = Widget Function(
  BuildContext context,
  TimelineRowHeaderDetails<TEvent, TRow> details,
);
typedef TimelinePinnedHeaderBuilder<TEvent extends TimelineEvent,
        TRow extends TimelineRow<TEvent>>
    = Widget Function(
  BuildContext context,
  TimelinePinnedHeaderDetails<TEvent, TRow> details,
);
typedef TimelineRangeExtendedCallback = FutureOr<void> Function(
  DateTime newStart,
  DateTime newEnd,
  Duration delta,
  bool toLeft,
);
typedef EventLifecycleCallback<T extends TimelineEvent> = void Function(
  T event,
  bool isActive,
);

/// Called when a table-level event interaction is triggered.
typedef TimelineEventInteractionCallback<TEvent extends TimelineEvent,
        TRow extends TimelineRow<TEvent>>
    = void Function(
  TimelineEventInteractionDetails<TEvent, TRow> details,
);

/// Controls how [TimelineTable.onEventLifecycle] behaves for repeated
/// activations of the same event id.
enum TimelineLifecyclePolicy {
  /// Fires on every enter transition and every leave transition.
  everyTransition,

  /// Fires the enter transition only once per event id for the current data
  /// snapshot, while leave transitions still fire when the event exits.
  firstActivationOnly,
}

/// Preferred match selection used by [TimelineTableController.scrollToEventByPartialId].
enum FML {
  /// Select the first matching event in the first matching row.
  first,

  /// Select the middle matching event in the first matching row.
  middle,

  /// Select the last matching event in the first matching row.
  last,
}

class _TimelineHorizontalStepIntent extends Intent {
  final int direction;

  const _TimelineHorizontalStepIntent(this.direction);
}

class _TimelineVerticalStepIntent extends Intent {
  final int direction;

  const _TimelineVerticalStepIntent(this.direction);
}

class _TimelineHomeIntent extends Intent {
  const _TimelineHomeIntent();
}

class TimelineViewState<TEvent extends TimelineEvent,
    TRow extends TimelineRow<TEvent>> {
  final TimelineConfig config;
  final List<TRow> rows;
  final DateTime now;
  final bool autoScrollEnabled;
  final Set<String> activeEventIds;
  final bool currentTimeInRange;

  const TimelineViewState({
    required this.config,
    required this.rows,
    required this.now,
    required this.autoScrollEnabled,
    required this.activeEventIds,
    required this.currentTimeInRange,
  });

  bool isEventActive(String eventId) => activeEventIds.contains(eventId);
}

/// Context passed to the pinned-column header builder.
class TimelinePinnedHeaderDetails<TEvent extends TimelineEvent,
    TRow extends TimelineRow<TEvent>> {
  final TimelineViewState<TEvent, TRow> state;
  final TimelineTableController<TEvent, TRow>? controller;

  const TimelinePinnedHeaderDetails({
    required this.state,
    required this.controller,
  });
}

/// Context passed to the row-header builder.
class TimelineRowHeaderDetails<TEvent extends TimelineEvent,
    TRow extends TimelineRow<TEvent>> {
  final TRow? row;
  final TimelineViewState<TEvent, TRow> state;
  final TimelineTableController<TEvent, TRow>? controller;

  const TimelineRowHeaderDetails({
    required this.row,
    required this.state,
    required this.controller,
  });
}

/// Context passed to the grouped row-header builder.
class TimelineGroupHeaderDetails<TEvent extends TimelineEvent,
    TRow extends TimelineRow<TEvent>> {
  final List<TRow> rows;
  final TimelineViewState<TEvent, TRow> state;
  final TimelineTableController<TEvent, TRow>? controller;

  const TimelineGroupHeaderDetails({
    required this.rows,
    required this.state,
    required this.controller,
  });
}

/// Context passed to `eventCellBuilder`.
///
/// If you provide a custom event cell and want table-level `onEventTap` or
/// `onEventLongPress` handlers to continue working, forward [handleTap] and
/// [handleLongPress] into your custom widget.
class TimelineEventBuildDetails<TEvent extends TimelineEvent,
    TRow extends TimelineRow<TEvent>> {
  final TEvent event;
  final TRow row;
  final DateTime now;
  final DateTime displayStart;
  final bool isActive;
  final TimelineCellStyle defaultCellStyle;
  final TimelineViewState<TEvent, TRow> state;
  final TimelineTableController<TEvent, TRow>? controller;
  final VoidCallback? handleTap;
  final VoidCallback? handleLongPress;

  const TimelineEventBuildDetails({
    required this.event,
    required this.row,
    required this.now,
    required this.displayStart,
    required this.isActive,
    required this.defaultCellStyle,
    required this.state,
    required this.controller,
    required this.handleTap,
    required this.handleLongPress,
  });

  String get rowId => row.id;
}

/// Payload delivered to table-level event interaction callbacks.
class TimelineEventInteractionDetails<TEvent extends TimelineEvent,
    TRow extends TimelineRow<TEvent>> {
  final TEvent event;
  final TRow row;
  final DateTime displayStart;
  final DateTime now;
  final bool isActive;
  final TimelineViewState<TEvent, TRow> state;
  final TimelineTableController<TEvent, TRow>? controller;

  const TimelineEventInteractionDetails({
    required this.event,
    required this.row,
    required this.displayStart,
    required this.now,
    required this.isActive,
    required this.state,
    required this.controller,
  });
}

/// Imperative and observable controller for a [TimelineTable].
///
/// Prefer observing it through [ChangeNotifier] and [viewState].
///
/// [ready] completes after the initial timeline layout and jump have finished,
/// which is useful for imperative actions that require active scroll metrics.
class TimelineTableController<TEvent extends TimelineEvent,
    TRow extends TimelineRow<TEvent>> extends ChangeNotifier {
  _TimelineTableState<TEvent, TRow>? _state;
  Completer<void> _readyCompleter = Completer<void>();
  bool _ready = false;
  bool _notificationScheduled = false;
  bool _disposed = false;

  bool get attached => _state != null;
  bool get isReady => _ready;
  Future<void> get ready => _readyCompleter.future;
  TimelineViewState<TEvent, TRow>? get viewState => _state?._snapshot();
  Set<String>? get activeEventIds => viewState?.activeEventIds;
  bool get autoScrollEnabled => viewState?.autoScrollEnabled ?? false;

  Future<bool> scrollToEvent(TEvent? event) =>
      _state?._scrollToEvent(event) ?? Future.value(false);
  Future<bool> scrollToEventById(String id) =>
      _state?._scrollToEventById(id) ?? Future.value(false);

  Future<bool> scrollToEventByPartialId(String id,
      {FML preferredPosition = FML.middle}) {
    return _state?._scrollToEventByPartialId(id,
            preferredPosition: preferredPosition) ??
        Future.value(false);
  }

  void scrollToNow() => _state?.scrollToCurrentTime();
  void enableAutoScroll([bool enable = true]) =>
      _state?._setAutoScrollEnabled(enable);
  void updateData(TimelineData<TEvent, TRow> data, {bool force = false}) =>
      _state?._updateData(data, force: force);
  TRow? getRowForEvent(String eventId) => _state?._rowForEventId[eventId];

  void _attach(_TimelineTableState<TEvent, TRow> state) {
    if (identical(_state, state)) return;
    _state = state;
    if (state._didInitialJump) {
      _markReady();
      return;
    }
    _dispatchListeners();
  }

  void _detach(_TimelineTableState<TEvent, TRow> state) {
    if (!identical(_state, state)) return;
    _state = null;
    _ready = false;
    if (_readyCompleter.isCompleted) {
      _readyCompleter = Completer<void>();
    }
    _dispatchListeners();
  }

  void _markReady() {
    if (_ready) return;
    _ready = true;
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
    _dispatchListeners();
  }

  void _notifyStateChanged() {
    if (_state == null) return;
    _dispatchListeners();
  }

  void _dispatchListeners() {
    if (_disposed) return;

    final schedulerPhase = WidgetsBinding.instance.schedulerPhase;
    if (schedulerPhase != SchedulerPhase.persistentCallbacks) {
      notifyListeners();
      return;
    }

    if (_notificationScheduled) return;
    _notificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationScheduled = false;
      if (_disposed) return;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _notificationScheduled = false;
    super.dispose();
  }
}

/// A virtualized, horizontally scrollable timeline table.
class TimelineTable<TEvent extends TimelineEvent,
    TRow extends TimelineRow<TEvent>> extends StatefulWidget {
  final TimelineData<TEvent, TRow> data;
  final TimelineConfig config;
  final Size? size;
  final TimelineTableController<TEvent, TRow>? controller;
  final bool enableInfiniteScroll;
  final bool enableCurrentTimeIndicator;
  final Duration indicatorUpdateInterval;
  final Duration autoScrollEnableDelay;
  final Duration extensionChunk;
  final double extensionThresholdPx;
  final TimelineRowHeaderBuilder<TEvent, TRow>? rowHeaderBuilder;
  final TimelineGroupHeaderBuilder<TEvent, TRow>? groupHeaderBuilder;
  final TimelineEventWidgetBuilder<TEvent, TRow>? eventCellBuilder;
  final TimelinePinnedHeaderBuilder<TEvent, TRow>? pinnedColumnHeaderBuilder;
  final TimelineTableStyle? style;
  final ScrollBehavior? scrollBehavior;
  final FocusNode? focusNode;
  final bool autofocus;
  final TimelineRangeExtendedCallback? onTimelineRangeExtended;
  final EventLifecycleCallback<TEvent>? onEventLifecycle;
  final TimelineLifecyclePolicy lifecyclePolicy;
  final TimelineEventInteractionCallback<TEvent, TRow>? onEventTap;
  final TimelineEventInteractionCallback<TEvent, TRow>? onEventLongPress;
  final TimelineNowBuilder nowBuilder;

  const TimelineTable({
    super.key,
    required this.data,
    required this.config,
    this.size,
    this.controller,
    this.enableInfiniteScroll = false,
    this.enableCurrentTimeIndicator = true,
    this.indicatorUpdateInterval = const Duration(seconds: 5),
    this.autoScrollEnableDelay = const Duration(minutes: 1),
    this.extensionChunk = const Duration(hours: 12),
    this.extensionThresholdPx = 800,
    this.rowHeaderBuilder,
    this.groupHeaderBuilder,
    this.eventCellBuilder,
    this.pinnedColumnHeaderBuilder,
    this.style,
    this.scrollBehavior,
    this.focusNode,
    this.autofocus = false,
    this.onTimelineRangeExtended,
    this.onEventLifecycle,
    this.lifecyclePolicy = TimelineLifecyclePolicy.everyTransition,
    this.onEventTap,
    this.onEventLongPress,
    this.nowBuilder = timelineSystemNow,
  });

  @override
  State<TimelineTable<TEvent, TRow>> createState() =>
      _TimelineTableState<TEvent, TRow>();
}

class _TimelineTableState<TEvent extends TimelineEvent,
        TRow extends TimelineRow<TEvent>>
    extends State<TimelineTable<TEvent, TRow>> {
  static const int _kPinnedColumnIndex = 0;
  static const int _kHeaderRowIndex = 0;

  late TimelineConfig _config;
  late List<TRow> _rows;
  late List<TEvent> _allEvents;
  late Map<String, List<TEvent>> _sortedEventsByRowId;
  late Map<String, ({int start, int count})> _groupInfoById;
  late Map<String, TRow> _rowForEventId;
  late Map<String, int> _rowIndexByEventId;

  late int _eventStepMs;
  late int _displayedStepMs;
  late int _gridStepFactor;
  late int _timeHeaderStepMs;
  late int _timeHeaderDisplayFactor;
  late int _underlyingColumnCount;

  late double _pixelsPerStep;
  Size? _resolvedSize;
  double _containerWidth = 0;
  double _scrollWindowWidth = 0;
  double _scrollCentre = 0;
  double _bottomSpacerHeight = 0;

  late final ScrollController _hController;
  late final ScrollController _vController;

  late TimelineTableStyle _style;
  late DateFormat _timeHeaderFormat;
  late EdgeInsets _eventMargin;

  bool _autoScrollEnabled = true;
  late DateTime _playheadTime;
  double _timelineIndicatorPosition = -1;
  bool _didInitialJump = false;

  late final Duration _extensionChunk;
  late final double _extensionThresholdPx;

  Timer? _indicatorTimer;
  Timer? _autoScrollEnableTimer;

  final Set<String> _everActivated = {};
  final Set<String> _currentlyLive = {};
  bool _showFocusHighlight = false;
  bool _edgeRangeExtensionScheduled = false;

  @override
  void initState() {
    super.initState();
    _extensionChunk = widget.extensionChunk;
    _extensionThresholdPx = widget.extensionThresholdPx;
    _hController = ScrollController();
    _vController = ScrollController();
    _style = const TimelineTableStyle();
    _eventMargin = EdgeInsets.symmetric(
      horizontal: _style.cellStyle.horizontalEventMargin,
      vertical: _style.cellStyle.verticalEventMargin,
    );
    _initFromData(widget.data);
    _playheadTime = _currentNow();
    _resetLifecycleTracking();
    _checkEventLifecycle(_playheadTime);
    widget.controller?._attach(this);

    if (widget.enableCurrentTimeIndicator) {
      _hController.addListener(_onScroll);
      _scheduleIndicatorUpdates();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshResolvedStyle();
  }

  @override
  void didUpdateWidget(covariant TimelineTable<TEvent, TRow> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }

    if (widget.data != oldWidget.data || widget.config != oldWidget.config) {
      _updateData(widget.data, force: true);
    }

    if (widget.style != oldWidget.style) {
      _refreshResolvedStyle();
    }

    if (widget.enableCurrentTimeIndicator !=
        oldWidget.enableCurrentTimeIndicator) {
      if (widget.enableCurrentTimeIndicator) {
        _hController.addListener(_onScroll);
        _scheduleIndicatorUpdates();
      } else {
        _hController.removeListener(_onScroll);
        _indicatorTimer?.cancel();
        if (_timelineIndicatorPosition != -1) {
          setState(() => _timelineIndicatorPosition = -1);
        }
      }
    }

    if (widget.indicatorUpdateInterval != oldWidget.indicatorUpdateInterval ||
        widget.nowBuilder != oldWidget.nowBuilder) {
      _indicatorTimer?.cancel();
      if (widget.enableCurrentTimeIndicator) {
        _scheduleIndicatorUpdates();
      }
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _hController
      ..removeListener(_onScroll)
      ..dispose();
    _vController.dispose();
    _indicatorTimer?.cancel();
    _autoScrollEnableTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      descendantsAreFocusable: false,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowLeft):
            _TimelineHorizontalStepIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowRight):
            _TimelineHorizontalStepIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowUp):
            _TimelineVerticalStepIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowDown):
            _TimelineVerticalStepIntent(1),
        SingleActivator(LogicalKeyboardKey.home): _TimelineHomeIntent(),
      },
      actions: <Type, Action<Intent>>{
        _TimelineHorizontalStepIntent:
            CallbackAction<_TimelineHorizontalStepIntent>(
          onInvoke: (intent) {
            _handleKeyboardHorizontalStep(intent.direction);
            return null;
          },
        ),
        _TimelineVerticalStepIntent:
            CallbackAction<_TimelineVerticalStepIntent>(
          onInvoke: (intent) {
            _handleKeyboardVerticalStep(intent.direction);
            return null;
          },
        ),
        _TimelineHomeIntent: CallbackAction<_TimelineHomeIntent>(
          onInvoke: (intent) {
            _handleKeyboardHome();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (value) {
        if (_showFocusHighlight == value) return;
        setState(() => _showFocusHighlight = value);
      },
      child: Semantics(
        container: true,
        focusable: true,
        label: 'Timeline table',
        hint: 'Drag to scroll. Use arrow keys to pan and Home to jump.',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final resolvedSize = _resolveSize(constraints);
            _applyViewportSize(resolvedSize);
            final localScrollBehavior = _resolveScrollBehavior(context);

            return SizedBox(
              width: resolvedSize.width,
              height: resolvedSize.height,
              child: Stack(
                children: [
                  ScrollConfiguration(
                    behavior: localScrollBehavior,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _handleUserScroll,
                        child: TableView.builder(
                          horizontalDetails: ScrollableDetails.horizontal(
                              controller: _hController),
                          verticalDetails: ScrollableDetails.vertical(
                              controller: _vController),
                          columnCount: 1 + _underlyingColumnCount,
                          pinnedColumnCount: 1,
                          pinnedRowCount: 1,
                          rowCount: 1 + _rows.length + 1,
                          cellBuilder: _buildCell,
                          columnBuilder: _buildColumnSpan,
                          rowBuilder: _buildRowSpan,
                        ),
                      ),
                    ),
                  ),
                  if (_showFocusHighlight)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (widget.enableCurrentTimeIndicator &&
                      _isTimeInRange(_playheadTime) &&
                      _timelineIndicatorPosition > 0 &&
                      _timelineIndicatorPosition < _scrollWindowWidth)
                    _buildCurrentTimeIndicator(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  TimelineViewState<TEvent, TRow> _snapshot() {
    return TimelineViewState<TEvent, TRow>(
      config: _config,
      rows: _rows,
      now: _playheadTime,
      autoScrollEnabled: _autoScrollEnabled,
      activeEventIds: Set.unmodifiable(Set<String>.from(_currentlyLive)),
      currentTimeInRange: _isTimeInRange(_playheadTime),
    );
  }

  void _notifyControllerStateChanged() {
    widget.controller?._notifyStateChanged();
  }

  DateTime _currentNow() => widget.nowBuilder().toUtc();

  ScrollBehavior _resolveScrollBehavior(BuildContext context) {
    final baseBehavior =
        widget.scrollBehavior ?? ScrollConfiguration.of(context);
    return baseBehavior.copyWith(
      dragDevices: <PointerDeviceKind>{
        ...baseBehavior.dragDevices,
        PointerDeviceKind.mouse,
      },
    );
  }

  Size _resolveSize(BoxConstraints constraints) {
    final width = widget.size?.width ??
        (constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity);
    final height = widget.size?.height ??
        (constraints.hasBoundedHeight
            ? constraints.maxHeight
            : double.infinity);

    assert(width.isFinite && width > 0,
        'TimelineTable requires a bounded width or an explicit size.');
    assert(height.isFinite && height > 0,
        'TimelineTable requires a bounded height or an explicit size.');

    return Size(width, height);
  }

  void _applyViewportSize(Size size) {
    if (_resolvedSize == size) return;
    _resolvedSize = size;
    _containerWidth = size.width;
    _scrollWindowWidth = max(0, _containerWidth - _style.pinnedColumnWidth);
    _scrollCentre = _scrollWindowWidth / 2;
    _recomputeBottomSpacer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_didInitialJump) {
        _initialJump();
      } else if (_hController.hasClients) {
        final pos = _getCurrentTimeOffset();
        if (_timelineIndicatorPosition != pos) {
          setState(() => _timelineIndicatorPosition = pos);
        }
      }
    });
  }

  void _initFromData(TimelineData<TEvent, TRow> data) {
    _config = widget.config;
    _rows = data.rows;
    _timeHeaderFormat = DateFormat(_config.headerTimeFormat);

    _allEvents = <TEvent>[];
    _sortedEventsByRowId = <String, List<TEvent>>{};
    _groupInfoById = <String, ({int start, int count})>{};
    _rowForEventId = <String, TRow>{};
    _rowIndexByEventId = <String, int>{};

    for (var rowIndex = 0; rowIndex < _rows.length; rowIndex++) {
      final row = _rows[rowIndex];
      assert(() {
        _debugValidateRow(row);
        return true;
      }());
      final sortedEvents = row.events
          .sorted((a, b) => a.startTime.compareTo(b.startTime))
          .toList(growable: false);
      _sortedEventsByRowId[row.id] = sortedEvents;
      final groupId = row.groupId;
      if (groupId != null) {
        final existing = _groupInfoById[groupId];
        _groupInfoById[groupId] = existing == null
            ? (start: rowIndex + 1, count: 1)
            : (start: existing.start, count: existing.count + 1);
      }

      for (final event in sortedEvents) {
        _allEvents.add(event);
        _rowForEventId[event.id] = row;
        _rowIndexByEventId[event.id] = rowIndex;
      }
    }

    _allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    _recomputeLayoutUnits();
    _ensureNowBracketsRange();
    if (_resolvedSize != null) {
      _applyViewportSize(_resolvedSize!);
    }
  }

  void _refreshResolvedStyle() {
    final themeStyle =
        TimelineTheme.of(context).merge(const TimelineTableStyle());
    final widgetStyle = widget.style ?? const TimelineTableStyle();
    _style = widgetStyle.merge(themeStyle);
    _eventMargin = EdgeInsets.symmetric(
      horizontal: _style.cellStyle.horizontalEventMargin,
      vertical: _style.cellStyle.verticalEventMargin,
    );
    if (_resolvedSize != null) {
      _applyViewportSize(_resolvedSize!);
    }
  }

  void _resetLifecycleTracking() {
    _everActivated.clear();
    _currentlyLive.clear();
  }

  void _updateData(TimelineData<TEvent, TRow> newData, {bool force = false}) {
    final changed = !identical(newData, widget.data);
    if (force || changed) {
      setState(() {
        _initFromData(newData);
        _resetLifecycleTracking();
        _checkEventLifecycle(_playheadTime);
      });
      _notifyControllerStateChanged();
    }
  }

  Duration _computeInitialDelay(Duration interval) {
    final now = _currentNow();
    final ms = interval.inMilliseconds;
    final rem = now.millisecondsSinceEpoch % ms;
    return Duration(milliseconds: (ms - rem) % ms);
  }

  void _scheduleIndicatorUpdates() {
    _indicatorTimer?.cancel();
    final interval = widget.indicatorUpdateInterval;
    final initialDelay = _computeInitialDelay(interval);
    _indicatorTimer = Timer(initialDelay, () {
      _onTick();
      _indicatorTimer = Timer.periodic(interval, (_) => _onTick());
    });
  }

  void _initialJump() {
    if (_resolvedSize == null || _scrollWindowWidth <= 0) return;

    if (_hController.hasClients) {
      final initialOffset =
          (_calculateTimeOffset(_playheadTime) - _scrollCentre).clamp(
        _hController.position.minScrollExtent,
        _hController.position.maxScrollExtent,
      );
      _hController.jumpTo(initialOffset.toDouble());
    }

    final pos = _getCurrentTimeOffset();
    if (_timelineIndicatorPosition != pos) {
      setState(() => _timelineIndicatorPosition = pos);
    }
    _didInitialJump = true;
    widget.controller?._markReady();
  }

  void _onTick() {
    if (!mounted) return;
    final nowUtc = _currentNow();
    _playheadTime = nowUtc;
    final lifecycleChanged = _checkEventLifecycle(nowUtc);

    final pos = _getCurrentTimeOffset();
    if (_timelineIndicatorPosition != pos) {
      setState(() => _timelineIndicatorPosition = pos);
    }

    if (_autoScrollEnabled && _didInitialJump && _hController.hasClients) {
      scrollToCurrentTime();
    }

    if (lifecycleChanged || widget.controller != null) {
      _notifyControllerStateChanged();
    }
  }

  void _onScroll() {
    final pos = _getCurrentTimeOffset();
    if (_timelineIndicatorPosition != pos) {
      setState(() => _timelineIndicatorPosition = pos);
    }
    if (widget.enableInfiniteScroll) _maybeExtendRange();
  }

  bool _handleUserScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.horizontal) {
      _maybeExtendRange();
      if (notification is UserScrollNotification &&
          notification.direction != ScrollDirection.idle) {
        _disableAutoScrollTemporarily();
      }
    }
    return false;
  }

  void _setAutoScrollEnabled(bool enable) {
    if (_autoScrollEnabled == enable) return;
    setState(() => _autoScrollEnabled = enable);
    _notifyControllerStateChanged();
  }

  void _disableAutoScrollTemporarily() {
    _setAutoScrollEnabled(false);
    _autoScrollEnableTimer?.cancel();
    _autoScrollEnableTimer = Timer(widget.autoScrollEnableDelay, () {
      if (mounted) {
        _setAutoScrollEnabled(true);
      }
    });
  }

  void _handleKeyboardHorizontalStep(int direction) {
    if (!_hController.hasClients) return;
    _disableAutoScrollTemporarily();
    final delta = direction * _pixelsPerStep * _gridStepFactor;
    _animateHorizontalTo(_hController.offset + delta);
  }

  void _handleKeyboardVerticalStep(int direction) {
    if (!_vController.hasClients) return;
    final delta = direction * _style.rowHeight;
    _animateVerticalTo(_vController.offset + delta);
  }

  void _handleKeyboardHome() {
    if (_isTimeInRange(_playheadTime)) {
      scrollToCurrentTime();
      return;
    }
    if (!_hController.hasClients) return;
    _disableAutoScrollTemporarily();
    _animateHorizontalTo(_hController.position.minScrollExtent);
  }

  void _animateHorizontalTo(double target) {
    if (!_hController.hasClients) return;
    final clamped = target
        .clamp(
          _hController.position.minScrollExtent,
          _hController.position.maxScrollExtent,
        )
        .toDouble();
    if ((_hController.offset - clamped).abs() < 0.5) return;
    _hController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  void _animateVerticalTo(double target) {
    if (!_vController.hasClients) return;
    final clamped = target
        .clamp(
          _vController.position.minScrollExtent,
          _vController.position.maxScrollExtent,
        )
        .toDouble();
    if ((_vController.offset - clamped).abs() < 0.5) return;
    _vController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  void _maybeExtendRange() {
    if (!widget.enableInfiniteScroll || !_hController.hasClients) return;
    final position = _hController.position;
    final maxExtent = position.maxScrollExtent;
    final minExtent = position.minScrollExtent;
    final scrollableExtent = maxExtent - minExtent;
    if (scrollableExtent <= 0 || _edgeRangeExtensionScheduled) return;

    final effectiveThreshold =
        min(_extensionThresholdPx, scrollableExtent / 2).toDouble();
    if (effectiveThreshold <= 0) return;

    final offset = _hController.offset;
    final distanceToStart = offset - minExtent;
    final distanceToEnd = maxExtent - offset;
    if (distanceToStart < effectiveThreshold) {
      _lockEdgeRangeExtensionForFrame();
      _extendLeft(_extensionChunk);
    } else if (distanceToEnd < effectiveThreshold) {
      _lockEdgeRangeExtensionForFrame();
      _extendRight(_extensionChunk);
    }
  }

  void _lockEdgeRangeExtensionForFrame() {
    _edgeRangeExtensionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _edgeRangeExtensionScheduled = false;
    });
  }

  void _extendLeft(Duration duration) {
    final steps = (duration.inMilliseconds / _eventStepMs).ceil();
    final shiftPx = steps * _pixelsPerStep;
    setState(() {
      _config =
          _config.copyWith(startTime: _config.startTime.subtract(duration));
      _recomputeLayoutUnits();
    });
    _notifyControllerStateChanged();
    widget.onTimelineRangeExtended
        ?.call(_config.startTime, _config.endTime, duration, true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hController.hasClients) {
        _hController.jumpTo(_hController.offset + shiftPx);
      }
    });
  }

  void _extendRight(Duration duration) {
    setState(() {
      _config = _config.copyWith(endTime: _config.endTime.add(duration));
      _recomputeLayoutUnits();
    });
    _notifyControllerStateChanged();
    widget.onTimelineRangeExtended
        ?.call(_config.startTime, _config.endTime, duration, false);
  }

  bool _checkEventLifecycle(DateTime nowUtc) {
    final callback = widget.onEventLifecycle;
    final nextLive = <String>{};
    final previousLive = Set<String>.from(_currentlyLive);

    for (final event in _allEvents) {
      if (event.startTime.isAfter(nowUtc)) break;
      if (!event.endTime.isAfter(nowUtc)) continue;

      nextLive.add(event.id);
      if (previousLive.contains(event.id)) {
        _everActivated.add(event.id);
        continue;
      }

      final shouldNotifyEnter = switch (widget.lifecyclePolicy) {
        TimelineLifecyclePolicy.everyTransition => true,
        TimelineLifecyclePolicy.firstActivationOnly =>
          _everActivated.add(event.id),
      };
      _everActivated.add(event.id);
      if (shouldNotifyEnter) {
        callback?.call(event, true);
      }
    }

    for (final eventId in previousLive.difference(nextLive)) {
      final event =
          _allEvents.firstWhereOrNull((candidate) => candidate.id == eventId);
      if (event != null) {
        callback?.call(event, false);
      }
    }

    if (setEquals(_currentlyLive, nextLive)) {
      return false;
    }

    _currentlyLive
      ..clear()
      ..addAll(nextLive);
    return true;
  }

  void scrollToCurrentTime() {
    if (!_isTimeInRange(_playheadTime) || !_hController.hasClients) return;
    if (!_autoScrollEnabled) {
      _setAutoScrollEnabled(true);
    }

    final offset = _calculateTimeOffset(_playheadTime);
    final target = (offset - _scrollCentre).clamp(
      _hController.position.minScrollExtent,
      _hController.position.maxScrollExtent,
    );
    if (_hController.offset == target || !mounted) return;

    _hController.animateTo(
      target,
      duration: const Duration(milliseconds: 700),
      curve: Curves.decelerate,
    );
  }

  Future<bool> _scrollToEvent(TEvent? event) async {
    if (event == null) return false;

    final rowIdx = _rowIndexByEventId[event.id];
    if (rowIdx == null) return false;

    if (!_isTimeInRange(event.startTime)) {
      if (!widget.enableInfiniteScroll) return false;
      while (event.startTime.isBefore(_config.startTime)) {
        _extendLeft(_extensionChunk);
      }
      while (event.startTime.isAfter(_config.endTime)) {
        _extendRight(_extensionChunk);
      }
    }

    final targetH =
        (_calculateTimeOffset(event.startTime) - _scrollCentre).clamp(
      _hController.position.minScrollExtent,
      _hController.position.maxScrollExtent,
    );

    var needV = false;
    var targetV = 0.0;
    if (_vController.hasClients) {
      final vp = _vController.position.viewportDimension;
      final off = _vController.offset;
      final rowH = _style.rowHeight;
      final first = (off / rowH).floor();
      final last = ((off + vp) / rowH).floor();
      if (rowIdx < first || rowIdx > last) {
        needV = true;
        targetV = rowIdx * rowH;
      }
    } else {
      needV = true;
      targetV = rowIdx * _style.rowHeight;
    }

    if (mounted) {
      _disableAutoScrollTemporarily();
      final futures = <Future<void>>[
        _hController.animateTo(
          targetH,
          duration: const Duration(milliseconds: 700),
          curve: Curves.decelerate,
        ),
      ];
      if (needV) {
        futures.add(
          _vController.animateTo(
            targetV,
            duration: const Duration(milliseconds: 500),
            curve: Curves.decelerate,
          ),
        );
      }
      await Future.wait(futures);
    }

    return true;
  }

  Future<bool> _scrollToEventById(String id) {
    final row = _rowForEventId[id];
    final event = row == null
        ? null
        : _eventsForRow(row)
            .firstWhereOrNull((candidate) => candidate.id == id);
    return _scrollToEvent(event);
  }

  Future<bool> _scrollToEventByPartialId(String search,
      {FML preferredPosition = FML.middle}) {
    for (final row in _rows) {
      final matches = _eventsForRow(row)
          .where((event) => event.id.contains(search))
          .toList(growable: false);
      if (matches.isNotEmpty) {
        final TEvent? match = switch (preferredPosition) {
          FML.first => matches.first,
          FML.middle =>
            matches.elementAtOrNull((matches.length / 2.0).ceil() - 1),
          FML.last => matches.last,
        };
        if (match != null) return _scrollToEvent(match);
      }
    }
    return _scrollToEvent(null);
  }

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
    return vicinity.row == _kHeaderRowIndex
        ? _buildHeaderCell(context, vicinity)
        : _buildDataCell(context, vicinity);
  }

  TableSpan _buildColumnSpan(int index) {
    final extent = index == _kPinnedColumnIndex
        ? _style.pinnedColumnWidth
        : _pixelsPerStep;
    return TableSpan(
      extent: FixedTableSpanExtent(extent),
      backgroundDecoration:
          index == _kPinnedColumnIndex ? _style.columnHeaderDecoration : null,
    );
  }

  TableSpan _buildRowSpan(int index) {
    if (index == _kHeaderRowIndex) {
      return TableSpan(
        extent: FixedTableSpanExtent(_style.headerRowHeight),
        backgroundDecoration: _style.rowHeaderDecoration,
      );
    }
    if (index == _rows.length + 1) {
      return TableSpan(extent: FixedTableSpanExtent(_bottomSpacerHeight));
    }
    return TableSpan(extent: FixedTableSpanExtent(_style.rowHeight));
  }

  TableViewCell _buildHeaderCell(BuildContext context, TableVicinity vicinity) {
    if (vicinity.column == _kPinnedColumnIndex) {
      final active = _isTimeInRange(_playheadTime);
      final details = TimelinePinnedHeaderDetails<TEvent, TRow>(
        state: _snapshot(),
        controller: widget.controller,
      );
      return TableViewCell(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _style.rowHeaderDecoration?.border?.trailing.color ??
                    _style.pinnedHeaderStyle.dividerColor,
              ),
            ),
          ),
          child: widget.pinnedColumnHeaderBuilder != null
              ? widget.pinnedColumnHeaderBuilder!(context, details)
              : Center(
                  child: Semantics(
                    header: true,
                    label: 'Timeline controls',
                    child: (widget.enableCurrentTimeIndicator && active)
                        ? IconButton(
                            icon: const Icon(Icons.timer),
                            iconSize: _style.headerRowHeight / 2,
                            color: _autoScrollEnabled
                                ? _style.pinnedHeaderStyle.activeIconColor
                                : _style.pinnedHeaderStyle.inactiveIconColor,
                            onPressed: scrollToCurrentTime,
                          )
                        : Text(
                            'Time',
                            style: _style.pinnedHeaderStyle.labelStyle,
                          ),
                  ),
                ),
        ),
      );
    }

    final underlyingIndex = vicinity.column - 1;
    final firstVis = _hController.hasClients
        ? (_hController.offset / _pixelsPerStep).floor()
        : 0;
    final headerData = _getHeaderCellData(underlyingIndex, firstVis);
    if (headerData == null) {
      return const TableViewCell(child: SizedBox.shrink());
    }

    final (timeLabel, rawSpan) = headerData;
    final maxSpan = (1 + _underlyingColumnCount) - vicinity.column;
    final span = min(rawSpan, maxSpan);
    final cellWidth = _timeHeaderDisplayFactor *
        (_timeHeaderStepMs / _displayedStepMs) *
        _pixelsPerStep;
    final label = _timeHeaderFormat.format(timeLabel.toLocal());

    return TableViewCell(
      columnMergeStart: vicinity.column,
      columnMergeSpan: span,
      child: OverflowBox(
        minWidth: cellWidth,
        maxWidth: cellWidth,
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: cellWidth,
          child: Center(
            child: Semantics(
              header: true,
              label: 'Time $label',
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
          ),
        ),
      ),
    );
  }

  TableViewCell _buildDataCell(BuildContext context, TableVicinity vicinity) {
    final rowIdx = vicinity.row - 1;
    final row = rowIdx < _rows.length ? _rows[rowIdx] : null;

    if (vicinity.column == _kPinnedColumnIndex) {
      if (row == null) {
        return TableViewCell(child: _defaultRowHeader(context, null));
      }

      final (groupSpan, _, groupCount) = _calculateGroupMerge(vicinity, row);
      if (groupSpan != null && groupCount != null) {
        final groupRows =
            _rows.getRange(rowIdx, rowIdx + groupCount).toList(growable: false);
        final details = TimelineGroupHeaderDetails<TEvent, TRow>(
          rows: groupRows,
          state: _snapshot(),
          controller: widget.controller,
        );
        return TableViewCell(
          rowMergeStart: vicinity.row,
          rowMergeSpan: groupSpan,
          child: widget.groupHeaderBuilder != null
              ? widget.groupHeaderBuilder!(context, details)
              : _defaultGroupHeader(context, groupRows),
        );
      }

      final details = TimelineRowHeaderDetails<TEvent, TRow>(
        row: row,
        state: _snapshot(),
        controller: widget.controller,
      );
      return TableViewCell(
        child: widget.rowHeaderBuilder != null
            ? widget.rowHeaderBuilder!(context, details)
            : _defaultRowHeader(context, row),
      );
    }

    return _buildTimelineCell(context, row, vicinity);
  }

  TimelineEventInteractionDetails<TEvent, TRow> _buildInteractionDetails({
    required TEvent event,
    required TRow row,
    required DateTime displayStart,
  }) {
    return TimelineEventInteractionDetails<TEvent, TRow>(
      event: event,
      row: row,
      displayStart: displayStart,
      now: _playheadTime,
      isActive: _currentlyLive.contains(event.id),
      state: _snapshot(),
      controller: widget.controller,
    );
  }

  TableViewCell _buildTimelineCell(
      BuildContext context, TRow? row, TableVicinity vicinity) {
    final now = _playheadTime;
    final cellStart = _config.startTime
        .add(Duration(milliseconds: (vicinity.column - 1) * _eventStepMs));
    final firstVisCol = _hController.hasClients
        ? (_hController.offset / _pixelsPerStep).floor() + 1
        : 1;
    final rowEvents = _eventsForRow(row);

    final eventsInCell = rowEvents
        .where((event) =>
            _isEventInCell(rowEvents, vicinity.column, firstVisCol, event))
        .toList(growable: false);
    final event = eventsInCell.isNotEmpty ? eventsInCell.first : null;

    final (_, groupStart, groupCount) = _calculateGroupMerge(vicinity, row);
    final isInGroup = groupStart != null &&
        groupCount != null &&
        vicinity.row >= groupStart &&
        vicinity.row < (groupStart + groupCount - 1);
    final showGrid = !isInGroup;

    if (event == null) {
      final span = _calcEmptyMerge(rowEvents, vicinity.column, firstVisCol);
      final endTime =
          cellStart.add(Duration(milliseconds: _eventStepMs * span));
      return TableViewCell(
        columnMergeStart: vicinity.column,
        columnMergeSpan: span,
        child: CustomPaint(
          painter: CellBackgroundPainter(
            currentTime: now,
            startTime: cellStart,
            endTime: endTime,
            style: _style.cellStyle,
            heightOffset: showGrid ? -1 : 0,
          ),
          foregroundPainter: GridLinePainter(
            currentTime: now,
            startTime: cellStart,
            endTime: endTime,
            startingColumn: vicinity.column,
            mergeSpan: span,
            widthPerStep: _pixelsPerStep,
            displayedFactor: _gridStepFactor,
            style: _style.cellStyle,
            showHorizontalGridline: showGrid,
          ),
        ),
      );
    }

    final startsBefore = event.startTime.isBefore(cellStart);
    final effectiveStart = startsBefore ? cellStart : event.startTime;
    final mergeSpan =
        _calcMergeForEvent(event, effectiveStart, vicinity.column);
    final mergedEnd =
        cellStart.add(Duration(milliseconds: mergeSpan * _eventStepMs));
    final cellStartOffset = (vicinity.column - 1) * _pixelsPerStep;
    final cellEndOffset = cellStartOffset + (mergeSpan * _pixelsPerStep);
    final eventStartOffset = _calculateTimeOffset(event.startTime);
    final eventEndOffset = _calculateTimeOffset(event.endTime);
    final visibleStartOffset = max(eventStartOffset, cellStartOffset);
    final visibleEndOffset = min(eventEndOffset, cellEndOffset);
    final eventOffsetX = max(0.0, visibleStartOffset - cellStartOffset);
    final visibleWidth = max(0.0, visibleEndOffset - visibleStartOffset);
    final handleTap = widget.onEventTap == null
        ? null
        : () => widget.onEventTap!(
              _buildInteractionDetails(
                event: event,
                row: row!,
                displayStart: effectiveStart,
              ),
            );
    final handleLongPress = widget.onEventLongPress == null
        ? null
        : () => widget.onEventLongPress!(
              _buildInteractionDetails(
                event: event,
                row: row!,
                displayStart: effectiveStart,
              ),
            );
    final details = TimelineEventBuildDetails<TEvent, TRow>(
      event: event,
      row: row!,
      now: now,
      displayStart: effectiveStart,
      isActive: _currentlyLive.contains(event.id),
      defaultCellStyle: _style.cellStyle,
      state: _snapshot(),
      controller: widget.controller,
      handleTap: handleTap,
      handleLongPress: handleLongPress,
    );

    return TableViewCell(
      key: ValueKey('eventCell_${event.id}'),
      columnMergeStart: vicinity.column,
      columnMergeSpan: mergeSpan,
      child: CustomPaint(
        painter: CellBackgroundPainter(
          currentTime: now,
          startTime: cellStart,
          endTime: mergedEnd,
          style: _style.cellStyle,
          heightOffset: showGrid ? -1 : 0,
        ),
        foregroundPainter: EventCellGridLinePainter(
          currentTime: now,
          startTime: cellStart,
          endTime: mergedEnd,
          eventOffsetX: eventOffsetX,
          eventStart: effectiveStart,
          eventEnd: event.endTime,
          startingColumn: vicinity.column,
          mergeSpan: mergeSpan,
          widthPerStep: _pixelsPerStep,
          displayedFactor: _gridStepFactor,
          cellHeight: _style.rowHeight,
          eventWidth: visibleWidth,
          style: _style.cellStyle,
          showHorizontalGridline: showGrid,
        ),
        child: Transform.translate(
          offset: Offset(eventOffsetX, 0),
          child: Container(
            key: ValueKey('eventCellContainer_${event.id}'),
            width: visibleWidth,
            height: _style.rowHeight,
            margin: _eventMargin.copyWith(
                left: startsBefore ? 0 : _eventMargin.left),
            child: widget.eventCellBuilder != null
                ? widget.eventCellBuilder!(context, details)
                : buildDefaultEventCell(details),
          ),
        ),
      ),
    );
  }

  Widget buildDefaultEventCell(
      TimelineEventBuildDetails<TEvent, TRow> details) {
    final interactive =
        details.handleTap != null || details.handleLongPress != null;
    return Semantics(
      label: _buildDefaultEventCellSemantics(details),
      button: interactive,
      enabled: interactive,
      onTap: details.handleTap,
      onLongPress: details.handleLongPress,
      child: ExcludeSemantics(
        child: EventCellView<TEvent>(
          key: ValueKey('eventCellView_${details.event.id}'),
          event: details.event,
          now: details.now,
          displayStart: details.displayStart,
          style: details.defaultCellStyle,
          onTap: details.handleTap,
          onLongPress: details.handleLongPress,
        ),
      ),
    );
  }

  String _buildDefaultEventCellSemantics(
      TimelineEventBuildDetails<TEvent, TRow> details) {
    final formatter = DateFormat('MMM d, yyyy HH:mm');
    final status = switch (details.event.getCurrentTimeState(details.now)) {
      TimeState.past => 'completed',
      TimeState.present => 'active now',
      TimeState.future => 'upcoming',
    };
    final start = formatter.format(details.event.startTime.toLocal());
    final end = formatter.format(details.event.endTime.toLocal());
    return '${details.event.label}, ${details.row.label}, $status, $start to $end';
  }

  Widget _defaultGroupHeader(BuildContext context, List<TRow> rows) {
    return Semantics(
      header: true,
      label: 'Group ${rows.first.groupId ?? ''}',
      child: Container(
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: _style.cellStyle.gridline.past)),
        ),
        child: Center(child: Text(rows.first.groupId ?? '')),
      ),
    );
  }

  Widget _defaultRowHeader(BuildContext context, TRow? row) {
    return Semantics(
      header: true,
      label: row == null ? 'Timeline row' : 'Row ${row.label}',
      child: Container(
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: _style.cellStyle.gridline.past)),
        ),
        child: row == null ? null : Center(child: Text(row.label)),
      ),
    );
  }

  Positioned _buildCurrentTimeIndicator() {
    return Positioned(
      key: const ValueKey('current-time-indicator'),
      top: 0,
      bottom: 0,
      left: _style.pinnedColumnWidth + _timelineIndicatorPosition,
      child: Container(
        width: _style.currentTimeIndicatorStyle.width,
        color: _style.currentTimeIndicatorStyle.color,
      ),
    );
  }

  bool _isTimeInRange(DateTime time) =>
      time.isAfter(_config.startTime) && time.isBefore(_config.endTime);

  void _ensureNowBracketsRange() {
    final now = _currentNow();
    var start = _config.startTime;
    var end = _config.endTime;
    if (now.isBefore(start)) {
      start = now.subtract(_extensionChunk);
    } else if (now.isAfter(end)) {
      end = now.add(_extensionChunk);
    }
    if (start != _config.startTime || end != _config.endTime) {
      _config = _config.copyWith(startTime: start, endTime: end);
      _recomputeLayoutUnits();
    }
  }

  double _calculateTimeOffset(DateTime time) {
    final msSince = time.difference(_config.startTime).inMilliseconds;
    return (msSince / _eventStepMs) * _pixelsPerStep;
  }

  double _getCurrentTimeOffset() {
    final now = _currentNow();
    if (!_isTimeInRange(now)) return -1;
    _playheadTime = now;
    final pos = _calculateTimeOffset(now);
    return _hController.hasClients ? pos - _hController.offset : pos;
  }

  void _recomputeLayoutUnits() {
    _eventStepMs = _config.eventResolution.inMilliseconds;
    assert(_eventStepMs > 0, 'eventResolution must be > 0');
    _displayedStepMs = _config.gridResolution.inMilliseconds;
    _gridStepFactor = (_displayedStepMs / _eventStepMs).round();
    _timeHeaderStepMs = _config.timeHeaderResolution.inMilliseconds;
    _timeHeaderDisplayFactor = (_timeHeaderStepMs / _eventStepMs).round();
    _underlyingColumnCount =
        (_config.endTime.difference(_config.startTime).inMilliseconds /
                _eventStepMs)
            .ceil();
    _pixelsPerStep = _config.pixelsPerStep;
  }

  void _recomputeBottomSpacer() {
    final resolvedHeight = _resolvedSize?.height ?? widget.size?.height ?? 0;
    final viewH = resolvedHeight - _style.headerRowHeight;
    final dataH = _rows.length * _style.rowHeight;
    final needCentre = viewH / 2;
    final needFill = max(0, viewH - dataH).toDouble();
    _bottomSpacerHeight = max(needCentre, needFill);
  }

  (int? span, int? start, int? count) _calculateGroupMerge(
      TableVicinity vicinity, TRow? row) {
    final groupId = row?.groupId;
    if (groupId == null) {
      return (null, null, null);
    }

    final groupInfo = _groupInfoById[groupId];
    if (groupInfo == null || groupInfo.count <= 1) {
      return (null, groupInfo?.start, groupInfo?.count);
    }

    final firstVisRow = _vController.hasClients
        ? (_vController.offset / _style.rowHeight).floor() + 1
        : 1;
    final headerRow = max(groupInfo.start, firstVisRow);
    if (vicinity.row == headerRow) {
      return (
        groupInfo.count - (headerRow - groupInfo.start),
        groupInfo.start,
        groupInfo.count
      );
    }

    return (null, groupInfo.start, groupInfo.count);
  }

  List<TEvent> _eventsForRow(TRow? row) {
    if (row == null) {
      return List<TEvent>.empty(growable: false);
    }
    return _sortedEventsByRowId[row.id] ?? List<TEvent>.empty(growable: false);
  }

  void _debugValidateRow(TRow row) {
    final events = row.events;
    for (var i = 0; i < events.length - 1; i++) {
      final current = events[i];
      final next = events[i + 1];
      final rowDescription = 'Row "${row.label}" (${row.id})';

      if (next.startTime.isBefore(current.startTime)) {
        throw AssertionError(
          '$rowDescription has unsorted events: "${current.id}" starts after '
          '"${next.id}". Events within a row must be sorted by startTime '
          'before reaching TimelineTable.',
        );
      }

      if (next.startTime.isBefore(current.endTime)) {
        throw AssertionError(
          '$rowDescription has overlapping events "${current.id}" and '
          '"${next.id}". TimelineTable treats each row as a single '
          'non-overlapping lane. Split overlapping events into separate rows '
          'upstream before passing data to TimelineTable.',
        );
      }
    }
  }

  bool _isEventInCell(
      List<TEvent> rowEvents, int column, int firstVisible, TEvent event) {
    final cellStart = _config.startTime
        .add(Duration(milliseconds: (column - 1) * _eventStepMs));
    final cellEnd = cellStart.add(Duration(milliseconds: _eventStepMs));
    if (!(event.endTime.isAfter(cellStart) &&
        event.startTime.compareTo(cellEnd) <= 0)) {
      return false;
    }

    var anchor = event.startTime.isBefore(_config.startTime)
        ? 1
        : ((event.startTime.difference(_config.startTime).inMilliseconds) ~/
                _eventStepMs) +
            1;
    final startsAtBoundary = event.startTime == cellStart;
    if (!startsAtBoundary && anchor < firstVisible) {
      final hasOnBoundary =
          rowEvents.any((candidate) => candidate.startTime == cellStart);
      if (!hasOnBoundary) {
        anchor = firstVisible;
      }
    }
    return anchor == column;
  }

  int _calcEmptyMerge(List<TEvent> rowEvents, int startCol, int firstVisible) {
    var span = 1;
    for (var j = startCol + 1; j <= 1 + _underlyingColumnCount; j++) {
      if (rowEvents
          .any((event) => _isEventInCell(rowEvents, j, firstVisible, event))) {
        break;
      }
      span++;
    }
    return min(span, (1 + _underlyingColumnCount) - startCol);
  }

  int _calcMergeForEvent(TEvent event, DateTime effectiveStart, int column) {
    final msDur = event.endTime.difference(effectiveStart).inMilliseconds;
    final raw = (msDur / _eventStepMs).ceil();
    return max(1, min(raw, _underlyingColumnCount - (column - 1)));
  }

  (DateTime, int)? _getHeaderCellData(int underlyingIdx, int firstVisible) {
    final slotStart =
        (underlyingIdx ~/ _timeHeaderDisplayFactor) * _timeHeaderDisplayFactor;
    final offscreen = slotStart < firstVisible && underlyingIdx == firstVisible;
    if (underlyingIdx % _timeHeaderDisplayFactor == 0 || offscreen) {
      final slotIdx = slotStart ~/ _timeHeaderDisplayFactor;
      final label = _config.startTime
          .add(Duration(milliseconds: slotIdx * _timeHeaderStepMs));
      final rawSpan = offscreen
          ? _timeHeaderDisplayFactor - (firstVisible - slotStart)
          : _timeHeaderDisplayFactor;
      return (label, rawSpan);
    }
    return null;
  }
}
