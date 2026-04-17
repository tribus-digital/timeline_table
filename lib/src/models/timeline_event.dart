import 'package:equatable/equatable.dart';

import '../types/time_state.dart';

/// Base event model rendered by [TimelineTable].
class TimelineEvent extends Equatable {
  final String id;
  final String label;
  final DateTime startTime;
  final DateTime endTime;

  TimelineEvent({
    required this.id,
    required this.label,
    required this.startTime,
    required this.endTime,
  }) : assert(
          endTime.isAfter(startTime),
          'TimelineEvent requires endTime to be after startTime.',
        );

  TimeState getCurrentTimeState(DateTime now) => TimeState.from(now, startTime, endTime);

  TimelineEvent copyWith({
    String? id,
    String? label,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      label: label ?? this.label,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  List<Object?> get props => [id, label, startTime, endTime];

  @override
  String toString() {
    return '$runtimeType(id: $id, startTime: $startTime, endTime: $endTime, label: $label)';
  }
}
