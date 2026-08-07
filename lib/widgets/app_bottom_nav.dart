import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Dijeljena bottom navigacija koja se koristi na svim glavnim ekranima.
/// Umjesto da svaki ekran ponovno piše istu listu destinacija, definiramo
/// je JEDNOM ovdje. Kad kasnije dodamo Obveze/Kalendar/Statistiku,
/// mijenjamo samo ovu datoteku.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  static const _routes = [
    '/dashboard',
    '/habits',
    '/obligations',
    '/calendar',
    '/statistics',
  ];
  // TODO: proširiti kad dodamo obligations/calendar/statistics ekrane

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => context.go(_routes[index]),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Početna',
        ),
        NavigationDestination(
          icon: Icon(Icons.repeat_outlined),
          selectedIcon: Icon(Icons.repeat),
          label: 'Navike',
        ),
        NavigationDestination(
          icon: Icon(Icons.task_alt_outlined),
          selectedIcon: Icon(Icons.task_alt),
          label: 'Obveze',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Kalendar',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Statistika',
        ),
      ],
    );
  }
}
