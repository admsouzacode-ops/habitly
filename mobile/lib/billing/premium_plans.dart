import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Assinatura única na Play Console, com dois planos base.
const premiumProductId = 'habitly_premium';
const monthlyBasePlanId = 'mensal';
const annualBasePlanId = 'anual';

enum PlanPeriod { monthly, annual }

/// Um plano pronto para exibir/comprar. Preços sempre vêm da loja
/// (ProductDetails), já formatados na moeda do usuário.
class PremiumPlan {
  const PremiumPlan({
    required this.basePlanId,
    required this.period,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    this.trialLabel,
    this.offerId,
    this.purchaseHandle,
  });

  final String basePlanId;
  final PlanPeriod period;

  /// Preço recorrente formatado, ex.: "R$ 59,90".
  final String price;
  final double rawPrice;
  final String currencyCode;

  /// Ex.: "7 dias grátis" quando há oferta de teste grátis elegível.
  final String? trialLabel;
  final String? offerId;

  /// ProductDetails (GooglePlayProductDetails) da oferta escolhida.
  final ProductDetails? purchaseHandle;

  bool get hasTrial => trialLabel != null;
  String get periodSuffix => period == PlanPeriod.annual ? '/ano' : '/mês';
  String get priceWithPeriod => '$price$periodSuffix';

  /// "7 dias grátis, depois R$ 59,90/ano" ou só "R$ 59,90/ano".
  String get headline =>
      hasTrial ? '$trialLabel, depois $priceWithPeriod' : priceWithPeriod;
}

/// "P7D" -> "7 dias grátis", "P1W" -> "1 semana grátis", "P1M" -> "1 mês grátis".
String? trialLabelFromIsoPeriod(String period) {
  final m = RegExp(
    r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$',
  ).firstMatch(period);
  if (m == null) return null;
  final y = int.tryParse(m.group(1) ?? '') ?? 0;
  final mo = int.tryParse(m.group(2) ?? '') ?? 0;
  final w = int.tryParse(m.group(3) ?? '') ?? 0;
  final d = int.tryParse(m.group(4) ?? '') ?? 0;
  String unit(int n, String one, String many) => '$n ${n == 1 ? one : many}';
  final String text;
  if (y > 0 && mo == 0 && w == 0 && d == 0) {
    text = unit(y, 'ano', 'anos');
  } else if (mo > 0 && w == 0 && d == 0 && y == 0) {
    text = unit(mo, 'mês', 'meses');
  } else if (w > 0 && d == 0 && y == 0 && mo == 0) {
    text = unit(w * 7, 'dia', 'dias');
  } else if (d > 0 || w > 0) {
    text = unit(w * 7 + d, 'dia', 'dias');
  } else {
    return null;
  }
  return '$text grátis';
}

PlanPeriod? _periodFor(String basePlanId) => switch (basePlanId) {
  monthlyBasePlanId => PlanPeriod.monthly,
  annualBasePlanId => PlanPeriod.annual,
  _ => null,
};

/// Converte o retorno do Google Play (uma entrada por plano base/oferta) nos
/// planos exibidos: para cada plano base usa a oferta com teste grátis quando
/// o usuário é elegível; senão, o próprio plano base. Anual primeiro.
List<PremiumPlan> plansFromProductDetails(Iterable<ProductDetails> details) {
  final byBase = <String, PremiumPlan>{};
  for (final pd in details) {
    if (pd.id != premiumProductId || pd is! GooglePlayProductDetails) continue;
    final index = pd.subscriptionIndex;
    final offers = pd.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null || index >= offers.length) continue;
    final offer = offers[index];
    final period = _periodFor(offer.basePlanId);
    if (period == null || offer.pricingPhases.isEmpty) continue;

    final recurring = offer.pricingPhases.lastWhere(
      (p) => p.priceAmountMicros > 0,
      orElse: () => offer.pricingPhases.last,
    );
    PricingPhaseWrapper? trial;
    for (final p in offer.pricingPhases) {
      if (p.priceAmountMicros == 0) {
        trial = p;
        break;
      }
    }
    final plan = PremiumPlan(
      basePlanId: offer.basePlanId,
      period: period,
      price: recurring.formattedPrice,
      rawPrice: recurring.priceAmountMicros / 1000000.0,
      currencyCode: recurring.priceCurrencyCode,
      trialLabel: trial == null
          ? null
          : trialLabelFromIsoPeriod(trial.billingPeriod),
      offerId: offer.offerId,
      purchaseHandle: pd,
    );
    final current = byBase[offer.basePlanId];
    final better =
        current == null ||
        (plan.hasTrial && !current.hasTrial) ||
        (plan.hasTrial == current.hasTrial &&
            plan.offerId == null &&
            current.offerId != null);
    if (better) byBase[offer.basePlanId] = plan;
  }
  return [
    if (byBase[annualBasePlanId] != null) byBase[annualBasePlanId]!,
    if (byBase[monthlyBasePlanId] != null) byBase[monthlyBasePlanId]!,
  ];
}

/// Economia do anual em relação a 12 mensalidades (0-100), ou null.
int? annualSavingsPercent(List<PremiumPlan> plans) {
  PremiumPlan? annual;
  PremiumPlan? monthly;
  for (final p in plans) {
    if (p.period == PlanPeriod.annual) annual = p;
    if (p.period == PlanPeriod.monthly) monthly = p;
  }
  if (annual == null || monthly == null) return null;
  if (annual.currencyCode != monthly.currencyCode || monthly.rawPrice <= 0) {
    return null;
  }
  final pct = (1 - annual.rawPrice / (monthly.rawPrice * 12)) * 100;
  if (pct < 1) return null;
  return pct.floor();
}
