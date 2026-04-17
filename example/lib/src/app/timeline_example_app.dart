import 'package:flutter/material.dart';
import 'package:timeline_table/timeline_table.dart';

import 'example_gallery_shell.dart';

class TimelineExampleApp extends StatelessWidget {
  const TimelineExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0E7490),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F7FB),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        extensions: const <ThemeExtension<dynamic>>[
          TimelineThemeData(
            tableStyle: TimelineTableStyle(
              currentTimeIndicatorStyle: TimelineCurrentTimeIndicatorStyle(
                color: Color(0xFF0F766E),
                width: 3,
              ),
              pinnedHeaderStyle: TimelinePinnedHeaderStyle(
                activeIconColor: Color(0xFF0F766E),
                inactiveIconColor: Color(0xFF94A3B8),
                labelStyle: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
                dividerColor: Color(0xFFCBD5E1),
              ),
              cellStyle: TimelineCellStyle(
                hoverBorderColor: Color(0xFFCCFBF1),
                hoverBorderWidth: 1.5,
                focusBorderColor: Color(0xFF164E63),
                focusBorderWidth: 3,
                hoverOverlayColor: Color(0x140F766E),
                focusOverlayColor: Color(0x220F766E),
                splashColor: Color(0x1A0F766E),
                highlightColor: Color(0x140F766E),
                hoverShadowColor: Color(0x180F172A),
                hoverShadowBlurRadius: 18,
                hoverShadowOffset: Offset(0, 8),
              ),
            ),
          ),
        ],
      ),
      home: const ExampleGalleryShell(),
    );
  }
}
