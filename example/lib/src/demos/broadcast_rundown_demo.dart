import 'package:flutter/material.dart';
import 'package:timeline_table/timeline_table.dart';

import '../app/demo_scaffold.dart';
import '../demo/demo_data.dart';
import '../demo/demo_models.dart';

class BroadcastRundownDemo extends StatefulWidget {
  const BroadcastRundownDemo({super.key});

  @override
  State<BroadcastRundownDemo> createState() => _BroadcastRundownDemoState();
}

class _BroadcastRundownDemoState extends State<BroadcastRundownDemo> {
  final TimelineTableController<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>> _controller =
      TimelineTableController<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>();
  late final DateTime _anchorTime;
  late final TimelineConfig _config;
  late final TimelineData<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>> _data;
  int _extensionCount = 0;

  @override
  void initState() {
    super.initState();
    _anchorTime = DateTime.now().toUtc();
    _config = buildHourlyConfig(
      _anchorTime,
      before: const Duration(hours: 1),
      after: const Duration(hours: 2),
      gridResolution: const Duration(minutes: 15),
      timeHeaderResolution: const Duration(minutes: 30),
      pixelsPerStep: 8,
    );
    _data = buildBroadcastData(_anchorTime);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      eyebrow: 'Live State',
      title: 'Broadcast Rundown',
      description:
          'This control room view highlights what is live right now, applies a local timeline theme override for the live playhead and header chrome, and extends the timeline only when operators reach the edge or jump to a late-running segment outside the initial window.',
      capability: 'Active-state rendering + local theme overrides',
      header: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: _controller.scrollToNow,
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Center Live Window'),
          ),
          FilledButton.tonal(
            onPressed: () {
              _controller.scrollToEventById('broadcast-5');
            },
            child: const Text('Jump To Late Segment'),
          ),
          Chip(
            avatar: const Icon(Icons.expand_outlined, size: 18),
            label: Text(
              'Range extensions: $_extensionCount',
              key: const ValueKey('broadcast-extension-count-label'),
            ),
          ),
        ],
      ),
      child: TimelineTable<DemoTimelineEvent, TimelineRow<DemoTimelineEvent>>(
        key: const ValueKey('broadcast-table'),
        controller: _controller,
        config: _config,
        data: _data,
        enableInfiniteScroll: true,
        extensionChunk: const Duration(hours: 6),
        extensionThresholdPx: 80,
        onTimelineRangeExtended: (newStart, newEnd, delta, toLeft) {
          if (!mounted) return;
          setState(() => _extensionCount++);
        },
        style: const TimelineTableStyle(
          pinnedColumnWidth: 168,
          rowHeight: 74,
          currentTimeIndicatorStyle: TimelineCurrentTimeIndicatorStyle(
            color: Color(0xFFBE123C),
            width: 4,
          ),
          pinnedHeaderStyle: TimelinePinnedHeaderStyle(
            activeIconColor: Color(0xFFBE123C),
            inactiveIconColor: Color(0xFFFDA4AF),
            dividerColor: Color(0xFFFBCFE8),
          ),
          cellStyle: TimelineCellStyle(
            hoverBorderColor: Color(0xFFFFE4E6),
            focusBorderColor: Color(0xFF881337),
            focusBorderWidth: 3,
            hoverOverlayColor: Color(0x14BE123C),
            focusOverlayColor: Color(0x1FBE123C),
            splashColor: Color(0x18BE123C),
            highlightColor: Color(0x12BE123C),
            hoverShadowColor: Color(0x26BE123C),
            hoverShadowBlurRadius: 20,
            hoverShadowOffset: Offset(0, 8),
          ),
        ),
        eventCellBuilder: (context, details) {
          final style = statusStyle(details.event.status, details.defaultCellStyle);
          final detailLabel = details.isActive ? 'LIVE' : details.event.detail;
          return EventCellView<DemoTimelineEvent>(
            event: details.event,
            now: details.now,
            displayStart: details.displayStart,
            style: style,
            onTap: details.handleTap,
            onLongPress: details.handleLongPress,
            childBuilder: (context, cell) => LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                if (maxWidth < 56) {
                  return Center(
                    child: Icon(
                      details.event.icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  );
                }

                final showDetail = maxWidth >= 150;
                final primaryText = maxWidth >= 100 ? details.event.label : detailLabel;

                return Row(
                  children: [
                    Icon(details.event.icon, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        primaryText,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (showDetail) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          detailLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
