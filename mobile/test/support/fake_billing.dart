import 'dart:async';

import 'package:habitly/billing/billing_gateway.dart';
import 'package:habitly/billing/premium_plans.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

PricingPhaseWrapper phase(String period, int micros, String formatted) =>
    PricingPhaseWrapper(
      billingCycleCount: micros == 0 ? 1 : 0,
      billingPeriod: period,
      formattedPrice: formatted,
      priceAmountMicros: micros,
      priceCurrencyCode: 'BRL',
      recurrenceMode: micros == 0
          ? RecurrenceMode.finiteRecurring
          : RecurrenceMode.infiniteRecurring,
    );

SubscriptionOfferDetailsWrapper offer(
  String basePlanId,
  List<PricingPhaseWrapper> phases, {
  String? offerId,
}) => SubscriptionOfferDetailsWrapper(
  basePlanId: basePlanId,
  offerId: offerId,
  offerTags: const [],
  offerIdToken: 'token-$basePlanId-${offerId ?? 'base'}',
  pricingPhases: phases,
);

/// Simula o que o Google Play devolve para `habitly_premium` com
/// mensal R$ 9,90, anual R$ 59,90 e oferta de 7 dias grátis no anual.
List<GooglePlayProductDetails> fakeHabitlyProductDetails({bool trial = true}) {
  final wrapper = ProductDetailsWrapper(
    description: 'Hábitos ilimitados e sem anúncios',
    name: 'Habitly Premium',
    productId: premiumProductId,
    productType: ProductType.subs,
    title: 'Habitly Premium (Habitly)',
    subscriptionOfferDetails: [
      offer(monthlyBasePlanId, [phase('P1M', 9900000, r'R$ 9,90')]),
      offer(annualBasePlanId, [phase('P1Y', 59900000, r'R$ 59,90')]),
      if (trial)
        offer(annualBasePlanId, [
          phase('P7D', 0, 'Grátis'),
          phase('P1Y', 59900000, r'R$ 59,90'),
        ], offerId: 'teste-7-dias'),
    ],
  );
  return GooglePlayProductDetails.fromProductDetails(wrapper);
}

PurchaseDetails fakePurchase(
  PurchaseStatus status, {
  bool pendingComplete = true,
}) {
  return PurchaseDetails(
    purchaseID: 'GPA.1234',
    productID: premiumProductId,
    verificationData: PurchaseVerificationData(
      localVerificationData: '{}',
      serverVerificationData: 'purchase-token',
      source: 'google_play',
    ),
    transactionDate: '0',
    status: status,
  )..pendingCompletePurchase = pendingComplete;
}

class FakeBillingGateway implements BillingGateway {
  FakeBillingGateway({
    this.available = true,
    List<PremiumPlan>? plans,
    this.owned = const [],
    this.ownedError,
  }) : plans = plans ?? plansFromProductDetails(fakeHabitlyProductDetails());

  bool available;
  List<PremiumPlan> plans;
  List<PurchaseDetails> owned;
  String? ownedError;
  final bought = <PremiumPlan>[];
  final completed = <PurchaseDetails>[];
  int restoreCalls = 0;
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  void emit(List<PurchaseDetails> purchases) => _controller.add(purchases);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<PlansQuery> queryPlans() async =>
      PlansQuery(plans: plans, notFound: plans.isEmpty);

  @override
  Future<bool> buy(PremiumPlan plan) async {
    bought.add(plan);
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }

  @override
  Future<OwnedQuery> queryOwned() async =>
      OwnedQuery(purchases: owned, error: ownedError);

  @override
  Future<void> restorePurchases() async {
    restoreCalls++;
  }
}
