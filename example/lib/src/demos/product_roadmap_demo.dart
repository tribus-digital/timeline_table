import 'package:flutter/material.dart';
import 'package:timeline_table/timeline_table.dart';

import '../app/demo_scaffold.dart';
import '../demo/demo_data.dart';
import '../demo/demo_models.dart';

class ProductRoadmapDemo extends StatelessWidget {
  const ProductRoadmapDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final data = buildRoadmapData(now);
    return DemoScaffold(
      eyebrow: 'Custom Builders',
      title: 'Product Roadmap',
      description:
          'A roadmap view for platform, growth, and reliability workstreams with styled headers, milestone treatments, and distinct status rendering. Each row stays as its own non-overlapping lane.',
      capability: 'Custom headers + custom event cells',
      child: TimelineTable<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>(
        key: const ValueKey('roadmap-table'),
        config: buildRoadmapConfig(now),
        data: data,
        lifecyclePolicy: TimelineLifecyclePolicy.firstActivationOnly,
        style: const TimelineTableStyle(
          pinnedColumnWidth: 180,
          rowHeight: 70,
          headerRowHeight: 56,
        ),
        pinnedColumnHeaderBuilder: (context, details) => Container(
          color: const Color(0xFFECFEFF),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.centerLeft,
          child: Text(
            'Workstreams',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF155E75),
                ),
          ),
        ),
        rowHeaderBuilder: (context, details) => Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.centerLeft,
          child: Text(
            details.row?.label ?? '',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
          ),
        ),
        groupHeaderBuilder: (context, details) => Container(
          color: const Color(0xFFE2E8F0),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.centerLeft,
          child: Text(
            details.rows.first.groupId ?? '',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF334155),
                ),
          ),
        ),
        eventCellBuilder: (context, details) {
          final style =
              statusStyle(details.event.status, details.defaultCellStyle);
          return EventCellView<DemoTimelineEvent>(
            key: ValueKey('roadmap_${details.event.id}'),
            event: details.event,
            now: details.now,
            displayStart: details.displayStart,
            style: style,
            onTap: details.handleTap,
            onLongPress: details.handleLongPress,
            leadingBuilder: (context, cell) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(details.event.icon, color: Colors.white, size: 18),
            ),
            trailingBuilder: (context, cell) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel(details.event.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
