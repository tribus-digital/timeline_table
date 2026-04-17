import 'package:flutter/material.dart';
import 'package:timeline_table/timeline_table.dart';

import '../app/demo_scaffold.dart';
import '../demo/demo_data.dart';
import '../demo/demo_models.dart';

class ClinicAppointmentsDemo extends StatefulWidget {
  const ClinicAppointmentsDemo({super.key});

  @override
  State<ClinicAppointmentsDemo> createState() => _ClinicAppointmentsDemoState();
}

class _ClinicAppointmentsDemoState extends State<ClinicAppointmentsDemo> {
  final TimelineTableController<DemoTimelineEvent,
          TimelineRow<DemoTimelineEvent>> _controller =
      TimelineTableController<DemoTimelineEvent,
          TimelineRow<DemoTimelineEvent>>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _jumpWhenReady(String eventId) async {
    await _controller.ready;
    if (!mounted) return;
    await _controller.scrollToEventById(eventId);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    return DemoScaffold(
      eyebrow: 'Controller',
      title: 'Clinic Appointments',
      description:
          'Navigation helpers are useful for dense operational schedules. This board lets you jump to patient check-ins, consult rooms, and follow-ups.',
      capability: 'Controller navigation + readiness state',
      header: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: _controller.scrollToNow,
            icon: const Icon(Icons.schedule),
            label: const Text('Scroll To Now'),
          ),
          FilledButton.tonal(
            onPressed: () {
              _controller.scrollToEventById('clinic-2');
            },
            child: const Text('Jump To Check-In'),
          ),
          FilledButton.tonal(
            onPressed: () {
              _controller.scrollToEventById('clinic-4');
            },
            child: const Text('Jump To Follow-Up'),
          ),
          FilledButton.tonal(
            onPressed: () => _jumpWhenReady('clinic-5'),
            child: const Text('Wait Then Jump'),
          ),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              final activeCount =
                  _controller.viewState?.activeEventIds.length ?? 0;
              return Chip(
                avatar: const Icon(Icons.monitor_heart_outlined, size: 18),
                label: Text(
                  _controller.isReady
                      ? 'Ready, $activeCount active'
                      : _controller.attached
                          ? 'Attached, waiting for layout'
                          : 'Waiting for attach',
                ),
              );
            },
          ),
        ],
      ),
      child: TimelineTable<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>(
        controller: _controller,
        config: buildHourlyConfig(
          now,
          before: const Duration(hours: 3),
          after: const Duration(hours: 5),
          gridResolution: const Duration(minutes: 30),
          timeHeaderResolution: const Duration(hours: 1),
          pixelsPerStep: 3,
        ),
        data: buildClinicData(now),
        style: const TimelineTableStyle(
          pinnedColumnWidth: 164,
          rowHeight: 76,
        ),
        rowHeaderBuilder: (context, details) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              details.row?.label ?? '',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
