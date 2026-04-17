import 'package:equatable/equatable.dart';

import 'timeline_event.dart';
import 'timeline_row.dart';

/// Root timeline payload passed into [TimelineTable].
class TimelineData<TEvent extends TimelineEvent,
    TRow extends TimelineRow<TEvent>> extends Equatable {
  final List<TRow> rows;

  TimelineData({
    required List<TRow> rows,
  }) : rows = List.unmodifiable(rows);

  Iterable<TEvent> get events sync* {
    for (final row in rows) {
      yield* row.events;
    }
  }

  @override
  List<Object?> get props => [rows];
}
