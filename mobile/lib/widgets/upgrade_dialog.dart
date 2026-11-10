import 'package:flutter/material.dart';

Future<void> showUpgradeDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Recurso Premium'),
        content: const Text(
          'No plano gratuito você pode acompanhar até 5 hábitos.\n\n'
          'Assine o Premium para criar hábitos ilimitados e usar o app '
          'sem anúncios.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'A assinatura ainda não está disponível nesta versão.',
                  ),
                ),
              );
            },
            child: const Text('Ver Premium'),
          ),
        ],
      );
    },
  );
}
