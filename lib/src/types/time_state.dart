/// Relative time state for an event or cell compared with "now".
enum TimeState {
  past,
  present,
  future;

  static TimeState from(DateTime now, DateTime start, DateTime end) {
    if (now.isBefore(start)) return TimeState.future;
    if (now.isAfter(end)) return TimeState.past;
    return TimeState.present;
  }
}

/// Convenience predicates for [TimeState] checks.
extension TimeStateExt on TimeState {
  bool get isPast => this == TimeState.past;
  bool get isPresent => this == TimeState.present;
  bool get isFuture => this == TimeState.future;
}
