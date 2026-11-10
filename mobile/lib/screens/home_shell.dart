import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/screens/calendar_screen.dart';
import 'package:habitly/screens/stats_screen.dart';
import 'package:habitly/screens/today_screen.dart';
import 'package:habitly/widgets/ad_banner.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  final _pages = const [TodayScreen(), CalendarScreen(), StatsScreen()];

  @override
  Widget build(BuildContext context) {
    // Mantém os lembretes agendados em sincronia com os hábitos.
    ref.watch(reminderSyncProvider);
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HabitlyAdBanner(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.wb_sunny_outlined),
                selectedIcon: Icon(Icons.wb_sunny),
                label: 'Hoje',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Histórico',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Estatísticas',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
