import 'package:flutter/material.dart';
import 'package:timeline_table/timeline_table.dart';

enum DemoEventStatus { planned, active, risk, complete }

class DemoTimelineEvent extends TimelineEvent {
  final DemoEventStatus status;
  final IconData icon;
  final String detail;

  DemoTimelineEvent({
    required this.status,
    required this.icon,
    required this.detail,
    required super.id,
    required super.label,
    required super.startTime,
    required super.endTime,
  });

  @override
  DemoTimelineEvent copyWith({
    DemoEventStatus? status,
    IconData? icon,
    String? detail,
    String? id,
    String? label,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return DemoTimelineEvent(
      status: status ?? this.status,
      icon: icon ?? this.icon,
      detail: detail ?? this.detail,
      id: id ?? this.id,
      label: label ?? this.label,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
