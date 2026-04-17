import 'package:flutter/material.dart';

class DemoScaffold extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final String capability;
  final Widget child;
  final Widget? header;

  const DemoScaffold({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.capability,
    required this.child,
    this.header,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF0F766E),
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF334155),
                ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              capability,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF075985),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (header != null) ...[
            const SizedBox(height: 16),
            header!,
          ],
          const SizedBox(height: 16),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD7E3F4)),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x110F172A),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
