import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _showTestToggle = false;

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.offline_pin_outlined),
            title: Text('Modo offline'),
            subtitle: Text(
              'Seus hábitos e registros ficam neste aparelho, mesmo sem internet.',
            ),
          ),
          ListTile(
            leading: Icon(premium ? Icons.workspace_premium : Icons.star_border),
            title: const Text('Plano'),
            subtitle: Text(premium ? 'Premium (teste)' : 'Gratuito · até 5 hábitos'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Habitly'),
            subtitle: const Text('Versão 1.0.0'),
            onLongPress: () {
              setState(() => _showTestToggle = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opções de teste liberadas.'),
                ),
              );
            },
          ),
          if (_showTestToggle)
            SwitchListTile(
              secondary: const Icon(Icons.science_outlined),
              title: const Text('Simular assinatura Premium'),
              subtitle: const Text('Toggle oculto para testes. Não cobra nada.'),
              value: premium,
              onChanged: (value) =>
                  ref.read(premiumProvider.notifier).setPremium(value),
            ),
        ],
      ),
    );
  }
}
