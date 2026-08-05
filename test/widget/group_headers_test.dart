import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeline_table/timeline_table.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// Covers how grouped rows are merged and what their headers receive.
///
/// A merged table cell can only describe one contiguous block of rows, and
/// `TableView` requires the *same* merge information from every vicinity the
/// merged cell contains - it builds the cell once, from whichever part happens
/// to be visible, and unmerges the rest if those values move. So groups are
/// contiguous runs whose merge geometry is fixed and independent of scroll
/// position, and a header fills its run rather than tracking the viewport.
void main() {
  final now = DateTime.utc(2025, 1, 1, 12);
  const rowHeight = 64.0;
  const headerRowHeight = 48.0;
  const viewportHeight = 160.0;

  TimelineRow<TimelineEvent> row(String id, String? groupId) =>
      TimelineRow<TimelineEvent>(
        id: id,
        label: id,
        groupId: groupId,
        events: [
          TimelineEvent(
            id: 'e-$id',
            label: id,
            startTime: now,
            endTime: now.add(const Duration(minutes: 30)),
          ),
        ],
      );

  /// Builds the tree from [spec], reporting each group header's rows.
  ///
  /// Rebuilt fresh on every call, so pumping it again is a genuine rebuild.
  Widget tree(
    List<(String, String?)> spec,
    void Function(GroupHeaderRows header) onHeader,
  ) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 700,
          height: viewportHeight,
          child: TimelineTable<TimelineEvent, TimelineRow<TimelineEvent>>(
            key: const ValueKey('table'),
            config: TimelineConfig(
              startTime: now.subtract(const Duration(hours: 2)),
              endTime: now.add(const Duration(hours: 6)),
              eventResolution: const Duration(minutes: 1),
              gridResolution: const Duration(minutes: 15),
              timeHeaderResolution: const Duration(hours: 1),
              pixelsPerStep: 4,
              headerTimeFormat: 'HH:mm',
            ),
            data: TimelineData<TimelineEvent, TimelineRow<TimelineEvent>>(
              rows: [for (final (id, g) in spec) row(id, g)],
            ),
            style: TimelineTableStyle(
              rowHeight: rowHeight,
              headerRowHeight: headerRowHeight,
            ),
            nowBuilder: () => now,
            groupHeaderBuilder: (context, details) {
              final group = details.rows.first.groupId!;
              onHeader(
                GroupHeaderRows(group, details.rows.map((r) => r.id).toList()),
              );
              return Container(key: ValueKey('gh-$group'));
            },
          ),
        ),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  ScrollController vertical(WidgetTester tester) => tester
      .widget<TableView>(find.byType(TableView))
      .verticalDetails
      .controller!;

  /// Pumps [spec], scrolls [scrollRows] rows down, then rebuilds.
  ///
  /// The rebuild matters: a merged header cell spans its whole run, so
  /// scrolling alone never rebuilds it. A live timeline rebuilds constantly
  /// (data updates, playhead ticks), which is how these states are reached in
  /// practice. Returns only the headers built by the rebuild.
  Future<List<GroupHeaderRows>> pumpScrolledThenRebuilt(
    WidgetTester tester,
    List<(String, String?)> spec, {
    required int scrollRows,
  }) async {
    final headers = <GroupHeaderRows>[];
    void collect(GroupHeaderRows h) => headers.add(h);

    await tester.pumpWidget(tree(spec, collect));
    await settle(tester);

    if (scrollRows > 0) {
      final controller = vertical(tester);
      final target = rowHeight * scrollRows;
      expect(
        controller.position.maxScrollExtent,
        greaterThanOrEqualTo(target),
        reason: 'viewport must allow scrolling $scrollRows row(s), '
            'otherwise this test silently proves nothing',
      );
      controller.jumpTo(target);
      await settle(tester);
      expect(controller.offset, greaterThanOrEqualTo(target));
    }

    headers.clear();
    await tester.pumpWidget(tree(spec, collect));
    await settle(tester);

    return headers;
  }

  // The bundled transit demo's shape: 'Green Line' occupies rows 1, 2 and 5,
  // 'Control' rows 3 and 6 - neither group is contiguous.
  const transitShape = <(String, String?)>[
    ('r1', 'Green Line'),
    ('r2', 'Green Line'),
    ('r3', 'Control'),
    ('r4', null),
    ('r5', 'Green Line'),
    ('r6', 'Control'),
  ];

  group('run detection', () {
    testWidgets('rows sharing a groupId non-adjacently form separate runs',
        (tester) async {
      // Taking a run's length from the group's *total* row count merged rows
      // 1-3, swallowing a Control row.
      final headers = <GroupHeaderRows>[];
      await tester.pumpWidget(tree(transitShape, headers.add));
      await settle(tester);

      for (final h in headers) {
        expect(
          h.rowIds,
          equals(['r1', 'r2']),
          reason: 'only the adjacent Green Line run may merge; '
              'got ${h.group} -> ${h.rowIds}',
        );
      }
      // Single-row runs stay ungrouped - there is nothing to merge.
      expect(headers.map((h) => h.group).toSet(), {'Green Line'});
    });

    testWidgets('a scrolled group header still reports only its own rows',
        (tester) async {
      // Scrolled one row down, the old merge pinned itself to row 2 and took
      // the group's total count from there, reporting rows 2-4: a Control row
      // and an ungrouped one.
      final headers =
          await pumpScrolledThenRebuilt(tester, transitShape, scrollRows: 1);

      expect(tester.takeException(), isNull);
      expect(headers, isNotEmpty, reason: 'header must not vanish when scrolled');
      for (final h in headers) {
        expect(
          h.rowIds,
          equals(['r1', 'r2']),
          reason: 'got ${h.group} -> ${h.rowIds}',
        );
      }
      expect(find.byKey(const ValueKey('gh-Green Line')), findsOneWidget);
    });
  });

  group('merge geometry', () {
    testWidgets('a scrolled run reaching the end of the table does not throw',
        (tester) async {
      // The reported crash. Two rows in one group, scrolled one row down: the
      // header pinned to row 2 and counted the group's 2 rows from there,
      // asking for rows [1, 3) of a 2-row list - "RangeError (end): Invalid
      // value: Not in inclusive range 1..2: 3", thrown during layout.
      final headers = await pumpScrolledThenRebuilt(
        tester,
        const [('a', 'g1'), ('b', 'g1')],
        scrollRows: 1,
      );

      expect(tester.takeException(), isNull);
      expect(headers, isNotEmpty);
      expect(headers.map((h) => h.rowIds), everyElement(equals(['a', 'b'])));
    });

    testWidgets('reported rows do not depend on scroll offset', (tester) async {
      const spec = <(String, String?)>[
        ('a', 'g1'),
        ('b', 'g1'),
        ('c', 'g1'),
      ];

      final unscrolled =
          await pumpScrolledThenRebuilt(tester, spec, scrollRows: 0);
      final scrolled =
          await pumpScrolledThenRebuilt(tester, spec, scrollRows: 1);

      expect(tester.takeException(), isNull);
      expect(unscrolled, isNotEmpty);
      expect(scrolled, isNotEmpty);
      // Any group-level total a caller derives from these rows must not shift
      // as the user scrolls.
      expect(unscrolled.map((h) => h.rowIds),
          everyElement(equals(['a', 'b', 'c'])));
      expect(
          scrolled.map((h) => h.rowIds), everyElement(equals(['a', 'b', 'c'])));
    });

    testWidgets('a group header fills its run and scrolls with it',
        (tester) async {
      // The header must occupy exactly its run's rows so its lower edge lands
      // on the run's last row boundary, in line with the timeline's row
      // gridlines.
      final spec = [for (var i = 1; i <= 6; i++) ('r$i', 'g')];

      final headers = <GroupHeaderRows>[];
      await tester.pumpWidget(tree(spec, headers.add));
      await settle(tester);

      final finder = find.byKey(const ValueKey('gh-g'));

      // Unscrolled: the merged cell starts directly below the pinned time
      // header and covers all six rows.
      expect(tester.getTopLeft(finder).dy, closeTo(headerRowHeight, 1));
      expect(tester.getSize(finder).height, closeTo(6 * rowHeight, 1));

      const offset = 2 * rowHeight;
      vertical(tester).jumpTo(offset);
      await settle(tester);

      // It has moved up with its group by exactly the scroll delta - no
      // independent drift - and kept its extent, so its bottom edge is still
      // on a row boundary.
      expect(
        tester.getTopLeft(finder).dy,
        closeTo(headerRowHeight - offset, 1),
        reason: 'header must track its own cell, not hold position',
      );
      expect(tester.getSize(finder).height, closeTo(6 * rowHeight, 1));
    });

    testWidgets('each run gets its own full-height header', (tester) async {
      final spec = [
        for (var i = 1; i <= 3; i++) ('a$i', 'first'),
        for (var i = 1; i <= 3; i++) ('b$i', 'second'),
      ];

      final headers = <GroupHeaderRows>[];
      await tester.pumpWidget(tree(spec, headers.add));
      await settle(tester);

      final controller = vertical(tester);
      controller.jumpTo(controller.position.maxScrollExtent);
      await settle(tester);

      expect(tester.takeException(), isNull);

      // Whichever runs are on screen span exactly their own three rows and sit
      // flush against a row boundary.
      for (final group in ['first', 'second']) {
        final finder = find.byKey(ValueKey('gh-$group'));
        if (finder.evaluate().isEmpty) continue;

        expect(tester.getSize(finder).height, closeTo(3 * rowHeight, 1));

        final topFromRows =
            tester.getTopLeft(finder).dy - headerRowHeight + controller.offset;
        expect(
          topFromRows % rowHeight,
          closeTo(0, 1),
          reason: '$group header should start on a row boundary',
        );
      }

      for (final h in headers) {
        expect(
          h.rowIds,
          h.group == 'first'
              ? equals(['a1', 'a2', 'a3'])
              : equals(['b1', 'b2', 'b3']),
        );
      }
    });
  });
}

/// A group header's id and the row ids it was given.
class GroupHeaderRows {
  GroupHeaderRows(this.group, this.rowIds);

  final String group;
  final List<String> rowIds;
}
