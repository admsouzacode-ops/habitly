import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/achievements.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/screens/achievements_screen.dart';
import 'package:habitly/screens/calendar_screen.dart';
import 'package:habitly/screens/stats_screen.dart';
import 'package:habitly/screens/today_screen.dart';
import 'package:habitly/services/home_widget_service.dart';
import 'package:habitly/widgets/ad_banner.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _index = 0;
  Timer? _widgetDebounce;

  final _pages = const [TodayScreen(), CalendarScreen(), StatsScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Assinatura: escuta compras e revalida o Premium no Google Play.
    Future.microtask(() {
      if (mounted) ref.read(premiumControllerProvider.notifier).start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetDebounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // O widget da tela inicial grava por outra conexão do banco; ao voltar
      // para o app recarrega tudo (o valor anterior fica na tela enquanto isso).
      ref.invalidate(habitSnapshotProvider);
      ref.invalidate(habitsProvider);
    }
  }

  void _onSnapshot(HabitSnapshot snapshot) {
    if (ref.read(homeWidgetSyncEnabledProvider)) {
      _widgetDebounce?.cancel();
      _widgetDebounce = Timer(
        const Duration(milliseconds: 300),
        () => syncHomeWidget(snapshot),
      );
    }
    _checkAchievements(snapshot);
  }

  Future<void> _checkAchievements(HabitSnapshot snapshot) async {
    final computed = computeUnlocked(snapshot, DateTime.now());
    final fresh = await ref
        .read(achievementLedgerProvider.notifier)
        .record(computed);
    if (fresh.isEmpty || !mounted) return;
    final text = fresh.length == 1
        ? '${fresh.first.emoji} Conquista desbloqueada: ${fresh.first.title}!'
        : '🏆 Você desbloqueou ${fresh.length} conquistas: '
              '${fresh.map((a) => a.emoji).join(' ')}';
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        key: const ValueKey('achievement-snackbar'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        // Com action o SnackBar fica na tela por padrão (persist) e cobre o
        // botão "Novo hábito"; aqui ele some sozinho.
        persist: false,
        content: Text(text),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mantém os lembretes agendados em sincronia com os hábitos.
    ref.watch(reminderSyncProvider);
    ref.listen<AsyncValue<HabitSnapshot>>(habitSnapshotProvider, (_, next) {
      final data = next.valueOrNull;
      if (data != null && !next.isLoading) _onSnapshot(data);
    });
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
