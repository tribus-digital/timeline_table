import 'package:flutter/material.dart';
import 'package:timeline_table/timeline_table.dart';

import 'demo_models.dart';

TimelineConfig buildHourlyConfig(
  DateTime now, {
  required Duration before,
  required Duration after,
  required Duration gridResolution,
  required Duration timeHeaderResolution,
  required double pixelsPerStep,
}) {
  final startTime =
      _floorToDurationBoundary(now.subtract(before), timeHeaderResolution);
  final endTime = _ceilToDurationBoundary(now.add(after), timeHeaderResolution);
  return TimelineConfig(
    startTime: startTime,
    endTime: endTime,
    eventResolution: const Duration(minutes: 1),
    gridResolution: gridResolution,
    timeHeaderResolution: timeHeaderResolution,
    pixelsPerStep: pixelsPerStep,
  );
}

TimelineConfig buildRoadmapConfig(DateTime now) {
  final start = DateTime.utc(now.year, now.month, now.day).subtract(
    const Duration(days: 3),
  );
  return TimelineConfig(
    startTime: start,
    endTime: start.add(const Duration(days: 12)),
    eventResolution: const Duration(hours: 1),
    gridResolution: const Duration(hours: 12),
    timeHeaderResolution: const Duration(days: 1),
    pixelsPerStep: 10,
    headerTimeFormat: 'EEE d MMM',
  );
}

String statusLabel(DemoEventStatus status) {
  return switch (status) {
    DemoEventStatus.planned => 'Planned',
    DemoEventStatus.active => 'Active',
    DemoEventStatus.risk => 'At Risk',
    DemoEventStatus.complete => 'Complete',
  };
}

TimelineCellStyle statusStyle(
  DemoEventStatus status,
  TimelineCellStyle base,
) {
  return switch (status) {
    DemoEventStatus.planned => base.copyWith(
        eventCellBackground: const (Color(0xFF2563EB), Color(0xFF60A5FA)),
        activeEventCellBackground: const (
          Color(0xFF1D4ED8),
          Color(0xFF2563EB),
        ),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    DemoEventStatus.active => base.copyWith(
        eventCellBackground: const (Color(0xFF0891B2), Color(0xFF22D3EE)),
        activeEventCellBackground: const (
          Color(0xFF0F766E),
          Color(0xFF14B8A6),
        ),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    DemoEventStatus.risk => base.copyWith(
        eventCellBackground: const (Color(0xFFDC2626), Color(0xFFF97316)),
        activeEventCellBackground: const (
          Color(0xFFB91C1C),
          Color(0xFFEA580C),
        ),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    DemoEventStatus.complete => base.copyWith(
        eventCellBackground: const (Color(0xFF059669), Color(0xFF34D399)),
        activeEventCellBackground: const (
          Color(0xFF047857),
          Color(0xFF10B981),
        ),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
  };
}

TimelineData<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>
    buildTransitData(DateTime now) {
  return TimelineData<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>(
    rows: [
      TimelineRow<DemoTimelineEvent>(
        id: 'transit-row-1',
        label: 'Platform 1',
        groupId: 'Green Line',
        events: [
          DemoTimelineEvent(
            id: 'transit-1',
            label: 'Inbound 402',
            detail: 'Arriving',
            status: DemoEventStatus.active,
            icon: Icons.train,
            startTime: now.subtract(const Duration(minutes: 18)),
            endTime: now.add(const Duration(minutes: 8)),
          ),
          DemoTimelineEvent(
            id: 'transit-2',
            label: 'Turnback Prep',
            detail: 'Crew handoff',
            status: DemoEventStatus.planned,
            icon: Icons.swap_horiz,
            startTime: now.add(const Duration(minutes: 20)),
            endTime: now.add(const Duration(minutes: 45)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'transit-row-2',
        label: 'Platform 2',
        groupId: 'Green Line',
        events: [
          DemoTimelineEvent(
            id: 'transit-3',
            label: 'Outbound 417',
            detail: 'Boarding',
            status: DemoEventStatus.risk,
            icon: Icons.departure_board_outlined,
            startTime: now.add(const Duration(minutes: 10)),
            endTime: now.add(const Duration(minutes: 35)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'transit-row-3',
        label: 'Signal Desk',
        groupId: 'Control',
        events: [
          DemoTimelineEvent(
            id: 'transit-4',
            label: 'Route Check',
            detail: 'Line clear',
            status: DemoEventStatus.complete,
            icon: Icons.rule_folder_outlined,
            startTime: now.subtract(const Duration(minutes: 70)),
            endTime: now.subtract(const Duration(minutes: 30)),
          ),
          DemoTimelineEvent(
            id: 'transit-5',
            label: 'Diversion Window',
            detail: 'Track maintenance',
            status: DemoEventStatus.planned,
            icon: Icons.alt_route_outlined,
            startTime: now.add(const Duration(minutes: 60)),
            endTime: now.add(const Duration(minutes: 120)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'transit-row-4',
        label: 'Cleaning Crew',
        events: [
          DemoTimelineEvent(
            id: 'transit-6',
            label: 'Car Set Reset',
            detail: 'Rapid turnaround',
            status: DemoEventStatus.complete,
            icon: Icons.cleaning_services_outlined,
            startTime: now.subtract(const Duration(minutes: 120)),
            endTime: now.subtract(const Duration(minutes: 55)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'transit-row-5',
        label: 'Platform 3',
        groupId: 'Green Line',
        events: [
          DemoTimelineEvent(
            id: 'transit-7',
            label: 'Inbound 431',
            detail: '2-car consist',
            status: DemoEventStatus.planned,
            icon: Icons.train_outlined,
            startTime: now.add(const Duration(minutes: 35)),
            endTime: now.add(const Duration(minutes: 62)),
          ),
          DemoTimelineEvent(
            id: 'transit-8',
            label: 'Crew swap',
            detail: 'Relief team',
            status: DemoEventStatus.complete,
            icon: Icons.badge_outlined,
            startTime: now.add(const Duration(minutes: 78)),
            endTime: now.add(const Duration(minutes: 102)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'transit-row-6',
        label: 'Yard Ops',
        groupId: 'Control',
        events: [
          DemoTimelineEvent(
            id: 'transit-9',
            label: 'Spare set dispatch',
            detail: 'Track 6',
            status: DemoEventStatus.active,
            icon: Icons.directions_railway_outlined,
            startTime: now.subtract(const Duration(minutes: 28)),
            endTime: now.add(const Duration(minutes: 14)),
          ),
        ],
      ),
    ],
  );
}

TimelineData<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>
    buildRoadmapData(DateTime now) {
  final anchor = DateTime.utc(now.year, now.month, now.day);
  return TimelineData<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>(
    rows: [
      TimelineRow<DemoTimelineEvent>(
        id: 'roadmap-row-1',
        label: 'Authentication Review',
        groupId: 'Core Platform',
        events: [
          DemoTimelineEvent(
            id: 'roadmap-2',
            label: 'SSO audit',
            detail: 'Security review',
            status: DemoEventStatus.complete,
            icon: Icons.verified_user_outlined,
            startTime: anchor.subtract(const Duration(days: 2, hours: 12)),
            endTime: anchor.subtract(const Duration(hours: 4)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'roadmap-row-2',
        label: 'Authentication Delivery',
        groupId: 'Core Platform',
        events: [
          DemoTimelineEvent(
            id: 'roadmap-1',
            label: 'Passkey beta',
            detail: 'Partner preview',
            status: DemoEventStatus.active,
            icon: Icons.key_outlined,
            startTime: anchor.subtract(const Duration(hours: 12)),
            endTime: anchor.add(const Duration(days: 2, hours: 8)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'roadmap-row-3',
        label: 'Billing',
        groupId: 'Core Platform',
        events: [
          DemoTimelineEvent(
            id: 'roadmap-3',
            label: 'Invoice redesign',
            detail: 'Design QA',
            status: DemoEventStatus.planned,
            icon: Icons.receipt_long_outlined,
            startTime: anchor.add(const Duration(days: 2)),
            endTime: anchor.add(const Duration(days: 5, hours: 12)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'roadmap-row-4',
        label: 'Lifecycle Messaging',
        groupId: 'Growth',
        events: [
          DemoTimelineEvent(
            id: 'roadmap-4',
            label: 'Reactivation campaign',
            detail: 'Needs copy review',
            status: DemoEventStatus.risk,
            icon: Icons.campaign_outlined,
            startTime: anchor.add(const Duration(days: 1, hours: 12)),
            endTime: anchor.add(const Duration(days: 4)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'roadmap-row-5',
        label: 'Analytics',
        groupId: 'Growth',
        events: [
          DemoTimelineEvent(
            id: 'roadmap-5',
            label: 'North star dashboard',
            detail: 'Exec preview',
            status: DemoEventStatus.active,
            icon: Icons.insights_outlined,
            startTime: anchor,
            endTime: anchor.add(const Duration(days: 3)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'roadmap-row-6',
        label: 'Resilience',
        groupId: 'Reliability',
        events: [
          DemoTimelineEvent(
            id: 'roadmap-6',
            label: 'Retry orchestration',
            detail: 'Release candidate',
            status: DemoEventStatus.complete,
            icon: Icons.sync_problem_outlined,
            startTime: anchor.subtract(const Duration(days: 1, hours: 12)),
            endTime: anchor.add(const Duration(days: 1)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'roadmap-row-7',
        label: 'Lifecycle Platform',
        groupId: 'Growth',
        events: [
          DemoTimelineEvent(
            id: 'roadmap-7',
            label: 'Journey builder',
            detail: 'Internal alpha',
            status: DemoEventStatus.planned,
            icon: Icons.account_tree_outlined,
            startTime: anchor.add(const Duration(days: 3)),
            endTime: anchor.add(const Duration(days: 6, hours: 12)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'roadmap-row-8',
        label: 'Service Recovery',
        groupId: 'Reliability',
        events: [
          DemoTimelineEvent(
            id: 'roadmap-8',
            label: 'Rollback drills',
            detail: 'Ops sign-off',
            status: DemoEventStatus.risk,
            icon: Icons.restore_outlined,
            startTime: anchor.add(const Duration(hours: 18)),
            endTime: anchor.add(const Duration(days: 2, hours: 18)),
          ),
        ],
      ),
    ],
  );
}

TimelineData<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>> buildClinicData(
    DateTime now) {
  return TimelineData<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>(
    rows: [
      TimelineRow<DemoTimelineEvent>(
        id: 'clinic-row-1',
        label: 'Reception',
        events: [
          DemoTimelineEvent(
            id: 'clinic-1',
            label: 'Morning intake',
            detail: 'Front desk',
            status: DemoEventStatus.active,
            icon: Icons.assignment_ind_outlined,
            startTime: now.subtract(const Duration(minutes: 20)),
            endTime: now.add(const Duration(minutes: 25)),
          ),
          DemoTimelineEvent(
            id: 'clinic-2',
            label: 'Check-in rush',
            detail: 'Walk-in arrivals',
            status: DemoEventStatus.planned,
            icon: Icons.queue_outlined,
            startTime: now.add(const Duration(minutes: 40)),
            endTime: now.add(const Duration(minutes: 85)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'clinic-row-2',
        label: 'Room 3',
        groupId: 'Consult Rooms',
        events: [
          DemoTimelineEvent(
            id: 'clinic-3',
            label: 'Vitals + consult',
            detail: 'Dr Patel',
            status: DemoEventStatus.complete,
            icon: Icons.health_and_safety_outlined,
            startTime: now.subtract(const Duration(minutes: 90)),
            endTime: now.subtract(const Duration(minutes: 25)),
          ),
          DemoTimelineEvent(
            id: 'clinic-4',
            label: 'Follow-up slot',
            detail: 'Respiratory review',
            status: DemoEventStatus.risk,
            icon: Icons.medical_information_outlined,
            startTime: now.add(const Duration(minutes: 75)),
            endTime: now.add(const Duration(minutes: 130)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'clinic-row-3',
        label: 'Room 5',
        groupId: 'Consult Rooms',
        events: [
          DemoTimelineEvent(
            id: 'clinic-5',
            label: 'Procedure prep',
            detail: 'Imaging handoff',
            status: DemoEventStatus.planned,
            icon: Icons.biotech_outlined,
            startTime: now.add(const Duration(minutes: 10)),
            endTime: now.add(const Duration(minutes: 55)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'clinic-row-4',
        label: 'Pharmacy',
        events: [
          DemoTimelineEvent(
            id: 'clinic-6',
            label: 'Medication pickup',
            detail: 'Queue balancing',
            status: DemoEventStatus.complete,
            icon: Icons.medication_liquid_outlined,
            startTime: now.subtract(const Duration(minutes: 150)),
            endTime: now.subtract(const Duration(minutes: 95)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'clinic-row-5',
        label: 'Room 7',
        groupId: 'Consult Rooms',
        events: [
          DemoTimelineEvent(
            id: 'clinic-7',
            label: 'Cardio consult',
            detail: 'Dr Lopez',
            status: DemoEventStatus.active,
            icon: Icons.favorite_border_outlined,
            startTime: now.subtract(const Duration(minutes: 8)),
            endTime: now.add(const Duration(minutes: 42)),
          ),
          DemoTimelineEvent(
            id: 'clinic-8',
            label: 'Discharge review',
            detail: 'Medication plan',
            status: DemoEventStatus.planned,
            icon: Icons.assignment_turned_in_outlined,
            startTime: now.add(const Duration(minutes: 70)),
            endTime: now.add(const Duration(minutes: 118)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'clinic-row-6',
        label: 'Lab',
        events: [
          DemoTimelineEvent(
            id: 'clinic-9',
            label: 'Blood panel batch',
            detail: 'Priority samples',
            status: DemoEventStatus.complete,
            icon: Icons.science_outlined,
            startTime: now.subtract(const Duration(minutes: 110)),
            endTime: now.subtract(const Duration(minutes: 45)),
          ),
        ],
      ),
    ],
  );
}

TimelineData<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>
    buildBroadcastData(DateTime now) {
  return TimelineData<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>(
    rows: [
      TimelineRow<DemoTimelineEvent>(
        id: 'broadcast-row-1',
        label: 'Studio A',
        groupId: 'Live Show',
        events: [
          DemoTimelineEvent(
            id: 'broadcast-1',
            label: 'Opening block',
            detail: 'MONO',
            status: DemoEventStatus.active,
            icon: Icons.mic_external_on_outlined,
            startTime: now.subtract(const Duration(minutes: 12)),
            endTime: now.add(const Duration(minutes: 18)),
          ),
          DemoTimelineEvent(
            id: 'broadcast-2',
            label: 'Guest interview',
            detail: 'Remote',
            status: DemoEventStatus.planned,
            icon: Icons.groups_outlined,
            startTime: now.add(const Duration(minutes: 25)),
            endTime: now.add(const Duration(minutes: 70)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'broadcast-row-2',
        label: 'Graphics',
        groupId: 'Live Show',
        events: [
          DemoTimelineEvent(
            id: 'broadcast-3',
            label: 'Lower thirds',
            detail: 'Package B',
            status: DemoEventStatus.complete,
            icon: Icons.animation_outlined,
            startTime: now.subtract(const Duration(minutes: 50)),
            endTime: now.subtract(const Duration(minutes: 10)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'broadcast-row-3',
        label: 'Streaming',
        events: [
          DemoTimelineEvent(
            id: 'broadcast-4',
            label: 'Ad break roll',
            detail: 'DCN',
            status: DemoEventStatus.risk,
            icon: Icons.wifi_tethering_outlined,
            startTime: now.add(const Duration(minutes: 82)),
            endTime: now.add(const Duration(minutes: 105)),
          ),
          DemoTimelineEvent(
            id: 'broadcast-5',
            label: 'Late overrun segment',
            detail: 'Extra 20 min',
            status: DemoEventStatus.planned,
            icon: Icons.schedule_send_outlined,
            startTime: now.add(const Duration(hours: 3, minutes: 10)),
            endTime: now.add(const Duration(hours: 3, minutes: 50)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'broadcast-row-4',
        label: 'Audio',
        groupId: 'Live Show',
        events: [
          DemoTimelineEvent(
            id: 'broadcast-6',
            label: 'Mic check reset',
            detail: 'Studio B',
            status: DemoEventStatus.complete,
            icon: Icons.graphic_eq_outlined,
            startTime: now.subtract(const Duration(minutes: 35)),
            endTime: now.subtract(const Duration(minutes: 5)),
          ),
          DemoTimelineEvent(
            id: 'broadcast-7',
            label: 'Backup mix route',
            detail: 'Standby',
            status: DemoEventStatus.planned,
            icon: Icons.surround_sound_outlined,
            startTime: now.add(const Duration(minutes: 48)),
            endTime: now.add(const Duration(minutes: 92)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'broadcast-row-5',
        label: 'Master Control',
        events: [
          DemoTimelineEvent(
            id: 'broadcast-8',
            label: 'Affiliate timing',
            detail: 'Regional windows',
            status: DemoEventStatus.risk,
            icon: Icons.settings_input_antenna_outlined,
            startTime: now.add(const Duration(minutes: 12)),
            endTime: now.add(const Duration(minutes: 38)),
          ),
        ],
      ),
    ],
  );
}

TimelineData<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>
    buildIncidentData(DateTime now) {
  return TimelineData<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>(
    rows: [
      TimelineRow<DemoTimelineEvent>(
        id: 'incident-row-1',
        label: 'Infrastructure',
        groupId: 'Response',
        events: [
          DemoTimelineEvent(
            id: 'incident-1',
            label: 'API failover',
            detail: 'Secondary region',
            status: DemoEventStatus.active,
            icon: Icons.cloud_sync_outlined,
            startTime: now.subtract(const Duration(minutes: 16)),
            endTime: now.add(const Duration(minutes: 24)),
          ),
          DemoTimelineEvent(
            id: 'incident-2',
            label: 'Capacity review',
            detail: 'Autoscaling audit',
            status: DemoEventStatus.planned,
            icon: Icons.speed_outlined,
            startTime: now.add(const Duration(minutes: 32)),
            endTime: now.add(const Duration(minutes: 70)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'incident-row-2',
        label: 'Customer Comms',
        groupId: 'Response',
        events: [
          DemoTimelineEvent(
            id: 'incident-3',
            label: 'Status page update',
            detail: 'Public',
            status: DemoEventStatus.complete,
            icon: Icons.campaign_outlined,
            startTime: now.subtract(const Duration(minutes: 65)),
            endTime: now.subtract(const Duration(minutes: 20)),
          ),
          DemoTimelineEvent(
            id: 'incident-4',
            label: 'Executive brief',
            detail: 'Leadership sync',
            status: DemoEventStatus.risk,
            icon: Icons.record_voice_over_outlined,
            startTime: now.add(const Duration(minutes: 55)),
            endTime: now.add(const Duration(minutes: 95)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'incident-row-3',
        label: 'Support',
        events: [
          DemoTimelineEvent(
            id: 'incident-5',
            label: 'Priority queue triage',
            detail: 'VIP tickets',
            status: DemoEventStatus.active,
            icon: Icons.support_agent_outlined,
            startTime: now.subtract(const Duration(minutes: 6)),
            endTime: now.add(const Duration(minutes: 46)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'incident-row-4',
        label: 'Security',
        events: [
          DemoTimelineEvent(
            id: 'incident-6',
            label: 'Audit timeline',
            detail: 'Forensics capture',
            status: DemoEventStatus.planned,
            icon: Icons.policy_outlined,
            startTime: now.add(const Duration(hours: 1, minutes: 15)),
            endTime: now.add(const Duration(hours: 2)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'incident-row-5',
        label: 'Database',
        groupId: 'Response',
        events: [
          DemoTimelineEvent(
            id: 'incident-7',
            label: 'Replica catch-up',
            detail: 'Lag audit',
            status: DemoEventStatus.active,
            icon: Icons.storage_outlined,
            startTime: now.subtract(const Duration(minutes: 22)),
            endTime: now.add(const Duration(minutes: 18)),
          ),
          DemoTimelineEvent(
            id: 'incident-8',
            label: 'Read-only guardrail',
            detail: 'Feature flag',
            status: DemoEventStatus.planned,
            icon: Icons.rule_outlined,
            startTime: now.add(const Duration(minutes: 44)),
            endTime: now.add(const Duration(minutes: 88)),
          ),
        ],
      ),
      TimelineRow<DemoTimelineEvent>(
        id: 'incident-row-6',
        label: 'Trust & Safety',
        events: [
          DemoTimelineEvent(
            id: 'incident-9',
            label: 'Customer outreach brief',
            detail: 'Escalation template',
            status: DemoEventStatus.complete,
            icon: Icons.shield_outlined,
            startTime: now.subtract(const Duration(minutes: 80)),
            endTime: now.subtract(const Duration(minutes: 30)),
          ),
        ],
      ),
    ],
  );
}

DateTime _floorToDurationBoundary(DateTime time, Duration step) {
  final stepMicros = step.inMicroseconds;
  final micros = time.microsecondsSinceEpoch;
  final remainder = micros.remainder(stepMicros);
  final flooredMicros = remainder == 0 ? micros : micros - remainder;
  return DateTime.fromMicrosecondsSinceEpoch(
    flooredMicros,
    isUtc: time.isUtc,
  );
}

DateTime _ceilToDurationBoundary(DateTime time, Duration step) {
  final stepMicros = step.inMicroseconds;
  final micros = time.microsecondsSinceEpoch;
  final remainder = micros.remainder(stepMicros);
  final ceiledMicros =
      remainder == 0 ? micros : micros + (stepMicros - remainder);
  return DateTime.fromMicrosecondsSinceEpoch(
    ceiledMicros,
    isUtc: time.isUtc,
  );
}
