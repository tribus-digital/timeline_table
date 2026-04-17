import 'package:equatable/equatable.dart';

import 'timeline_event.dart';

/// A single rendered lane in the timeline.
///
/// Each row is treated as a non-overlapping sequence of [events]. If events
/// overlap in time, split them into separate rows before building the table.
class TimelineRow<TEvent extends TimelineEvent> extends Equatable {
  final String id;
  final String label;
  final String? groupId;
  final List<TEvent> events;

  TimelineRow({
    required this.id,
    required this.label,
    this.groupId,
    required List<TEvent> events,
  }) : events = List.unmodifiable(events);

  TimelineRow<TEvent> copyWith({
    String? id,
    String? label,
    String? groupId,
    List<TEvent>? events,
  }) {
    return TimelineRow<TEvent>(
      id: id ?? this.id,
      label: label ?? this.label,
      groupId: groupId ?? this.groupId,
      events: events ?? this.events,
    );
  }

  @override
  List<Object?> get props => [id, label, groupId, events];
}
