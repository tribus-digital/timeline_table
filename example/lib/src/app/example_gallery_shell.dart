import 'package:flutter/material.dart';

import '../demos/broadcast_rundown_demo.dart';
import '../demos/clinic_appointments_demo.dart';
import '../demos/incident_response_demo.dart';
import '../demos/product_roadmap_demo.dart';
import '../demos/transit_operations_demo.dart';

class ExampleGalleryShell extends StatefulWidget {
  const ExampleGalleryShell({super.key});

  @override
  State<ExampleGalleryShell> createState() => _ExampleGalleryShellState();
}

class _ExampleGalleryShellState extends State<ExampleGalleryShell>
    with SingleTickerProviderStateMixin {
  static const List<_GalleryDestination> _destinations = [
    _GalleryDestination(
      label: 'Transit',
      title: 'Transit Operations',
      subtitle: 'Default usage with grouped routes and departures.',
      icon: Icons.train_outlined,
    ),
    _GalleryDestination(
      label: 'Roadmap',
      title: 'Product Roadmap',
      subtitle: 'Builder-first customization for headers and milestones.',
      icon: Icons.alt_route,
    ),
    _GalleryDestination(
      label: 'Clinic',
      title: 'Clinic Appointments',
      subtitle: 'Controller-driven navigation for busy daily schedules.',
      icon: Icons.local_hospital_outlined,
    ),
    _GalleryDestination(
      label: 'Broadcast',
      title: 'Broadcast Rundown',
      subtitle: 'Live state tracking with edge-triggered range extension.',
      icon: Icons.live_tv_outlined,
    ),
    _GalleryDestination(
      label: 'Incident',
      title: 'Incident Response',
      subtitle: 'Desktop/web input, focus, and accessibility patterns.',
      icon: Icons.security_update_warning_outlined,
    ),
  ];

  static const List<Widget> _pages = [
    TransitOperationsDemo(),
    ProductRoadmapDemo(),
    ClinicAppointmentsDemo(),
    BroadcastRundownDemo(),
    IncidentResponseDemo(),
  ];

  late final TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _destinations.length, vsync: this)
      ..addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabSelection)
      ..dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    if (_selectedIndex == _tabController.index) return;
    setState(() => _selectedIndex = _tabController.index);
  }

  void _selectIndex(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destinations[_selectedIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 1100;
        return Scaffold(
          appBar: AppBar(
            title: const Text('timeline_table example gallery'),
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            bottom: useRail
                ? null
                : TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: [
                      for (final item in _destinations)
                        Tab(text: item.label, icon: Icon(item.icon)),
                    ],
                  ),
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8FBFF), Color(0xFFF3F6FB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: useRail
                ? Row(
                    children: [
                      SafeArea(
                        child: NavigationRail(
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: _selectIndex,
                          minWidth: 88,
                          labelType: NavigationRailLabelType.all,
                          leading: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(
                                    Icons.view_timeline_outlined,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Explore varied timeline workloads',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFF475569),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          destinations: [
                            for (final item in _destinations)
                              NavigationRailDestination(
                                icon: Icon(item.icon),
                                label: Text(item.label),
                              ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: _pages,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _GalleryIntroBanner(destination: destination),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: _pages,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _GalleryDestination {
  final String label;
  final String title;
  final String subtitle;
  final IconData icon;

  const _GalleryDestination({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _GalleryIntroBanner extends StatelessWidget {
  final _GalleryDestination destination;

  const _GalleryIntroBanner({required this.destination});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF155E75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(destination.icon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    destination.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              destination.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
