import 'package:flutter/material.dart';

import '../../theme/timeline_style.dart';

class CellBackgroundPainter extends CustomPainter {
  final DateTime startTime;
  final DateTime endTime;
  final DateTime currentTime;
  final TimelineCellStyle style;
  final double heightOffset;

  CellBackgroundPainter({
    required this.startTime,
    required this.endTime,
    required this.currentTime,
    required this.style,
    this.heightOffset = -1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final drawSize = Size(size.width, size.height + heightOffset);

    if (currentTime.isBefore(startTime)) {
      paint.color = style.emptyCellBackground.future;
      canvas.drawRect(Offset.zero & drawSize, paint);
    } else if (currentTime.isAfter(endTime)) {
      paint.color = style.emptyCellBackground.past;
      canvas.drawRect(Offset.zero & drawSize, paint);
    } else {
      final totalWidth = drawSize.width;
      final totalMs = endTime.difference(startTime).inMilliseconds;
      final elapsedMs = currentTime.difference(startTime).inMilliseconds;
      final fraction = (elapsedMs / totalMs).clamp(0.0, 1.0);
      final currentX = totalWidth * fraction;

      paint.color = style.emptyCellBackground.past;
      canvas.drawRect(Rect.fromLTWH(0, 0, currentX, drawSize.height), paint);
      paint.color = style.emptyCellBackground.future;
      canvas.drawRect(Rect.fromLTWH(currentX, 0, totalWidth - currentX, drawSize.height), paint);
    }
  }

  @override
  bool shouldRepaint(CellBackgroundPainter oldDelegate) {
    return startTime != oldDelegate.startTime ||
        endTime != oldDelegate.endTime ||
        style.emptyCellBackground.past != oldDelegate.style.emptyCellBackground.past ||
        style.emptyCellBackground.future != oldDelegate.style.emptyCellBackground.future ||
        currentTime != oldDelegate.currentTime;
  }
}
