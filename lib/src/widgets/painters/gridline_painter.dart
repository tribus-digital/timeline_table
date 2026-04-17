import 'package:flutter/material.dart';

import '../../theme/timeline_style.dart';

class GridLinePainter extends CustomPainter {
  final int startingColumn;
  final int mergeSpan;
  final double widthPerStep;
  final int displayedFactor;
  final DateTime currentTime;
  final DateTime startTime;
  final DateTime endTime;
  final TimelineCellStyle style;
  final bool showHorizontalGridline;

  const GridLinePainter({
    required this.startingColumn,
    required this.mergeSpan,
    required this.widthPerStep,
    required this.displayedFactor,
    required this.startTime,
    required this.endTime,
    required this.currentTime,
    required this.style,
    required this.showHorizontalGridline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = style.gridLineWidth
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 6.0;

    final cellStart = startingColumn;
    final cellEnd = startingColumn + mergeSpan;
    final cellWidth = mergeSpan * widthPerStep;

    var n = ((cellStart - 1) ~/ displayedFactor) + 1;
    while (true) {
      final boundary = 1 + n * displayedFactor;
      if (boundary > cellEnd) break;
      final x = (boundary - cellStart) * widthPerStep;

      final Color gridColor;
      if (x >= 0 && x <= cellWidth && cellWidth > 0) {
        final fraction = x / cellWidth;
        final totalEventMs = endTime.difference(startTime).inMilliseconds;
        final eventMsOffset = (totalEventMs * fraction).round();
        final gridLineEventTime = startTime.add(Duration(milliseconds: eventMsOffset));
        gridColor = currentTime.isBefore(gridLineEventTime) ? style.gridline.future : style.gridline.past;
      } else {
        gridColor = currentTime.isBefore(startTime)
            ? style.gridline.future
            : currentTime.isAfter(endTime)
                ? style.gridline.past
                : style.gridline.future;
      }
      paint.color = gridColor;

      var startY = -1.0;
      while (startY < size.height) {
        canvas.drawLine(Offset(x, startY), Offset(x, startY + dashWidth), paint);
        startY += dashWidth + dashSpace;
      }
      n++;
    }

    if (showHorizontalGridline) {
      final y = size.height - 0.5;
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
  bool shouldRepaint(GridLinePainter oldDelegate) {
    return startingColumn != oldDelegate.startingColumn ||
        mergeSpan != oldDelegate.mergeSpan ||
        widthPerStep != oldDelegate.widthPerStep ||
        displayedFactor != oldDelegate.displayedFactor ||
        style.gridLineWidth != oldDelegate.style.gridLineWidth ||
        startTime != oldDelegate.startTime ||
        endTime != oldDelegate.endTime ||
        currentTime != oldDelegate.currentTime ||
        style.gridline.past != oldDelegate.style.gridline.past ||
        style.gridline.future != oldDelegate.style.gridline.future ||
        showHorizontalGridline != oldDelegate.showHorizontalGridline;
  }
}
