import 'package:flutter_test/flutter_test.dart';
import 'package:timeline_table/timeline_table.dart';

void main() {
  test('TimelineRow and TimelineData keep unmodifiable collections', () {
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Event',
      startTime: DateTime.utc(2025, 1, 1, 8),
      endTime: DateTime.utc(2025, 1, 1, 9),
    );
    final row = TimelineRow<TimelineEvent>(
      id: 'row-1',
      label: 'Row',
      events: [event],
    );
    final data =
        TimelineData<TimelineEvent, TimelineRow<TimelineEvent>>(rows: [row]);

    expect(() => row.events.add(event), throwsUnsupportedError);
    expect(() => data.rows.add(row), throwsUnsupportedError);
  });

  test('TimelineEvent reports time state from now/start/end', () {
    final event = TimelineEvent(
      id: 'event-1',
      label: 'Event',
      startTime: DateTime.utc(2025, 1, 1, 8),
      endTime: DateTime.utc(2025, 1, 1, 9),
    );

    expect(event.getCurrentTimeState(DateTime.utc(2025, 1, 1, 7, 59)).isFuture,
        isTrue);
    expect(event.getCurrentTimeState(DateTime.utc(2025, 1, 1, 8, 30)).isPresent,
        isTrue);
    expect(event.getCurrentTimeState(DateTime.utc(2025, 1, 1, 9, 1)).isPast,
        isTrue);
  });

  test('TimelineConfig rejects invalid ranges and resolution multiples', () {
    expect(
      () => TimelineConfig(
        startTime: DateTime.utc(2025, 1, 1, 10),
        endTime: DateTime.utc(2025, 1, 1, 9),
        pixelsPerStep: 4,
        eventResolution: const Duration(minutes: 1),
        gridResolution: const Duration(minutes: 15),
        timeHeaderResolution: const Duration(hours: 1),
      ),
      throwsA(isA<AssertionError>()),
    );

    expect(
      () => TimelineConfig(
        startTime: DateTime.utc(2025, 1, 1, 8),
        endTime: DateTime.utc(2025, 1, 1, 9),
        pixelsPerStep: 4,
        eventResolution: const Duration(minutes: 7),
        gridResolution: const Duration(minutes: 15),
        timeHeaderResolution: const Duration(hours: 1),
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('TimelineEvent rejects zero or negative durations', () {
    expect(
      () => TimelineEvent(
        id: 'event-1',
        label: 'Event',
        startTime: DateTime.utc(2025, 1, 1, 8),
        endTime: DateTime.utc(2025, 1, 1, 8),
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
