# timeline_table

A reusable Flutter package for building virtualised, customisable timeline tables.

## Features

- Virtualised timeline grid built on `two_dimensional_scrollables`
- Generic timeline event/row/data models
- Infinite horizontal range extension
- Current-time indicator with injectable clock for deterministic tests
- App-wide theming via `ThemeData.extensions` plus per-widget style overrides
- Builder-first customisation for pinned headers, row headers, group headers, and event cells
- Table-level tap and long-press hooks with opt-in builder wiring
- Configurable lifecycle semantics for `onEventLifecycle`
- Package-owned helper widgets and styles for default event-cell rendering

## Install

```sh
flutter pub add timeline_table
```

For local development against a checkout of this repository, you can also use a
path dependency:

```yaml
dependencies:
  timeline_table:
    path: ../timeline_table
```

Import the package with:

```dart
import 'package:timeline_table/timeline_table.dart';
```

## Requirements

`TimelineTable` must receive either:

- bounded parent constraints for width and height, or
- an explicit `size`

The timeline models also validate their inputs:

- `TimelineConfig.startTime` must be before `endTime`
- `pixelsPerStep` must be greater than zero
- `eventResolution`, `gridResolution`, and `timeHeaderResolution` must all be greater than `Duration.zero`
- `gridResolution` must be an exact multiple of `eventResolution`
- `timeHeaderResolution` must be an exact multiple of both `eventResolution` and `gridResolution`
- `TimelineEvent.endTime` must be after `startTime`
- each `TimelineRow` is treated as a single non-overlapping lane, so its events must be sorted by `startTime` and must not overlap; split overlaps upstream into separate rows before building the table

## Package guarantees

The package assumes a few invariants and keeps them stable across the default
rendering path:

- each row is a single non-overlapping lane
- event positioning is derived from exact time offsets, including partially clipped events at the left viewport edge
- controller-driven scroll helpers operate on the rendered timeline range and can extend that range when infinite scrolling is enabled

## Basic usage

```dart
final config = TimelineConfig(
  startTime: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
  endTime: DateTime.now().toUtc().add(const Duration(hours: 2)),
  eventResolution: const Duration(minutes: 1),
  gridResolution: const Duration(minutes: 30),
  timeHeaderResolution: const Duration(hours: 1),
  pixelsPerStep: 4,
);

final data = TimelineData(
  rows: [
    TimelineRow(
      id: 'row-1',
      label: 'Example Row',
      events: [
        TimelineEvent(
          id: 'event-1',
          label: 'Event',
          startTime: DateTime.now().toUtc(),
          endTime: DateTime.now().toUtc().add(const Duration(minutes: 45)),
        ),
      ],
    ),
  ],
);

SizedBox(
  width: 960,
  height: 420,
  child: TimelineTable<TimelineEvent, TimelineRow<TimelineEvent>>(
    config: config,
    data: data,
  ),
);
```

## Custom event types

```dart
class JobEvent extends TimelineEvent {
  final int priority;
  final Color accentColor;

  JobEvent({
    required this.priority,
    required this.accentColor,
    required super.id,
    required super.label,
    required super.startTime,
    required super.endTime,
  });

  @override
  JobEvent copyWith({
    int? priority,
    Color? accentColor,
    String? id,
    String? label,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return JobEvent(
      priority: priority ?? this.priority,
      accentColor: accentColor ?? this.accentColor,
      id: id ?? this.id,
      label: label ?? this.label,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

final data = TimelineData<JobEvent, TimelineRow<JobEvent>>(
  rows: [
    TimelineRow<JobEvent>(
      id: 'machine-1',
      label: 'Machine 1',
      events: [
        JobEvent(
          id: 'job-1',
          label: 'Run',
          priority: 2,
          accentColor: const Color(0xFF0F766E),
          startTime: DateTime.now().toUtc(),
          endTime: DateTime.now().toUtc().add(const Duration(minutes: 30)),
        ),
      ],
    ),
  ],
);
```

## Custom headers

```dart
TimelineTable<TimelineEvent, TimelineRow<TimelineEvent>>(
  config: config,
  data: data,
  pinnedColumnHeaderBuilder: (context, details) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 12),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text('Stations'),
    ),
  ),
  rowHeaderBuilder: (context, details) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(details.row?.label ?? ''),
    ),
  ),
  groupHeaderBuilder: (context, details) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(details.rows.first.groupId ?? ''),
    ),
  ),
)
```

## Custom event cells

```dart
TimelineTable<TimelineEvent, TimelineRow<TimelineEvent>>(
  config: config,
  data: data,
  onEventTap: (details) {
    debugPrint('Tapped ${details.row.label}: ${details.event.label}');
  },
  onEventLongPress: (details) {
    debugPrint('Long pressed ${details.event.id}');
  },
  eventCellBuilder: (context, details) {
    final style = details.defaultCellStyle.copyWith(
      eventCellBackground: const (Color(0xFF2563EB), Color(0xFF60A5FA)),
      activeEventCellBackground: const (Color(0xFF1D4ED8), Color(0xFF2563EB)),
    );

    return EventCellView<TimelineEvent>(
      event: details.event,
      now: details.now,
      displayStart: details.displayStart,
      style: style,
      onTap: details.handleTap,
      onLongPress: details.handleLongPress,
      trailingBuilder: (context, cell) => Text(
        cell.isActive ? 'LIVE' : '',
        style: cell.style.labelStyle,
      ),
    );
  },
)
```

When you provide a custom `eventCellBuilder`, you own the gesture wiring for that widget.
If you want table-level `onEventTap` and `onEventLongPress` callbacks to keep working,
forward `details.handleTap` and `details.handleLongPress` into your custom widget.

## Theming

You can theme the package globally through `ThemeData.extensions`:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: const <ThemeExtension<dynamic>>[
      TimelineThemeData(
        tableStyle: TimelineTableStyle(
          currentTimeIndicatorStyle: TimelineCurrentTimeIndicatorStyle(
            color: Color(0xFFFF7A00),
            width: 3,
          ),
          pinnedHeaderStyle: TimelinePinnedHeaderStyle(
            activeIconColor: Color(0xFF475569),
            inactiveIconColor: Color(0xFF94A3B8),
          ),
        ),
      ),
    ],
  ),
  home: const MyScreen(),
)
```

You can still override styling per widget with `TimelineTableStyle`:

```dart
TimelineTable<TimelineEvent, TimelineRow<TimelineEvent>>(
  config: config,
  data: data,
  style: const TimelineTableStyle(
    currentTimeIndicatorStyle: TimelineCurrentTimeIndicatorStyle(
      color: Color(0xFF2563EB),
      width: 4,
    ),
  ),
)
```

`TimelineTheme.of(context)` resolves the package defaults currently active for the
surrounding Flutter theme.

`TimelineTableStyle.currentTimeIndicatorColor` and
`TimelineTableStyle.currentTimeIndicatorWidth` are still supported for backward
compatibility, but new code should prefer `currentTimeIndicatorStyle`.

## Builder details

The main builder payloads exposed by the package are:

- `TimelinePinnedHeaderDetails`: current `TimelineViewState` plus the controller
- `TimelineRowHeaderDetails`: the row for that header, current state, and controller
- `TimelineGroupHeaderDetails`: grouped rows, current state, and controller
- `TimelineEventBuildDetails`: the event, row, `displayStart`, `now`, `isActive`, default cell style, state, controller, and optional `handleTap` / `handleLongPress`
- `TimelineEventInteractionDetails`: the event, row, `displayStart`, `now`, `isActive`, state, and controller delivered to `onEventTap` / `onEventLongPress`

## Lifecycle policy

`onEventLifecycle` is called when events enter or leave the active time window.
The policy controls how repeated activations are handled for the same event id.

- `TimelineLifecyclePolicy.everyTransition`
  Every enter transition fires `onEventLifecycle(event, true)`, and every leave transition fires `onEventLifecycle(event, false)`.
- `TimelineLifecyclePolicy.firstActivationOnly`
  The first enter transition for an event id fires `onEventLifecycle(event, true)`. Later re-entries for that same event id are suppressed, but leave transitions still fire.

Lifecycle tracking is reset when you replace the timeline data, so "first activation"
means first activation within the current data snapshot.

```dart
TimelineTable<TimelineEvent, TimelineRow<TimelineEvent>>(
  config: config,
  data: data,
  lifecyclePolicy: TimelineLifecyclePolicy.firstActivationOnly,
  onEventLifecycle: (event, isActive) {
    debugPrint('${event.id} ${isActive ? 'entered' : 'exited'}');
  },
)
```

## Injecting time for tests

```dart
final fixedNow = DateTime.utc(2025, 1, 1, 12);

TimelineTable<TimelineEvent, TimelineRow<TimelineEvent>>(
  config: config,
  data: data,
  nowBuilder: () => fixedNow,
  indicatorUpdateInterval: const Duration(seconds: 1),
)
```

## Controller usage

```dart
final controller =
    TimelineTableController<TimelineEvent, TimelineRow<TimelineEvent>>();

controller.ready.then((_) {
  controller.scrollToEventById('event-2');
});

Column(
  children: [
    Row(
      children: [
        FilledButton(
          onPressed: controller.scrollToNow,
          child: const Text('Now'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => controller.scrollToEventById('event-2'),
          child: const Text('Jump To Event'),
        ),
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
      ],
    ),
    Expanded(
      child: TimelineTable<TimelineEvent, TimelineRow<TimelineEvent>>(
        controller: controller,
        config: config,
        data: data,
      ),
    ),
  ],
)
```

`TimelineTableController` is a `ChangeNotifier`, so the preferred observation path is
`ListenableBuilder`, `AnimatedBuilder`, or your own listener against `controller.viewState`.

Use `await controller.ready` or `controller.ready.then(...)` for one-time work that
needs the initial layout and scroll metrics to exist before running.

You can also scroll to the first row containing events whose ids include a
partial string:

```dart
await controller.scrollToEventByPartialId(
  'incident-',
  preferredPosition: FML.middle,
);
```

`preferredPosition` controls which matching event in the first matching row is
chosen:

- `FML.first` selects the earliest matching event in that row
- `FML.middle` selects the middle matching event in that row
- `FML.last` selects the latest matching event in that row

## Desktop/Web and Accessibility

`TimelineTable` now enables mouse dragging for its own scrollable surface without
changing app-wide scroll behavior. Wheel scrolling and the default Shift+wheel
axis flip from Flutter's scroll behavior continue to work as usual.

For keyboard access, you can optionally pass `focusNode` and `autofocus`:

```dart
final focusNode = FocusNode();

TimelineTable<TimelineEvent, TimelineRow<TimelineEvent>>(
  focusNode: focusNode,
  autofocus: true,
  config: config,
  data: data,
)
```

When the timeline viewport is focused:

- `ArrowLeft` / `ArrowRight` pans horizontally by one grid interval
- `ArrowUp` / `ArrowDown` pans vertically by one row
- `Home` jumps to the current time when it is in range, otherwise to the start

The package-owned `EventCellView` now includes richer default semantics for
screen readers, plus visible hover and focus feedback on desktop/web.

If you provide a custom `eventCellBuilder`, you own the final accessibility of
that custom subtree. Reusing `EventCellView` preserves the package defaults for
event-level interaction, while the built-in table rendering also adds row-aware
context when it is available.

## Sizing and scrolling

If the parent already provides bounded constraints, you can let the widget size itself
from the layout. If not, pass an explicit `size`.

```dart
TimelineTable<TimelineEvent, TimelineRow<TimelineEvent>>(
  size: const Size(960, 420),
  config: config,
  data: data,
)
```

To extend the visible time range as the user nears either edge, enable infinite scrolling
and listen for range changes:

```dart
TimelineTable<TimelineEvent, TimelineRow<TimelineEvent>>(
  config: config,
  data: data,
  enableInfiniteScroll: true,
  extensionChunk: const Duration(hours: 6),
  extensionThresholdPx: 600,
  onTimelineRangeExtended: (newStart, newEnd, delta, toLeft) async {
    debugPrint(
      'Range extended to ${newStart.toIso8601String()} -> ${newEnd.toIso8601String()}',
    );
  },
)
```

Infinite scrolling only activates when the timeline actually has horizontal overflow,
and edge detection is clamped to the current scroll metrics so small desktop/web
viewports do not immediately trigger repeated range growth.

## Public API

- `TimelineConfig`, `TimelineEvent`, `TimelineRow`, `TimelineData`
- `TimelineTable`, `TimelineTableController`, `TimelineViewState`
- `TimelineLifecyclePolicy`
- `TimelinePinnedHeaderDetails`, `TimelineRowHeaderDetails`, `TimelineGroupHeaderDetails`
- `TimelineEventBuildDetails`, `TimelineEventInteractionDetails`
- `TimelineTheme`, `TimelineThemeData`
- `TimelineTableStyle`, `TimelineCellStyle`
- `TimelineCurrentTimeIndicatorStyle`, `TimelinePinnedHeaderStyle`
- `EventCellView`, `TimelineEventCellDetails`

## Example app

The package example gallery includes five runnable demos:

- `Transit Operations` for grouped route schedules and default event rendering
- `Product Roadmap` for custom headers and milestone styling
- `Clinic Appointments` for controller-driven navigation
- `Broadcast Rundown` for live-state rendering and edge-triggered range extension
- `Incident Response` for desktop/web input, keyboard focus, and accessibility review
