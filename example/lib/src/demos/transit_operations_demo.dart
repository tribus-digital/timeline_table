import 'package:flutter/material.dart';
import 'package:timeline_table/timeline_table.dart';

import '../app/demo_scaffold.dart';
import '../demo/demo_data.dart';
import '../demo/demo_models.dart';

class TransitOperationsDemo extends StatelessWidget {
  const TransitOperationsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    return DemoScaffold(
      eyebrow: 'Default Usage',
      title: 'Transit Operations',
      description:
          'A station control board with grouped routes, departures, arrivals, and short handover tasks. This demo stays close to the default package experience while picking up app-wide timeline theming from ThemeData.',
      capability: 'Grouped rows + theme-driven defaults',
      child: TimelineTable<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>(
        config: buildHourlyConfig(
          now,
          before: const Duration(hours: 2),
          after: const Duration(hours: 4),
          gridResolution: const Duration(minutes: 15),
          timeHeaderResolution: const Duration(hours: 1),
          pixelsPerStep: 4,
        ),
        data: buildTransitData(now),
        style: const TimelineTableStyle(
          pinnedColumnWidth: 156,
          rowHeight: 72,
        ),
      ),
    );
  }
}
