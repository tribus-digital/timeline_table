import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeline_table_example/main.dart';

final RegExp _timeHeaderPattern = RegExp(r'^\d{2}:\d{2}$');

List<String> _visibleTimeHeaderLabels(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? widget.textSpan?.toPlainText())
      .whereType<String>()
      .where(_timeHeaderPattern.hasMatch)
      .toList();
}

void main() {
  testWidgets('narrow gallery can navigate across all demos', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const TimelineExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Transit Operations'), findsWidgets);
    expect(_visibleTimeHeaderLabels(tester), isNotEmpty);
    expect(
      _visibleTimeHeaderLabels(tester),
      everyElement(matches(RegExp(r'^\d{2}:00$'))),
    );

    await tester.tap(find.text('Roadmap'));
    await tester.pumpAndSettle();
    expect(find.text('Product Roadmap'), findsWidgets);
    expect(find.byKey(const ValueKey('roadmap-table')), findsOneWidget);
    expect(find.byKey(const ValueKey('roadmap_roadmap-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('roadmap_roadmap-2')), findsOneWidget);

    await tester.tap(find.text('Clinic'));
    await tester.pumpAndSettle();
    expect(find.text('Clinic Appointments'), findsWidgets);
    expect(find.textContaining('Ready,'), findsOneWidget);

    await tester.tap(find.text('Broadcast'));
    await tester.pumpAndSettle();
    expect(find.text('Broadcast Rundown'), findsWidgets);
    expect(_visibleTimeHeaderLabels(tester), isNotEmpty);
    expect(
      _visibleTimeHeaderLabels(tester),
      everyElement(matches(RegExp(r'^\d{2}:(00|30)$'))),
    );

    await tester.tap(find.text('Incident'));
    await tester.pumpAndSettle();
    expect(find.text('Incident Response'), findsWidgets);
    expect(find.byKey(const ValueKey('incident-focus-button')), findsOneWidget);
  });

  testWidgets('wide gallery uses navigation rail destinations', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const TimelineExampleApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Transit Operations'), findsWidgets);

    await tester.tap(find.text('Incident'));
    await tester.pumpAndSettle();
    expect(find.text('Incident Response'), findsWidgets);

    await tester.tap(find.text('Clinic'));
    await tester.pumpAndSettle();
    expect(find.text('Clinic Appointments'), findsWidgets);
    expect(find.textContaining('Ready,'), findsOneWidget);
  });

  testWidgets('broadcast jump extends the range once and settles',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const TimelineExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Broadcast'));
    await tester.pumpAndSettle();
    expect(_visibleTimeHeaderLabels(tester), isNotEmpty);
    expect(
      _visibleTimeHeaderLabels(tester),
      everyElement(matches(RegExp(r'^\d{2}:(00|30)$'))),
    );

    final eventFinder =
        find.byKey(const ValueKey('eventCellContainer_broadcast-2'));
    expect(eventFinder, findsOneWidget);

    final before = tester.getTopLeft(eventFinder).dx;
    await tester.drag(
      find.byKey(const ValueKey('broadcast-table')),
      const Offset(-260, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final afterDrag = tester.getTopLeft(eventFinder).dx;
    expect(afterDrag, lessThan(before));
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('broadcast-extension-count-label')),
          )
          .data,
      'Range extensions: 0',
    );

    await tester.tap(find.text('Jump To Late Segment'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('broadcast-extension-count-label')),
          )
          .data,
      'Range extensions: 1',
    );
    expect(tester.takeException(), isNull);
  });
}
