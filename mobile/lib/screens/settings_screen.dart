import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/screens/achievements_screen.dart';
import 'package:habitly/screens/paywall_screen.dart';

const appVersionLabel = 'Versão 1.0.0 (8)';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _showTestToggle = false;
  bool? _exactAllowed;

  @override
  void initState() {
    super.initState();
    _refreshExact();
  }

  Future<void> _refreshExact() async {
    if (!ref.read(reminderSyncEnabledProvider)) return;
    final allowed = await ref.read(reminderServiceProvider).canScheduleExact();
    if (mounted) setState(() => _exactAllowed = allowed);
  }

  Future<void> _resync() async {
    final habits = ref.read(habitsProvider).valueOrNull;
    if (habits == null || !ref.read(reminderSyncEnabledProvider)) return;
    await ref
        .read(reminderServiceProvider)
        .sync(
          toReminderHabits(habits),
          enabled: ref.read(remindersEnabledProvider),
        );
  }

  Future<void> _toggleReminders(bool value) async {
    if (value && ref.read(reminderSyncEnabledProvider)) {
      final granted = await ref
          .read(reminderServiceProvider)
          .requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permita as notificações do Habitly nas configurações do '
              'Android para receber os lembretes.',
            ),
          ),
        );
      }
    }
    await ref.read(remindersEnabledProvider.notifier).set(value);
  }

  Future<void> _askExact() async {
    await ref.read(reminderServiceProvider).requestExactPermission();
    await _refreshExact();
    await _resync();
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumProvider);
    final reminders = ref.watch(remindersEnabledProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          const _SectionHeader('Lembretes'),
          SwitchListTile(
            secondary: Icon(
              reminders
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              color: reminders ? scheme.primary : null,
            ),
            title: const Text('Lembretes de hábitos'),
            subtitle: Text(
              reminders
                  ? 'Você recebe um aviso no horário definido em cada hábito.'
                  : 'Nenhum lembrete será enviado.',
            ),
            value: reminders,
            onChanged: _toggleReminders,
          ),
          if (reminders && _exactAllowed == false)
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Avisar no horário exato'),
              subtitle: const Text(
                'Sem essa permissão o Android pode atrasar o aviso alguns '
                'minutos. Toque para permitir.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _askExact,
            ),
          const Divider(),
          const _SectionHeader('Progresso'),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Conquistas'),
            subtitle: const Text('Medalhas por sequências e conclusões.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AchievementsScreen(),
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.widgets_outlined),
            title: Text('Widget na tela inicial'),
            subtitle: Text(
              'Segure um espaço vazio da tela inicial, toque em Widgets e '
              'arraste o Habitly para marcar hábitos sem abrir o app.',
            ),
          ),
          const Divider(),
          const _SectionHeader('Conta'),
          const ListTile(
            leading: Icon(Icons.offline_pin_outlined),
            title: Text('Modo offline'),
            subtitle: Text(
              'Seus hábitos e registros ficam salvos neste aparelho, mesmo '
              'sem internet.',
            ),
          ),
          ListTile(
            key: const ValueKey('settings-plan'),
            leading: Icon(
              premium ? Icons.workspace_premium : Icons.star_border,
              color: premium ? scheme.primary : null,
            ),
            title: const Text('Plano'),
            subtitle: Text(
              premium
                  ? 'Premium · hábitos ilimitados, sem anúncios'
                  : 'Gratuito · até 5 hábitos. Toque para ver o Premium.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openPaywall(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Habitly'),
            subtitle: const Text(appVersionLabel),
            onLongPress: !kDebugMode
                ? null
                : () {
                    setState(() => _showTestToggle = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opções de teste liberadas.'),
                      ),
                    );
                  },
          ),
          // Toggle de simulação só existe em builds de debug.
          if (kDebugMode && _showTestToggle)
            SwitchListTile(
              secondary: const Icon(Icons.science_outlined),
              title: const Text('Simular assinatura Premium'),
              subtitle: const Text('Só em debug. Não cobra nada.'),
              value: ref.watch(premiumControllerProvider).mock,
              onChanged: (value) =>
                  ref.read(premiumControllerProvider.notifier).setMock(value),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
