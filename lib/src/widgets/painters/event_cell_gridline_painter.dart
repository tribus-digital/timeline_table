import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/timeline_style.dart';

class EventCellGridLinePainter extends CustomPainter {
  final TimelineCellStyle style;
  final int startingColumn;
  final int mergeSpan;
  final double widthPerStep;
  final int displayedFactor;
  final double cellHeight;
  final double eventWidth;
  final double eventOffsetX;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime currentTime;
  final DateTime eventStart;
  final DateTime eventEnd;
  final bool showHorizontalGridline;

  const EventCellGridLinePainter({
    required this.style,
    required this.startingColumn,
    required this.mergeSpan,
    required this.widthPerStep,
    required this.displayedFactor,
    required this.cellHeight,
    required this.eventWidth,
    required this.eventOffsetX,
    required this.currentTime,
    required this.startTime,
    required this.endTime,
    required this.eventStart,
    required this.eventEnd,
    required this.showHorizontalGridline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = style.gridLineWidth;
    const dashWidth = 6.0;
    const dashSpace = 6.0;

    void drawDashedVertical(double x, double y0, double y1) {
      var y = y0;
      while (y < y1) {
        final segmentEnd = min(y + dashWidth, y1);
        canvas.drawLine(Offset(x, y), Offset(x, segmentEnd), paint);
        y += dashWidth + dashSpace;
      }
    }

    final cellStart = startingColumn;
    final cellEnd = startingColumn + mergeSpan;
    var n = ((cellStart - 1) ~/ displayedFactor) + 1;

    while (true) {
      final boundary = 1 + n * displayedFactor;
      if (boundary > cellEnd) break;
      final x = (boundary - cellStart) * widthPerStep;

      final eventLeft = eventOffsetX;
      final eventRight = eventOffsetX + eventWidth;
      if (x >= eventLeft && x <= eventRight && eventWidth > 0) {
        final fraction = (x - eventLeft) / eventWidth;
        final totalMs = eventEnd.difference(eventStart).inMilliseconds;
        final offsetMs = (totalMs * fraction).round();
        final markTime = eventStart.add(Duration(milliseconds: offsetMs));
        paint.color = currentTime.isBefore(markTime)
            ? style.gridline.future
            : style.gridline.past;
      } else {
        paint.color = currentTime.isBefore(eventStart)
            ? style.gridline.future
            : currentTime.isAfter(eventEnd)
                ? style.gridline.past
                : style.gridline.future;
      }

      if ((x - eventLeft).abs() <= style.horizontalEventMargin ||
          (x - eventRight).abs() <= style.horizontalEventMargin) {
        drawDashedVertical(x, -1, cellHeight - 1);
      } else {
        drawDashedVertical(x, -1, style.verticalEventMargin);
        drawDashedVertical(
            x, cellHeight - style.verticalEventMargin - 0.5, cellHeight - 1);
      }

      n++;
    }

    if (showHorizontalGridline) {
      final y = cellHeight - 0.5;
      if (currentTime.isBefore(startTime)) {
        paint.color = style.gridline.future;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      } else if (currentTime.isAfter(endTime)) {
        paint.color = style.gridline.past;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      } else {
        final totalMs = endTime.difference(startTime).inMilliseconds;
        final elapsedMs = currentTime.difference(startTime).inMilliseconds;
        final fraction = elapsedMs / totalMs;
        final transitionX = fraction * size.width;
        paint.color = style.gridline.past;
        canvas.drawLine(Offset(0, y), Offset(transitionX, y), paint);
        paint.color = style.gridline.future;
        canvas.drawLine(Offset(transitionX, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(EventCellGridLinePainter old) {
    return startingColumn != old.startingColumn ||
        mergeSpan != old.mergeSpan ||
        widthPerStep != old.widthPerStep ||
        displayedFactor != old.displayedFactor ||
        cellHeight != old.cellHeight ||
        eventWidth != old.eventWidth ||
        eventOffsetX != old.eventOffsetX ||
        style.verticalEventMargin != old.style.verticalEventMargin ||
        style.horizontalEventMargin != old.style.horizontalEventMargin ||
        style.gridLineWidth != old.style.gridLineWidth ||
        startTime != old.startTime ||
        endTime != old.endTime ||
        currentTime != old.currentTime ||
        style.gridline.past != old.style.gridline.past ||
        style.gridline.future != old.style.gridline.future ||
        showHorizontalGridline != old.showHorizontalGridline;
  }
}
