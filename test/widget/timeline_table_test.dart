import 'dart:ui' show SemanticsAction;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeline_table/timeline_table.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

void main() {
  final fixedNow = DateTime.utc(2025, 1, 1, 12);

  TimelineConfig buildConfig({
    DateTime? startTime,
    DateTime? endTime,
    Duration eventResolution = const Duration(minutes: 1),
    Duration gridResolution = const Duration(minutes: 15),
    Duration timeHeaderResolution = const Duration(hours: 1),
    double pixelsPerStep = 4,
  }) {
    return TimelineConfig(
      startTime: startTime ?? fixedNow.subtract(const Duration(hours: 2)),
      endTime: endTime ?? fixedNow.add(const Duration(hours: 2)),
      eventResolution: eventResolution,
      gridResolution: gridResolution,
      timeHeaderResolution: timeHeaderResolution,
      pixelsPerStep: pixelsPerStep,
      headerTimeFormat: 'HH:mm',
    );
  }

  TimelineData<TimelineEvent, TimelineRow<TimelineEvent>> buildData({
    required List<TimelineEvent> events,
  }) {
    return TimelineData<TimelineEvent, TimelineRow<TimelineEvent>>(
      rows: [
        TimelineRow<TimelineEvent>(id: 'row-1', label: 'Row', events: events),
      ],
    );
  }

  Future<void> pumpTimeline(
    WidgetTester tester, {
    required TimelineConfig config,
    required TimelineData<TimelineEvent, TimelineRow<TimelineEvent>> data,
    TimelineTableStyle? style,
    TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>?
        controller,
    TimelineEventWidgetBuilder<TimelineEvent, TimelineRow<TimelineEvent>>?
        eventCellBuilder,
    TimelineRowHeaderBuilder<TimelineEvent, TimelineRow<TimelineEvent>>?
        rowHeaderBuilder,
    bool enableInfiniteScroll = false,
    TimelineRangeExtendedCallback? onTimelineRangeExtended,
    EventLifecycleCallback<TimelineEvent>? onEventLifecycle,
    TimelineLifecyclePolicy lifecyclePolicy =
        TimelineLifecyclePolicy.everyTransition,
    bool enableCurrentTimeIndicator = true,
    TimelineEventInteractionCallback<TimelineEvent, TimelineRow<TimelineEvent>>?
        onEventTap,
    TimelineEventInteractionCallback<TimelineEvent, TimelineRow<TimelineEvent>>?
        onEventLongPress,
    FocusNode? focusNode,
    bool autofocus = false,
    Duration indicatorUpdateInterval = const Duration(seconds: 5),
    Duration extensionChunk = const Duration(hours: 12),
    double extensionThresholdPx = 800,
    ThemeData? theme,
    required DateTime Function() nowBuilder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: SizedBox(
          width: 800,
          height: 400,
          child: TimelineTable<TimelineEvent, TimelineRow<TimelineEvent>>(
            key: const ValueKey('table'),
            config: config,
            data: data,
            style: style,
            controller: controller,
            nowBuilder: nowBuilder,
            enableInfiniteScroll: enableInfiniteScroll,
            enableCurrentTimeIndicator: enableCurrentTimeIndicator,
            onTimelineRangeExtended: onTimelineRangeExtended,
            eventCellBuilder: eventCellBuilder,
            rowHeaderBuilder: rowHeaderBuilder,
            onEventLifecycle: onEventLifecycle,
            lifecyclePolicy: lifecyclePolicy,
            onEventTap: onEventTap,
            onEventLongPress: onEventLongPress,
            focusNode: focusNode,
            autofocus: autofocus,
            indicatorUpdateInterval: indicatorUpdateInterval,
            extensionChunk: extensionChunk,
            extensionThresholdPx: extensionThresholdPx,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Container currentTimeIndicatorSurface(WidgetTester tester) {
    final positioned = tester.widget<Positioned>(
      find.byKey(const ValueKey('current-time-indicator')),
    );
    return positioned.child as Container;
  }

  double currentTimeIndicatorWidth(WidgetTester tester) {
    final indicator = currentTimeIndicatorSurface(tester);
    final constraints = indicator.constraints;
    return constraints?.maxWidth ?? constraints?.minWidth ?? 0;
  }

  double eventRightEdge(WidgetTester tester, TimelineEvent event) {
    final finder = find.byKey(ValueKey('eventCellContainer_${event.id}'));
    return tester.getTopRight(finder).dx;
  }

  double eventLeftEdge(WidgetTester tester, TimelineEvent event) {
    final finder = find.byKey(ValueKey('eventCellContainer_${event.id}'));
    return tester.getTopLeft(finder).dx;
  }

  ScrollController horizontalScrollController(WidgetTester tester) {
    final tableView = tester.widget<TableView>(find.byType(TableView));
    return tableView.horizontalDetails.controller!;
  }

  double expectedHorizontalTargetOffset(
    TimelineConfig config,
    TimelineEvent event, {
    double containerWidth = 800,
    double pinnedColumnWidth = 128,
  }) {
    final viewportWidth = containerWidth - pinnedColumnWidth;
    final scrollCentre = viewportWidth / 2;
    final totalTimelineWidth =
        (config.endTime.difference(config.startTime).inMilliseconds /
                config.eventResolution.inMilliseconds) *
            config.pixelsPerStep;
    final maxOffset = totalTimelineWidth <= viewportWidth
        ? 0.0
        : totalTimelineWidth - viewportWidth;
    final offset =
        (event.startTime.difference(config.startTime).inMilliseconds /
                config.eventResolution.inMilliseconds) *
            config.pixelsPerStep;
    final target = offset - scrollCentre;
    if (target < 0) return 0;
    if (target > maxOffset) return maxOffset;
    return target;
  }

  testWidgets('current time indicator respects injected clock', (tester) async {
    final config = buildConfig();
    final data = buildData(events: const []);

    await pumpTimeline(
      tester,
      config: config,
      data: data,
      nowBuilder: () => fixedNow,
    );

    expect(
      find.byKey(const ValueKey('current-time-indicator')),
      findsOneWidget,
    );
  });

  testWidgets(
      'current time indicator uses package defaults when no theme or style is provided',
      (tester) async {
    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: const []),
      nowBuilder: () => fixedNow,
    );

    final indicator = currentTimeIndicatorSurface(tester);
    expect(currentTimeIndicatorWidth(tester), 2.0);
    expect(indicator.color, const Color(0xfff91a98));
  });

  testWidgets(
      'theme extension applies to current time indicator when widget style is absent',
      (tester) async {
    final theme = ThemeData(
      extensions: const <ThemeExtension<dynamic>>[
        TimelineThemeData(
          tableStyle: TimelineTableStyle(
            currentTimeIndicatorStyle: TimelineCurrentTimeIndicatorStyle(
              width: 6,
              color: Colors.orange,
            ),
          ),
        ),
      ],
    );

    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: const []),
      theme: theme,
      nowBuilder: () => fixedNow,
    );

    final indicator = currentTimeIndicatorSurface(tester);
    expect(currentTimeIndicatorWidth(tester), 6.0);
    expect(indicator.color, Colors.orange);
  });

  testWidgets('explicit widget style overrides theme extension defaults',
      (tester) async {
    final theme = ThemeData(
      extensions: const <ThemeExtension<dynamic>>[
        TimelineThemeData(
          tableStyle: TimelineTableStyle(
            currentTimeIndicatorStyle: TimelineCurrentTimeIndicatorStyle(
              width: 6,
              color: Colors.orange,
            ),
          ),
        ),
      ],
    );

    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: const []),
      theme: theme,
      style: const TimelineTableStyle(
        currentTimeIndicatorStyle: TimelineCurrentTimeIndicatorStyle(
          width: 4,
          color: Colors.blue,
        ),
      ),
      nowBuilder: () => fixedNow,
    );

    final indicator = currentTimeIndicatorSurface(tester);
    expect(currentTimeIndicatorWidth(tester), 4.0);
    expect(indicator.color, Colors.blue);
  });

  testWidgets(
      'legacy current time indicator fields still configure the playhead',
      (tester) async {
    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: const []),
      style: const TimelineTableStyle(
        currentTimeIndicatorWidth: 5,
        currentTimeIndicatorColor: Colors.deepOrange,
      ),
      nowBuilder: () => fixedNow,
    );

    final indicator = currentTimeIndicatorSurface(tester);
    expect(currentTimeIndicatorWidth(tester), 5.0);
    expect(indicator.color, Colors.deepOrange);
  });

  testWidgets(
      'nested indicator style wins over deprecated legacy indicator fields',
      (tester) async {
    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: const []),
      style: const TimelineTableStyle(
        currentTimeIndicatorWidth: 5,
        currentTimeIndicatorColor: Colors.deepOrange,
        currentTimeIndicatorStyle: TimelineCurrentTimeIndicatorStyle(
          width: 3,
          color: Colors.teal,
        ),
      ),
      nowBuilder: () => fixedNow,
    );

    final indicator = currentTimeIndicatorSurface(tester);
    expect(currentTimeIndicatorWidth(tester), 3.0);
    expect(indicator.color, Colors.teal);
  });

  testWidgets('custom row header builder is used', (tester) async {
    final config = buildConfig();
    final data = buildData(events: const []);

    await pumpTimeline(
      tester,
      config: config,
      data: data,
      rowHeaderBuilder: (context, details) => const Text('Custom Row Header'),
      nowBuilder: () => fixedNow,
    );

    expect(find.text('Custom Row Header'), findsOneWidget);
  });

  testWidgets('theme extension styles the default pinned header timer icon',
      (tester) async {
    final theme = ThemeData(
      extensions: const <ThemeExtension<dynamic>>[
        TimelineThemeData(
          tableStyle: TimelineTableStyle(
            pinnedHeaderStyle: TimelinePinnedHeaderStyle(
              activeIconColor: Colors.amber,
              inactiveIconColor: Colors.cyan,
            ),
          ),
        ),
      ],
    );

    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: const []),
      theme: theme,
      nowBuilder: () => fixedNow,
    );

    final iconButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(iconButton.color, Colors.amber);
  });

  testWidgets('widget style overrides the default pinned header label styling',
      (tester) async {
    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: const []),
      enableCurrentTimeIndicator: false,
      style: const TimelineTableStyle(
        pinnedHeaderStyle: TimelinePinnedHeaderStyle(
          labelStyle: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      nowBuilder: () => fixedNow,
    );

    final label = tester.widget<Text>(find.text('Time'));
    expect(label.style?.color, Colors.indigo);
    expect(label.style?.fontWeight, FontWeight.w500);
  });

  testWidgets('event width matches configured resolution', (tester) async {
    final config = buildConfig();
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Event',
      startTime: fixedNow.add(const Duration(minutes: 5)),
      endTime: fixedNow.add(const Duration(minutes: 50)),
    );

    await pumpTimeline(
      tester,
      config: config,
      data: buildData(events: [event]),
      nowBuilder: () => fixedNow,
    );

    final eventFinder = find.byKey(ValueKey('eventCellContainer_${event.id}'));
    expect(eventFinder, findsOneWidget);
    expect(tester.getSize(eventFinder).width, 180);
  });

  testWidgets('builder-first event customization is used', (tester) async {
    final config = buildConfig();
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Event',
      startTime: fixedNow.add(const Duration(minutes: 5)),
      endTime: fixedNow.add(const Duration(minutes: 10)),
    );

    await pumpTimeline(
      tester,
      config: config,
      data: buildData(events: [event]),
      eventCellBuilder: (context, details) => Container(
        key: const ValueKey('custom-event-cell'),
        color: Colors.orange,
        child: Text(details.event.label),
      ),
      nowBuilder: () => fixedNow,
    );

    expect(find.byKey(const ValueKey('custom-event-cell')), findsOneWidget);
  });

  testWidgets('rows assert when events are not sorted by start time',
      (tester) async {
    final later = TimelineEvent(
      id: 'event-late',
      label: 'Later event',
      startTime: fixedNow.add(const Duration(minutes: 20)),
      endTime: fixedNow.add(const Duration(minutes: 45)),
    );
    final earlier = TimelineEvent(
      id: 'event-early',
      label: 'Earlier event',
      startTime: fixedNow.add(const Duration(minutes: 5)),
      endTime: fixedNow.add(const Duration(minutes: 15)),
    );

    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: [later, earlier]),
      nowBuilder: () => fixedNow,
    );

    expect(
      tester.takeException(),
      isA<AssertionError>().having(
        (error) => error.toString(),
        'message',
        contains('has unsorted events'),
      ),
    );
  });

  testWidgets('rows assert when events overlap within a lane', (tester) async {
    final first = TimelineEvent(
      id: 'event-1',
      label: 'First',
      startTime: fixedNow.add(const Duration(minutes: 5)),
      endTime: fixedNow.add(const Duration(minutes: 30)),
    );
    final second = TimelineEvent(
      id: 'event-2',
      label: 'Second',
      startTime: fixedNow.add(const Duration(minutes: 20)),
      endTime: fixedNow.add(const Duration(minutes: 40)),
    );

    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: [first, second]),
      nowBuilder: () => fixedNow,
    );

    expect(
      tester.takeException(),
      isA<AssertionError>().having(
        (error) => error.toString(),
        'message',
        contains('Split overlapping events into separate rows upstream'),
      ),
    );
  });

  testWidgets('controller reflects auto-scroll state after user drag',
      (tester) async {
    final controller =
        TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>();
    final config = buildConfig();

    await pumpTimeline(
      tester,
      config: config,
      data: buildData(events: const []),
      controller: controller,
      nowBuilder: () => fixedNow,
    );
    expect(controller.autoScrollEnabled, isTrue);

    await tester.drag(
      find.byKey(const ValueKey('table')),
      const Offset(-200, 0),
    );
    await tester.pump();

    expect(controller.autoScrollEnabled, isFalse);
  });

  testWidgets('timeline supports mouse drag scrolling', (tester) async {
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Event',
      startTime: fixedNow.add(const Duration(minutes: 35)),
      endTime: fixedNow.add(const Duration(minutes: 75)),
    );

    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: [event]),
      nowBuilder: () => fixedNow,
    );

    final eventFinder = find.byKey(ValueKey('eventCellContainer_${event.id}'));
    final before = tester.getTopLeft(eventFinder).dx;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('table'))),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(-180, 0));
    await tester.pumpAndSettle();
    await gesture.up();

    final after = tester.getTopLeft(eventFinder).dx;
    expect(after, lessThan(before));
  });

  testWidgets('left-clipped events keep a smooth right edge during drag',
      (tester) async {
    final event = TimelineEvent(
      id: 'event-left-clip',
      label: 'Clipped Event',
      startTime: fixedNow.subtract(const Duration(minutes: 20)),
      endTime: fixedNow.add(const Duration(minutes: 25)),
    );

    await pumpTimeline(
      tester,
      config: buildConfig(
        eventResolution: const Duration(minutes: 1),
        gridResolution: const Duration(minutes: 15),
        pixelsPerStep: 4,
      ),
      data: buildData(events: [event]),
      nowBuilder: () => fixedNow,
    );

    final eventFinder = find.byKey(ValueKey('eventCellContainer_${event.id}'));
    expect(eventFinder, findsOneWidget);

    final horizontalController = horizontalScrollController(tester);
    horizontalController.jumpTo(horizontalController.offset + 260);
    await tester.pump();

    final tableLeft = tester.getTopLeft(find.byKey(const ValueKey('table'))).dx;
    const pinnedBoundaryOffset = 128.0;
    final eventLeft = tester.getTopLeft(eventFinder).dx;

    expect(
      eventLeft,
      lessThan(tableLeft + pinnedBoundaryOffset),
    );

    final rightEdges = <double>[eventRightEdge(tester, event)];
    for (var i = 0; i < 5; i++) {
      horizontalController.jumpTo(horizontalController.offset + 1);
      await tester.pump();
      rightEdges.add(eventRightEdge(tester, event));
    }

    final deltas = <double>[
      for (var i = 1; i < rightEdges.length; i++)
        rightEdges[i] - rightEdges[i - 1],
    ];

    expect(deltas, everyElement(inExclusiveRange(-1.5, -0.5)));
  });

  testWidgets('coarse event resolutions keep a smooth right edge while clipped',
      (tester) async {
    final config = buildConfig(
      startTime: fixedNow.subtract(const Duration(days: 2)),
      endTime: fixedNow.add(const Duration(days: 5)),
      eventResolution: const Duration(hours: 1),
      gridResolution: const Duration(hours: 12),
      timeHeaderResolution: const Duration(days: 1),
      pixelsPerStep: 10,
    );
    final event = TimelineEvent(
      id: 'event-roadmap-like',
      label: 'Roadmap Event',
      startTime: fixedNow.subtract(const Duration(hours: 8)),
      endTime: fixedNow.add(const Duration(days: 1, hours: 4)),
    );

    await pumpTimeline(
      tester,
      config: config,
      data: buildData(events: [event]),
      nowBuilder: () => fixedNow,
    );

    final horizontalController = horizontalScrollController(tester);
    horizontalController.jumpTo(horizontalController.offset + 15);
    await tester.pump();

    final rightEdges = <double>[eventRightEdge(tester, event)];
    for (var i = 0; i < 12; i++) {
      horizontalController.jumpTo(horizontalController.offset + 1);
      await tester.pump();
      rightEdges.add(eventRightEdge(tester, event));
    }

    final deltas = <double>[
      for (var i = 1; i < rightEdges.length; i++)
        rightEdges[i] - rightEdges[i - 1],
    ];

    expect(deltas, everyElement(inExclusiveRange(-1.5, -0.5)));
  });

  testWidgets('sub-step event starts move smoothly while scrolling',
      (tester) async {
    final event = TimelineEvent(
      id: 'event-sub-step',
      label: 'Sub-step Event',
      startTime: fixedNow
          .subtract(const Duration(minutes: 20))
          .add(const Duration(seconds: 30)),
      endTime: fixedNow
          .add(const Duration(minutes: 18))
          .add(const Duration(seconds: 30)),
    );

    await pumpTimeline(
      tester,
      config: buildConfig(
        eventResolution: const Duration(minutes: 1),
        gridResolution: const Duration(minutes: 15),
        pixelsPerStep: 8,
      ),
      data: buildData(events: [event]),
      nowBuilder: () => fixedNow,
    );

    final horizontalController = horizontalScrollController(tester);
    final leftEdges = <double>[eventLeftEdge(tester, event)];
    final rightEdges = <double>[eventRightEdge(tester, event)];
    for (var i = 0; i < 6; i++) {
      horizontalController.jumpTo(horizontalController.offset + 1);
      await tester.pump();
      leftEdges.add(eventLeftEdge(tester, event));
      rightEdges.add(eventRightEdge(tester, event));
    }

    final leftDeltas = <double>[
      for (var i = 1; i < leftEdges.length; i++)
        leftEdges[i] - leftEdges[i - 1],
    ];
    final rightDeltas = <double>[
      for (var i = 1; i < rightEdges.length; i++)
        rightEdges[i] - rightEdges[i - 1],
    ];

    expect(leftDeltas, everyElement(inExclusiveRange(-1.5, -0.5)));
    expect(rightDeltas, everyElement(inExclusiveRange(-1.5, -0.5)));
  });

  testWidgets(
      'infinite scroll does not extend when no horizontal overflow exists',
      (tester) async {
    var extensionCalls = 0;

    await pumpTimeline(
      tester,
      config: buildConfig(
        startTime: fixedNow.subtract(const Duration(minutes: 30)),
        endTime: fixedNow.add(const Duration(minutes: 30)),
      ),
      data: buildData(events: const []),
      enableInfiniteScroll: true,
      onTimelineRangeExtended: (newStart, newEnd, delta, toLeft) async {
        extensionCalls++;
      },
      nowBuilder: () => fixedNow,
    );

    await tester.drag(
      find.byKey(const ValueKey('table')),
      const Offset(-240, 0),
    );
    await tester.pumpAndSettle();

    expect(extensionCalls, 0);
  });

  testWidgets('controller can extend range to reach out-of-range event',
      (tester) async {
    final controller =
        TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>();
    final config = buildConfig(
      startTime: fixedNow.subtract(const Duration(hours: 1)),
      endTime: fixedNow.add(const Duration(hours: 1)),
    );
    final event = TimelineEvent(
      id: 'event-outside',
      label: 'Later',
      startTime: fixedNow.add(const Duration(hours: 3)),
      endTime: fixedNow.add(const Duration(hours: 3, minutes: 30)),
    );

    var extensionCalls = 0;
    await pumpTimeline(
      tester,
      config: config,
      data: buildData(events: [event]),
      controller: controller,
      enableInfiniteScroll: true,
      onTimelineRangeExtended: (newStart, newEnd, delta, toLeft) async {
        extensionCalls++;
      },
      nowBuilder: () => fixedNow,
    );

    final didScroll = await controller.scrollToEventById(event.id);
    await tester.pump();

    expect(didScroll, isTrue);
    expect(extensionCalls, greaterThan(0));
  });

  testWidgets('controller can scroll to the first partial-id match',
      (tester) async {
    final controller =
        TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>();
    final config = buildConfig();
    final first = TimelineEvent(
      id: 'incident-alpha',
      label: 'First',
      startTime: fixedNow.add(const Duration(minutes: 10)),
      endTime: fixedNow.add(const Duration(minutes: 30)),
    );
    final middle = TimelineEvent(
      id: 'incident-bravo',
      label: 'Middle',
      startTime: fixedNow.add(const Duration(minutes: 50)),
      endTime: fixedNow.add(const Duration(minutes: 70)),
    );
    final last = TimelineEvent(
      id: 'incident-charlie',
      label: 'Last',
      startTime: fixedNow.add(const Duration(minutes: 90)),
      endTime: fixedNow.add(const Duration(minutes: 110)),
    );

    await pumpTimeline(
      tester,
      config: config,
      data: buildData(events: [first, middle, last]),
      controller: controller,
      nowBuilder: () => fixedNow,
    );

    final scrollFuture = controller.scrollToEventByPartialId(
      'incident-',
      preferredPosition: FML.first,
    );
    await tester.pumpAndSettle();
    final didScroll = await scrollFuture;

    expect(didScroll, isTrue);
    expect(
      horizontalScrollController(tester).offset,
      closeTo(expectedHorizontalTargetOffset(config, first), 0.5),
    );
  });

  testWidgets('controller can scroll to the middle partial-id match',
      (tester) async {
    final controller =
        TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>();
    final config = buildConfig();
    final first = TimelineEvent(
      id: 'incident-alpha',
      label: 'First',
      startTime: fixedNow.add(const Duration(minutes: 10)),
      endTime: fixedNow.add(const Duration(minutes: 30)),
    );
    final middle = TimelineEvent(
      id: 'incident-bravo',
      label: 'Middle',
      startTime: fixedNow.add(const Duration(minutes: 50)),
      endTime: fixedNow.add(const Duration(minutes: 70)),
    );
    final last = TimelineEvent(
      id: 'incident-charlie',
      label: 'Last',
      startTime: fixedNow.add(const Duration(minutes: 90)),
      endTime: fixedNow.add(const Duration(minutes: 110)),
    );

    await pumpTimeline(
      tester,
      config: config,
      data: buildData(events: [first, middle, last]),
      controller: controller,
      nowBuilder: () => fixedNow,
    );

    final scrollFuture = controller.scrollToEventByPartialId(
      'incident-',
      preferredPosition: FML.middle,
    );
    await tester.pumpAndSettle();
    final didScroll = await scrollFuture;

    expect(didScroll, isTrue);
    expect(
      horizontalScrollController(tester).offset,
      closeTo(expectedHorizontalTargetOffset(config, middle), 0.5),
    );
  });

  testWidgets('controller can scroll to the last partial-id match',
      (tester) async {
    final controller =
        TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>();
    final config = buildConfig();
    final first = TimelineEvent(
      id: 'incident-alpha',
      label: 'First',
      startTime: fixedNow.add(const Duration(minutes: 10)),
      endTime: fixedNow.add(const Duration(minutes: 30)),
    );
    final middle = TimelineEvent(
      id: 'incident-bravo',
      label: 'Middle',
      startTime: fixedNow.add(const Duration(minutes: 50)),
      endTime: fixedNow.add(const Duration(minutes: 70)),
    );
    final last = TimelineEvent(
      id: 'incident-charlie',
      label: 'Last',
      startTime: fixedNow.add(const Duration(minutes: 90)),
      endTime: fixedNow.add(const Duration(minutes: 110)),
    );

    await pumpTimeline(
      tester,
      config: config,
      data: buildData(events: [first, middle, last]),
      controller: controller,
      nowBuilder: () => fixedNow,
    );

    final scrollFuture = controller.scrollToEventByPartialId(
      'incident-',
      preferredPosition: FML.last,
    );
    await tester.pumpAndSettle();
    final didScroll = await scrollFuture;

    expect(didScroll, isTrue);
    expect(
      horizontalScrollController(tester).offset,
      closeTo(expectedHorizontalTargetOffset(config, last), 0.5),
    );
  });

  testWidgets('controller partial-id scroll returns false when no match exists',
      (tester) async {
    final controller =
        TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>();
    final config = buildConfig();
    final event = TimelineEvent(
      id: 'incident-alpha',
      label: 'Only Event',
      startTime: fixedNow.add(const Duration(minutes: 10)),
      endTime: fixedNow.add(const Duration(minutes: 30)),
    );

    await pumpTimeline(
      tester,
      config: config,
      data: buildData(events: [event]),
      controller: controller,
      nowBuilder: () => fixedNow,
    );

    final before = horizontalScrollController(tester).offset;
    final didScroll = await controller.scrollToEventByPartialId(
      'missing-id',
      preferredPosition: FML.last,
    );
    await tester.pump();

    expect(didScroll, isFalse);
    expect(horizontalScrollController(tester).offset, before);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a near-edge drag extends once and the timeline stays draggable after extension',
      (tester) async {
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Event',
      startTime: fixedNow.add(const Duration(minutes: 90)),
      endTime: fixedNow.add(const Duration(minutes: 120)),
    );
    var extensionCalls = 0;

    await pumpTimeline(
      tester,
      config: buildConfig(
        startTime: fixedNow.subtract(const Duration(hours: 2)),
        endTime: fixedNow.add(const Duration(hours: 2)),
      ),
      data: buildData(events: [event]),
      enableInfiniteScroll: true,
      extensionChunk: const Duration(hours: 6),
      extensionThresholdPx: 180,
      onTimelineRangeExtended: (newStart, newEnd, delta, toLeft) async {
        extensionCalls++;
      },
      nowBuilder: () => fixedNow,
    );

    final tableFinder = find.byKey(const ValueKey('table'));
    final eventFinder = find.byKey(ValueKey('eventCellContainer_${event.id}'));
    expect(eventFinder, findsOneWidget);

    await tester.drag(tableFinder, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(extensionCalls, 1);

    final afterExtension = tester.getTopLeft(eventFinder).dx;

    await tester.drag(tableFinder, const Offset(-120, 0));
    await tester.pumpAndSettle();

    expect(extensionCalls, 1);
    final afterSecondDrag = tester.getTopLeft(eventFinder).dx;
    expect(afterSecondDrag, lessThan(afterExtension));
  });

  testWidgets('keyboard arrows pan the focused timeline viewport',
      (tester) async {
    final focusNode = FocusNode(debugLabel: 'timeline');
    addTearDown(focusNode.dispose);
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Event',
      startTime: fixedNow.add(const Duration(minutes: 45)),
      endTime: fixedNow.add(const Duration(minutes: 80)),
    );

    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: [event]),
      focusNode: focusNode,
      autofocus: true,
      nowBuilder: () => fixedNow,
    );

    expect(focusNode.hasFocus, isTrue);

    final eventFinder = find.byKey(ValueKey('eventCellContainer_${event.id}'));
    final before = tester.getTopLeft(eventFinder).dx;

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    final afterRight = tester.getTopLeft(eventFinder).dx;

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    final afterLeft = tester.getTopLeft(eventFinder).dx;

    expect(afterRight, lessThan(before));
    expect(afterLeft, greaterThan(afterRight));
  });

  testWidgets('Home recenters the current-time window when now is in range',
      (tester) async {
    final focusNode = FocusNode(debugLabel: 'timeline');
    addTearDown(focusNode.dispose);
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Current Window Event',
      startTime: fixedNow.add(const Duration(minutes: 45)),
      endTime: fixedNow.add(const Duration(minutes: 90)),
    );

    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: [event]),
      focusNode: focusNode,
      autofocus: true,
      nowBuilder: () => fixedNow,
    );

    expect(focusNode.hasFocus, isTrue);

    final eventFinder = find.byKey(ValueKey('eventCellContainer_${event.id}'));
    expect(eventFinder, findsOneWidget);
    final original = tester.getTopLeft(eventFinder).dx;

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    final shifted = tester.getTopLeft(eventFinder).dx;
    expect(shifted, lessThan(original));

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();

    final recentered = tester.getTopLeft(eventFinder).dx;
    expect((recentered - original).abs(), lessThan(5));
  });

  testWidgets('controller ListenableBuilder is safe in a lazily mounted tab',
      (tester) async {
    final controller =
        TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>();

    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Basic'),
                  Tab(text: 'Custom'),
                  Tab(text: 'Controller'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                SizedBox(
                  width: 800,
                  height: 400,
                  child: Column(
                    children: [
                      ListenableBuilder(
                        listenable: controller,
                        builder: (context, child) {
                          final viewState = controller.viewState;
                          return Text(
                            controller.isReady
                                ? 'Ready, ${viewState?.activeEventIds.length ?? 0} active'
                                : controller.attached
                                    ? 'Attached, waiting for layout'
                                    : 'Waiting for attach',
                          );
                        },
                      ),
                      Expanded(
                        child: TimelineTable<TimelineEvent,
                            TimelineRow<TimelineEvent>>(
                          config: buildConfig(),
                          data: buildData(events: const []),
                          controller: controller,
                          nowBuilder: () => fixedNow,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Controller'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.attached, isTrue);
    expect(controller.isReady, isTrue);
  });

  testWidgets('controller ListenableBuilder is safe when parent rebuilds data',
      (tester) async {
    final controller =
        TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>();
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Event',
      startTime: fixedNow.add(const Duration(minutes: 5)),
      endTime: fixedNow.add(const Duration(minutes: 15)),
    );
    var data = buildData(events: const []);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 800,
                height: 400,
                child: Column(
                  children: [
                    FilledButton(
                      key: const ValueKey('swap-data'),
                      onPressed: () {
                        setState(() {
                          data = buildData(events: [event]);
                        });
                      },
                      child: const Text('Swap Data'),
                    ),
                    ListenableBuilder(
                      listenable: controller,
                      builder: (context, child) {
                        final rows = controller.viewState?.rows ?? const [];
                        final eventCount = rows.fold<int>(
                          0,
                          (count, row) => count + row.events.length,
                        );
                        return Text('events: $eventCount');
                      },
                    ),
                    Expanded(
                      child: TimelineTable<TimelineEvent,
                          TimelineRow<TimelineEvent>>(
                        config: buildConfig(),
                        data: data,
                        controller: controller,
                        nowBuilder: () => fixedNow,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.viewState?.rows.single.events, isEmpty);

    await tester.tap(find.byKey(const ValueKey('swap-data')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.viewState?.rows.single.events, hasLength(1));
  });

  testWidgets('controller detaches from the old instance when swapped',
      (tester) async {
    final firstController =
        TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>();
    final secondController =
        TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>();
    final config = buildConfig();
    final data = buildData(events: const []);

    await pumpTimeline(
      tester,
      config: config,
      data: data,
      controller: firstController,
      nowBuilder: () => fixedNow,
    );

    expect(firstController.attached, isTrue);
    expect(secondController.attached, isFalse);
    expect(firstController.isReady, isTrue);
    expect(secondController.isReady, isFalse);

    await pumpTimeline(
      tester,
      config: config,
      data: data,
      controller: secondController,
      nowBuilder: () => fixedNow,
    );

    expect(firstController.attached, isFalse);
    expect(secondController.attached, isTrue);
    expect(firstController.isReady, isFalse);
    expect(secondController.isReady, isTrue);
  });

  testWidgets('controller ready completes after initial layout',
      (tester) async {
    final controller =
        TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>();
    final readyFuture = controller.ready;

    expect(controller.isReady, isFalse);

    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: const []),
      controller: controller,
      nowBuilder: () => fixedNow,
    );

    await readyFuture;

    expect(controller.isReady, isTrue);
  });

  testWidgets('controller readiness resets when detached', (tester) async {
    final controller =
        TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>();
    final firstReady = controller.ready;

    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: const []),
      controller: controller,
      nowBuilder: () => fixedNow,
    );

    await firstReady;
    expect(controller.isReady, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(controller.attached, isFalse);
    expect(controller.isReady, isFalse);
    expect(identical(firstReady, controller.ready), isFalse);
  });

  testWidgets('controller listener reports latest state across lifecycle',
      (tester) async {
    final controller =
        TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>();
    final snapshots = <({bool attached, bool ready, bool autoScroll})>[];
    controller.addListener(() {
      snapshots.add((
        attached: controller.attached,
        ready: controller.isReady,
        autoScroll: controller.autoScrollEnabled,
      ));
    });

    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: const []),
      controller: controller,
      nowBuilder: () => fixedNow,
    );

    expect(snapshots, isNotEmpty);
    expect(
      snapshots,
      contains(
        (
          attached: true,
          ready: true,
          autoScroll: true,
        ),
      ),
    );

    controller.enableAutoScroll(false);
    await tester.pump();

    expect(
      snapshots,
      contains(
        (
          attached: true,
          ready: true,
          autoScroll: false,
        ),
      ),
    );

    controller.updateData(buildData(events: const []), force: true);
    await tester.pump();

    expect(snapshots.last.attached, isTrue);
    expect(snapshots.last.ready, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(controller.attached, isFalse);
    expect(snapshots.last.attached, isFalse);
    expect(snapshots.last.ready, isFalse);
  });

  testWidgets(
      'everyTransition lifecycle policy fires enter and exit repeatedly',
      (tester) async {
    final config = buildConfig(
      startTime: fixedNow.subtract(const Duration(hours: 1)),
      endTime: fixedNow.add(const Duration(hours: 1)),
    );
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Event',
      startTime: fixedNow.subtract(const Duration(minutes: 5)),
      endTime: fixedNow.add(const Duration(minutes: 5)),
    );
    final lifecycleEvents = <String>[];
    var now = fixedNow.subtract(const Duration(minutes: 10));

    await pumpTimeline(
      tester,
      config: config,
      data: buildData(events: [event]),
      lifecyclePolicy: TimelineLifecyclePolicy.everyTransition,
      onEventLifecycle: (event, isActive) {
        lifecycleEvents.add('${event.id}:${isActive ? 'enter' : 'exit'}');
      },
      nowBuilder: () => now,
      indicatorUpdateInterval: const Duration(seconds: 1),
    );

    expect(lifecycleEvents, isEmpty);

    now = fixedNow;
    await tester.pump(const Duration(seconds: 1));

    now = fixedNow.add(const Duration(minutes: 10));
    await tester.pump(const Duration(seconds: 1));

    now = fixedNow;
    await tester.pump(const Duration(seconds: 1));

    expect(
      lifecycleEvents,
      ['event-1:enter', 'event-1:exit', 'event-1:enter'],
    );
  });

  testWidgets(
      'firstActivationOnly lifecycle policy keeps one-shot enter behavior',
      (tester) async {
    final config = buildConfig(
      startTime: fixedNow.subtract(const Duration(hours: 1)),
      endTime: fixedNow.add(const Duration(hours: 1)),
    );
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Event',
      startTime: fixedNow.subtract(const Duration(minutes: 5)),
      endTime: fixedNow.add(const Duration(minutes: 5)),
    );
    final lifecycleEvents = <String>[];
    var now = fixedNow.subtract(const Duration(minutes: 10));

    await pumpTimeline(
      tester,
      config: config,
      data: buildData(events: [event]),
      lifecyclePolicy: TimelineLifecyclePolicy.firstActivationOnly,
      onEventLifecycle: (event, isActive) {
        lifecycleEvents.add('${event.id}:${isActive ? 'enter' : 'exit'}');
      },
      nowBuilder: () => now,
      indicatorUpdateInterval: const Duration(seconds: 1),
    );

    now = fixedNow;
    await tester.pump(const Duration(seconds: 1));

    now = fixedNow.add(const Duration(minutes: 10));
    await tester.pump(const Duration(seconds: 1));

    now = fixedNow;
    await tester.pump(const Duration(seconds: 1));

    expect(
      lifecycleEvents,
      ['event-1:enter', 'event-1:exit'],
    );
  });

  testWidgets('lifecycle tracking resets when data updates', (tester) async {
    final controller =
        TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>();
    final config = buildConfig();
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Event',
      startTime: fixedNow.subtract(const Duration(minutes: 5)),
      endTime: fixedNow.add(const Duration(minutes: 5)),
    );
    final lifecycleEvents = <String>[];

    await pumpTimeline(
      tester,
      config: config,
      data: buildData(events: [event]),
      controller: controller,
      lifecyclePolicy: TimelineLifecyclePolicy.firstActivationOnly,
      onEventLifecycle: (event, isActive) {
        if (isActive) {
          lifecycleEvents.add(event.id);
        }
      },
      nowBuilder: () => fixedNow,
    );

    expect(lifecycleEvents, ['event-1']);

    controller.updateData(buildData(events: [event]), force: true);
    await tester.pump();

    expect(lifecycleEvents, ['event-1', 'event-1']);
  });

  testWidgets('default event cell dispatches tap and long press',
      (tester) async {
    final config = buildConfig();
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Event',
      startTime: fixedNow.add(const Duration(minutes: 5)),
      endTime: fixedNow.add(const Duration(minutes: 15)),
    );
    final interactions = <String>[];

    await pumpTimeline(
      tester,
      config: config,
      data: buildData(events: [event]),
      onEventTap: (details) => interactions.add('${details.event.id}:tap'),
      onEventLongPress: (details) =>
          interactions.add('${details.event.id}:long'),
      nowBuilder: () => fixedNow,
    );

    final eventFinder = find.byKey(ValueKey('eventCellView_${event.id}'));
    expect(eventFinder, findsOneWidget);

    await tester.tap(eventFinder);
    await tester.pump();
    await tester.longPress(eventFinder);
    await tester.pump();

    expect(interactions, ['event-1:tap', 'event-1:long']);
  });

  testWidgets('default timeline event cells expose row-aware semantics',
      (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Event',
      startTime: fixedNow.add(const Duration(minutes: 5)),
      endTime: fixedNow.add(const Duration(minutes: 15)),
    );

    await pumpTimeline(
      tester,
      config: buildConfig(),
      data: buildData(events: [event]),
      onEventTap: (details) {},
      onEventLongPress: (details) {},
      nowBuilder: () => fixedNow,
    );

    final semanticsLabel =
        'Event, Row, upcoming, Jan 1, 2025 12:05 to Jan 1, 2025 12:15';
    final semanticsNode = tester.getSemantics(
      find.bySemanticsLabel(semanticsLabel),
    );

    final data = semanticsNode.getSemanticsData();
    expect(data.label, semanticsLabel);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.hasAction(SemanticsAction.longPress), isTrue);
    semanticsHandle.dispose();
  });

  testWidgets('custom event builder can opt into tap and long press',
      (tester) async {
    final config = buildConfig();
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Event',
      startTime: fixedNow.add(const Duration(minutes: 5)),
      endTime: fixedNow.add(const Duration(minutes: 15)),
    );
    final interactions = <String>[];

    await pumpTimeline(
      tester,
      config: config,
      data: buildData(events: [event]),
      onEventTap: (details) => interactions.add('${details.event.id}:tap'),
      onEventLongPress: (details) =>
          interactions.add('${details.event.id}:long'),
      eventCellBuilder: (context, details) => GestureDetector(
        key: const ValueKey('custom-event-cell'),
        onTap: details.handleTap,
        onLongPress: details.handleLongPress,
        child: ColoredBox(
          color: Colors.orange,
          child: Text(details.event.label),
        ),
      ),
      nowBuilder: () => fixedNow,
    );

    final customFinder = find.byKey(const ValueKey('custom-event-cell'));
    await tester.tap(customFinder);
    await tester.pump();
    await tester.longPress(customFinder);
    await tester.pump();

    expect(interactions, ['event-1:tap', 'event-1:long']);
  });

  testWidgets('EventCellView shows hover and focus decoration', (tester) async {
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Event',
      startTime: fixedNow.add(const Duration(minutes: 5)),
      endTime: fixedNow.add(const Duration(minutes: 15)),
    );
    const style = TimelineCellStyle(
      hoverBorderColor: Colors.orange,
      hoverBorderWidth: 3,
      focusBorderColor: Colors.purple,
      focusBorderWidth: 5,
      hoverOverlayColor: Colors.yellow,
      focusOverlayColor: Colors.blue,
      splashColor: Colors.green,
      highlightColor: Colors.red,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              height: 56,
              child: EventCellView<TimelineEvent>(
                key: ValueKey('eventCellView_${event.id}'),
                event: event,
                now: fixedNow,
                displayStart: event.startTime,
                style: style,
                onTap: () {},
                onLongPress: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    BoxDecoration surfaceDecoration() {
      final surface = tester.widget<Ink>(
        find.byKey(ValueKey('eventCellSurface_${event.id}')),
      );
      return surface.decoration! as BoxDecoration;
    }

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.hoverColor, Colors.yellow);
    expect(inkWell.focusColor, Colors.blue);
    expect(inkWell.splashColor, Colors.green);
    expect(inkWell.highlightColor, Colors.red);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(
        tester.getCenter(find.byKey(ValueKey('eventCellView_${event.id}'))));
    await tester.pumpAndSettle();

    expect(surfaceDecoration().border, isNotNull);
    final hoverBorder = surfaceDecoration().border! as Border;
    expect(hoverBorder.top.width, 3);
    expect(hoverBorder.top.color, Colors.orange);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final focusBorder = surfaceDecoration().border! as Border;
    expect(focusBorder.top.width, 5);
    expect(focusBorder.top.color, Colors.purple);
  });
}
