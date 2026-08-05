import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeline_table/timeline_table.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'package:timeline_table_example/src/demo/demo_data.dart';
import 'package:timeline_table_example/src/demo/demo_models.dart';

/// Exercises every bundled demo in a viewport short enough to scroll
/// vertically, then scrolls down and horizontally - the sequence that made
/// grouped pinned headers jump, vanish, or span the wrong rows.
///
/// Asserts the two properties that were broken:
///  * no exception escapes layout, and
///  * every group header receives only rows from its own group.
void main() {
  final now = DateTime.utc(2025, 6, 1, 12);

  final demos = <String,
      TimelineData<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>>{
    'transit': buildTransitData(now),
    'roadmap': buildRoadmapData(now),
    'clinic': buildClinicData(now),
    'broadcast': buildBroadcastData(now),
    'incident': buildIncidentData(now),
  };

  for (final entry in demos.entries) {
    testWidgets('${entry.key} demo groups stay coherent when scrolled',
        (tester) async {
      final data = entry.value;
      final violations = <String>[];

      Widget tree() => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 700,
                height: 180, // short: forces vertical scrolling
                child: TimelineTable<DemoTimelineEvent,
                    TimelineRow<DemoTimelineEvent>>(
                  key: const ValueKey('table'),
                  config: TimelineConfig(
                    startTime: now.subtract(const Duration(hours: 3)),
                    endTime: now.add(const Duration(hours: 9)),
                    eventResolution: const Duration(minutes: 1),
                    gridResolution: const Duration(minutes: 15),
                    timeHeaderResolution: const Duration(hours: 1),
                    pixelsPerStep: 3,
                    headerTimeFormat: 'HH:mm',
                  ),
                  data: data,
                  nowBuilder: () => now,
                  groupHeaderBuilder: (context, details) {
                    final groups =
                        details.rows.map((r) => r.groupId).toSet();
                    if (groups.length != 1 || groups.first == null) {
                      violations.add(
                        'header got rows from ${groups.length} group(s): '
                        '${details.rows.map((r) => "${r.id}:${r.groupId}").join(", ")}',
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          );

      Future<void> settle() async {
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }

      await tester.pumpWidget(tree());
      await settle();
      expect(tester.takeException(), isNull, reason: 'initial layout');

      final tv = tester.widget<TableView>(find.byType(TableView));
      final v = tv.verticalDetails.controller!;
      final h = tv.horizontalDetails.controller!;

      // Walk down the rows, and at each step scroll horizontally and rebuild -
      // the pinned column gets rebuilt at whatever row is first visible.
      for (final vFrac in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        v.jumpTo(v.position.maxScrollExtent * vFrac);
        await settle();

        for (final hFrac in [0.0, 0.3, 0.6, 1.0]) {
          h.jumpTo(h.position.maxScrollExtent * hFrac);
          await settle();
          await tester.pumpWidget(tree()); // rebuild while scrolled
          await settle();

          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} at v=$vFrac h=$hFrac',
          );
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  }
}
