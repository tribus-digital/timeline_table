import 'package:flutter/material.dart';
import 'package:timeline_table/timeline_table.dart';

import '../app/demo_scaffold.dart';
import '../demo/demo_data.dart';
import '../demo/demo_models.dart';

class IncidentResponseDemo extends StatefulWidget {
  const IncidentResponseDemo({super.key});

  @override
  State<IncidentResponseDemo> createState() => _IncidentResponseDemoState();
}

class _IncidentResponseDemoState extends State<IncidentResponseDemo> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'incident_timeline');
  final TimelineTableController<DemoTimelineEvent,
          TimelineRow<DemoTimelineEvent>> _controller =
      TimelineTableController<DemoTimelineEvent,
          TimelineRow<DemoTimelineEvent>>();

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    return DemoScaffold(
      eyebrow: 'Accessibility',
      title: 'Incident Response',
      description:
          'This demo is tuned for desktop and web review. Mouse dragging works inside the timeline, keyboard focus can stay on the viewport, and the themed hover/focus treatments make interaction state easier to read.',
      capability: 'Mouse drag + keyboard focus + themed interactions',
      header: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            key: const ValueKey('incident-focus-button'),
            onPressed: _focusNode.requestFocus,
            icon: const Icon(Icons.keyboard),
            label: const Text('Focus Timeline'),
          ),
          FilledButton.tonal(
            onPressed: _controller.scrollToNow,
            child: const Text('Home To Current Window'),
          ),
          const Chip(
            avatar: Icon(Icons.mouse_outlined, size: 18),
            label: Text('Drag with mouse or use arrow keys'),
          ),
        ],
      ),
      child: TimelineTable<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        config: buildHourlyConfig(
          now,
          before: const Duration(hours: 2),
          after: const Duration(hours: 6),
          gridResolution: const Duration(minutes: 30),
          timeHeaderResolution: const Duration(hours: 1),
          pixelsPerStep: 4,
        ),
        data: buildIncidentData(now),
        onEventTap: (details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selected ${details.row.label}: ${details.event.label}',
              ),
            ),
          );
        },
        style: const TimelineTableStyle(
          pinnedColumnWidth: 188,
          rowHeight: 78,
        ),
      ),
    );
  }
}
