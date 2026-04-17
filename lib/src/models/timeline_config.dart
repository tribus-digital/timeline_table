import 'package:equatable/equatable.dart';

/// Defines the visible time range and layout resolutions for a [TimelineTable].
class TimelineConfig extends Equatable {
  final DateTime startTime;
  final DateTime endTime;
  final double pixelsPerStep;
  final Duration eventResolution;
  final Duration gridResolution;
  final Duration timeHeaderResolution;
  final String headerTimeFormat;

  TimelineConfig({
    required this.startTime,
    required this.endTime,
    required this.pixelsPerStep,
    required this.eventResolution,
    required this.gridResolution,
    required this.timeHeaderResolution,
    this.headerTimeFormat = 'HH:mm',
  })  : assert(
          startTime.isBefore(endTime),
          'TimelineConfig requires startTime to be before endTime.',
        ),
        assert(
          pixelsPerStep > 0,
          'TimelineConfig requires pixelsPerStep to be greater than zero.',
        ),
        assert(
          eventResolution > Duration.zero,
          'TimelineConfig requires eventResolution to be greater than zero.',
        ),
        assert(
          gridResolution > Duration.zero,
          'TimelineConfig requires gridResolution to be greater than zero.',
        ),
        assert(
          timeHeaderResolution > Duration.zero,
          'TimelineConfig requires timeHeaderResolution to be greater than zero.',
        ),
        assert(
          gridResolution.inMilliseconds % eventResolution.inMilliseconds == 0,
          'TimelineConfig requires gridResolution to be an exact multiple of eventResolution.',
        ),
        assert(
          timeHeaderResolution.inMilliseconds % eventResolution.inMilliseconds == 0,
          'TimelineConfig requires timeHeaderResolution to be an exact multiple of eventResolution.',
        ),
        assert(
          timeHeaderResolution.inMilliseconds % gridResolution.inMilliseconds == 0,
          'TimelineConfig requires timeHeaderResolution to be an exact multiple of gridResolution.',
        );

  TimelineConfig copyWith({
    DateTime? startTime,
    DateTime? endTime,
    double? pixelsPerStep,
    Duration? eventResolution,
    Duration? gridResolution,
    Duration? timeHeaderResolution,
    String? headerTimeFormat,
  }) {
    return TimelineConfig(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pixelsPerStep: pixelsPerStep ?? this.pixelsPerStep,
      eventResolution: eventResolution ?? this.eventResolution,
      gridResolution: gridResolution ?? this.gridResolution,
      timeHeaderResolution: timeHeaderResolution ?? this.timeHeaderResolution,
      headerTimeFormat: headerTimeFormat ?? this.headerTimeFormat,
    );
  }

  @override
  List<Object?> get props => [
        startTime,
        endTime,
        pixelsPerStep,
        eventResolution,
        gridResolution,
        timeHeaderResolution,
        headerTimeFormat,
      ];
}
