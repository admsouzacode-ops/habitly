import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/billing/premium_controller.dart';
import 'package:habitly/billing/premium_plans.dart';
import 'package:habitly/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

const _manageSubscriptionsUrl =
    'https://play.google.com/store/account/subscriptions'
    '?sku=$premiumProductId&package=br.com.souzacode.habitly';

Future<void> openPaywall(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const PaywallScreen()));
}

Future<void> openManageSubscriptions() async {
  try {
    await launchUrl(
      Uri.parse(_manageSubscriptionsUrl),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {}
}

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    // Recarrega preços se a loja ainda não respondeu ou falhou antes.
    final s = ref.read(premiumControllerProvider);
    if (s.store != StoreStatus.loading && s.plans.isEmpty) {
      Future.microtask(
        () => ref.read(premiumControllerProvider.notifier).refresh(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PremiumState>(premiumControllerProvider, (prev, next) {
      if (next.message != null && next.messageId != prev?.messageId) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message!)));
      }
    });
    final state = ref.watch(premiumControllerProvider);
    final controller = ref.read(premiumControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    PremiumPlan? selected;
    for (final p in state.plans) {
      if (p.basePlanId == (_selected ?? annualBasePlanId)) selected = p;
    }
    selected ??= state.plans.isEmpty ? null : state.plans.first;
    final savings = annualSavingsPercent(state.plans);

    return Scaffold(
      appBar: AppBar(title: const Text('Habitly Premium')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  Icons.workspace_premium,
                  size: 40,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              state.isPremium ? 'Você é Premium 🎉' : 'Vá além com o Premium',
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Acompanhe todos os hábitos que quiser, sem distrações.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            const _Benefit(
              icon: Icons.all_inclusive,
              title: 'Hábitos ilimitados',
              subtitle: 'No plano gratuito são até 5 hábitos.',
            ),
            const _Benefit(
              icon: Icons.block,
              title: 'Sem anúncios',
              subtitle: 'Nenhum banner em nenhuma tela.',
            ),
            const _Benefit(
              icon: Icons.insights_outlined,
              title: 'Tudo o que já é seu continua',
              subtitle:
                  'Metas flexíveis, lembretes, notas, conquistas e widget.',
            ),
            const _Benefit(
              icon: Icons.favorite_outline,
              title: 'Apoie um app brasileiro independente',
              subtitle: 'Sua assinatura financia as próximas novidades.',
            ),
            const SizedBox(height: 16),
            if (state.isPremium)
              _PremiumActive(mockOnly: !state.purchased)
            else
              ..._storeSection(context, state, controller, selected, savings),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('restore-purchases'),
              onPressed: state.busy ? null : controller.restore,
              child: const Text('Restaurar compras'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _storeSection(
    BuildContext context,
    PremiumState state,
    PremiumController controller,
    PremiumPlan? selected,
    int? savings,
  ) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    if (state.store == StoreStatus.loading ||
        (state.store == StoreStatus.available &&
            state.plans.isEmpty &&
            !state.plansNotFound &&
            state.plansError == null)) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (state.store == StoreStatus.unavailable ||
        state.plans.isEmpty ||
        selected == null) {
      final msg = state.store == StoreStatus.unavailable
          ? 'O Google Play não está disponível agora. Verifique a conexão e '
                'se o app foi instalado pela Play Store.'
          : 'Os planos Premium ainda não estão disponíveis. Tente novamente '
                'em alguns minutos.';
      return [
        Card(
          key: const ValueKey('paywall-unavailable'),
          color: scheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.cloud_off_outlined, color: scheme.onSurfaceVariant),
                const SizedBox(height: 8),
                Text(msg, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => controller.refresh(recheckOwned: true),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    final cta = selected.hasTrial
        ? 'Começar ${selected.trialLabel}'
        : 'Assinar por ${selected.priceWithPeriod}';
    return [
      for (final plan in state.plans)
        _PlanCard(
          plan: plan,
          selected: plan.basePlanId == selected.basePlanId,
          savings: plan.period == PlanPeriod.annual ? savings : null,
          onTap: () => setState(() => _selected = plan.basePlanId),
        ),
      const SizedBox(height: 12),
      FilledButton(
        key: const ValueKey('paywall-subscribe'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: state.busy || state.pending
            ? null
            : () => controller.buy(selected),
        child: state.busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Text(cta, textAlign: TextAlign.center),
      ),
      if (state.pending)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Pagamento pendente de confirmação pelo Google Play.',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ),
      const SizedBox(height: 12),
      Text(
        [
          if (selected.hasTrial)
            'Teste grátis: se você não cancelar antes do fim do período, a '
                'cobrança de ${selected.priceWithPeriod} começa '
                'automaticamente.',
          'A assinatura é renovada automaticamente até ser cancelada. '
              'Cancele quando quiser em Google Play › Pagamentos e '
              'assinaturas. A cobrança é feita pela sua conta Google Play.',
        ].join(' '),
        textAlign: TextAlign.center,
        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
    ];
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
    this.savings,
  });

  final PremiumPlan plan;
  final bool selected;
  final int? savings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final annual = plan.period == PlanPeriod.annual;
    String? perMonth;
    if (annual && plan.rawPrice > 0) {
      try {
        perMonth =
            '${NumberFormat.simpleCurrency(locale: 'pt_BR', name: plan.currencyCode).format(plan.rawPrice / 12)}/mês';
      } catch (_) {}
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        key: ValueKey('plan-${plan.basePlanId}'),
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            annual ? 'Anual' : 'Mensal',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (annual)
                            _Badge(
                              savings != null
                                  ? 'Melhor valor · -$savings%'
                                  : 'Melhor valor',
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.headline,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: plan.hasTrial ? FontWeight.w600 : null,
                          color: plan.hasTrial ? scheme.primary : null,
                        ),
                      ),
                      if (perMonth != null)
                        Text(
                          'Equivale a $perMonth',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PremiumActive extends StatelessWidget {
  const _PremiumActive({required this.mockOnly});

  final bool mockOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              mockOnly
                  ? 'Premium simulado (build de teste).'
                  : 'Sua assinatura está ativa. Obrigado por apoiar o Habitly!',
              textAlign: TextAlign.center,
            ),
            if (!mockOnly) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: openManageSubscriptions,
                child: const Text('Gerenciar assinatura'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
