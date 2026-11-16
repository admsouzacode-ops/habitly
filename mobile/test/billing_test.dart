import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitly/billing/premium_controller.dart';
import 'package:habitly/billing/premium_plans.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/screens/paywall_screen.dart';
import 'package:habitly/theme/habitly_theme.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_billing.dart';
import 'support/fonts.dart';

void main() {
  group('planos do Google Play', () {
    test('usa oferta com teste grátis no anual e plano base no mensal', () {
      final plans = plansFromProductDetails(fakeHabitlyProductDetails());
      expect(plans.map((p) => p.basePlanId), ['anual', 'mensal']);
      final annual = plans.first;
      expect(annual.offerId, 'teste-7-dias');
      expect(annual.price, r'R$ 59,90');
      expect(annual.trialLabel, '7 dias grátis');
      expect(annual.headline, r'7 dias grátis, depois R$ 59,90/ano');
      final monthly = plans.last;
      expect(monthly.offerId, isNull);
      expect(monthly.hasTrial, isFalse);
      expect(monthly.headline, r'R$ 9,90/mês');
      expect(annualSavingsPercent(plans), 49);
    });

    test('sem oferta elegível cai no plano base', () {
      final plans = plansFromProductDetails(
        fakeHabitlyProductDetails(trial: false),
      );
      expect(plans.first.hasTrial, isFalse);
      expect(plans.first.headline, r'R$ 59,90/ano');
    });

    test('ignora outros produtos e lista vazia', () {
      expect(plansFromProductDetails(const []), isEmpty);
    });

    test('rótulos de período ISO 8601', () {
      expect(trialLabelFromIsoPeriod('P7D'), '7 dias grátis');
      expect(trialLabelFromIsoPeriod('P1W'), '7 dias grátis');
      expect(trialLabelFromIsoPeriod('P2W'), '14 dias grátis');
      expect(trialLabelFromIsoPeriod('P1M'), '1 mês grátis');
      expect(trialLabelFromIsoPeriod('P3M'), '3 meses grátis');
      expect(trialLabelFromIsoPeriod('xyz'), isNull);
    });
  });

  group('PremiumController', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('compra confirmada libera Premium, salva e faz acknowledge', () async {
      final gw = FakeBillingGateway();
      final c = PremiumController(prefs, gw);
      await c.start();
      expect(c.state.isPremium, isFalse);
      expect(c.state.plans, hasLength(2));
      await c.buy(c.state.plans.first);
      expect(gw.bought.single.basePlanId, 'anual');
      gw.emit([fakePurchase(PurchaseStatus.purchased)]);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.isPremium, isTrue);
      expect(c.state.busy, isFalse);
      expect(prefs.getBool(premiumPurchasedPrefKey), isTrue);
      expect(gw.completed, hasLength(1));
      c.dispose();
    });

    test('pendente não libera; cancelado/erro liberam o botão', () async {
      final gw = FakeBillingGateway();
      final c = PremiumController(prefs, gw);
      await c.start();
      gw.emit([fakePurchase(PurchaseStatus.pending, pendingComplete: false)]);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.pending, isTrue);
      expect(c.state.isPremium, isFalse);
      gw.emit([fakePurchase(PurchaseStatus.canceled, pendingComplete: false)]);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.pending, isFalse);
      expect(c.state.busy, isFalse);
      c.dispose();
    });

    test('ao abrir: assinatura ativa na Play mantém Premium', () async {
      final gw = FakeBillingGateway(
        owned: [fakePurchase(PurchaseStatus.purchased)],
      );
      final c = PremiumController(prefs, gw);
      await c.start();
      expect(c.state.isPremium, isTrue);
      expect(gw.completed, hasLength(1)); // acknowledge pendente
      c.dispose();
    });

    test('ao abrir: assinatura expirada remove Premium', () async {
      await prefs.setBool(premiumPurchasedPrefKey, true);
      final c = PremiumController(prefs, FakeBillingGateway());
      expect(c.state.isPremium, isTrue);
      await c.start();
      expect(c.state.isPremium, isFalse);
      c.dispose();
    });

    test('ao abrir offline: mantém o último estado salvo', () async {
      await prefs.setBool(premiumPurchasedPrefKey, true);
      final c = PremiumController(
        prefs,
        FakeBillingGateway(ownedError: 'SERVICE_UNAVAILABLE'),
      );
      await c.start();
      expect(c.state.isPremium, isTrue);
      final c2 = PremiumController(prefs, FakeBillingGateway(available: false));
      await c2.start();
      expect(c2.state.isPremium, isTrue);
      expect(c2.state.store, StoreStatus.unavailable);
      c.dispose();
      c2.dispose();
    });

    test('restaurar sem assinatura avisa o usuário', () async {
      final gw = FakeBillingGateway();
      final c = PremiumController(prefs, gw);
      await c.start();
      await c.restore();
      expect(gw.restoreCalls, 1);
      expect(c.state.message, contains('Nenhuma assinatura ativa'));
      gw.owned = [fakePurchase(PurchaseStatus.purchased)];
      await c.restore();
      expect(c.state.isPremium, isTrue);
      expect(c.state.message, contains('restaurada'));
      c.dispose();
    });
  });

  group('Paywall', () {
    setUpAll(loadRealFonts);

    Future<FakeBillingGateway> pumpPaywall(
      WidgetTester tester,
      FakeBillingGateway gw, {
      double width = 360,
      double scale = 1.0,
    }) async {
      tester.view.physicalSize = Size(width, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          billingGatewayProvider.overrideWithValue(gw),
        ],
      );
      addTearDown(container.dispose);
      await container.read(premiumControllerProvider.notifier).start();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildHabitlyTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const PaywallScreen(),
          ),
        ),
      );
      await tester.pump();
      return gw;
    }

    testWidgets('mostra preços da loja, teste grátis e anual destacado', (
      tester,
    ) async {
      final gw = await pumpPaywall(tester, FakeBillingGateway());
      expect(tester.takeException(), isNull);
      expect(find.text('Hábitos ilimitados'), findsOneWidget);
      expect(find.text('Sem anúncios'), findsOneWidget);
      expect(find.text(r'7 dias grátis, depois R$ 59,90/ano'), findsOneWidget);
      expect(find.text(r'R$ 9,90/mês'), findsOneWidget);
      expect(find.textContaining('Melhor valor'), findsOneWidget);
      expect(find.text('Começar 7 dias grátis'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('plan-mensal')));
      await tester.pump();
      expect(find.text(r'Assinar por R$ 9,90/mês'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('paywall-subscribe')),
      );
      await tester.tap(find.byKey(const ValueKey('paywall-subscribe')));
      await tester.pump();
      expect(gw.bought.single.basePlanId, 'mensal');
    });

    testWidgets('loja indisponível mostra aviso sem quebrar', (tester) async {
      await pumpPaywall(tester, FakeBillingGateway(available: false));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('paywall-unavailable')), findsOneWidget);
      expect(
        find.textContaining('Google Play não está disponível'),
        findsOneWidget,
      );
    });

    testWidgets('produto não encontrado mostra aviso', (tester) async {
      await pumpPaywall(tester, FakeBillingGateway(plans: []));
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('ainda não estão disponíveis'),
        findsOneWidget,
      );
    });

    testWidgets('sem overflow em 360dp com texto x1.3', (tester) async {
      await pumpPaywall(tester, FakeBillingGateway(), scale: 1.3);
      expect(tester.takeException(), isNull);
    });
  });
}
