import 'package:flutter/material.dart';
import 'package:habitly/screens/paywall_screen.dart';

Future<void> showUpgradeDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Recurso Premium'),
        content: const Text(
          'No plano gratuito você pode acompanhar até 5 hábitos.\n\n'
          'Assine o Premium para criar hábitos ilimitados e usar o app '
          'sem anúncios.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              openPaywall(context);
            },
            child: const Text('Ver Premium'),
          ),
        ],
      );
    },
  );
}
