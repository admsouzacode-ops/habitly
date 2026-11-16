import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'premium_plans.dart';

/// Resultado da consulta de planos.
class PlansQuery {
  const PlansQuery({this.plans = const [], this.notFound = false, this.error});

  final List<PremiumPlan> plans;

  /// A loja respondeu, mas `habitly_premium` (ou seus planos) não existe/está
  /// inativo para este app.
  final bool notFound;
  final String? error;
}

/// Assinaturas ativas encontradas na conta Google Play do aparelho.
class OwnedQuery {
  const OwnedQuery({this.purchases = const [], this.error});

  final List<PurchaseDetails> purchases;

  /// Não deu para consultar (sem conexão, loja indisponível...). Nesse caso o
  /// app mantém o último estado salvo.
  final String? error;

  bool get ok => error == null;
}

/// Interface fina sobre o plugin, para trocar por um fake nos testes.
abstract class BillingGateway {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<PlansQuery> queryPlans();
  Future<bool> buy(PremiumPlan plan);
  Future<void> completePurchase(PurchaseDetails purchase);
  Future<OwnedQuery> queryOwned();
  Future<void> restorePurchases();
}

class PlayBillingGateway implements BillingGateway {
  PlayBillingGateway([InAppPurchase? iap]) : _iapOverride = iap;

  final InAppPurchase? _iapOverride;
  InAppPurchase get _iap => _iapOverride ?? InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream {
    try {
      return _iap.purchaseStream;
    } catch (e) {
      debugPrint('Billing: purchaseStream indisponível: $e');
      return const Stream.empty();
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      return await _iap.isAvailable();
    } catch (e) {
      debugPrint('Billing: isAvailable falhou: $e');
      return false;
    }
  }

  @override
  Future<PlansQuery> queryPlans() async {
    try {
      final response = await _iap.queryProductDetails({premiumProductId});
      if (response.error != null) {
        return PlansQuery(error: response.error!.message);
      }
      final plans = plansFromProductDetails(response.productDetails);
      return PlansQuery(plans: plans, notFound: plans.isEmpty);
    } catch (e) {
      debugPrint('Billing: queryProductDetails falhou: $e');
      return PlansQuery(error: '$e');
    }
  }

  @override
  Future<bool> buy(PremiumPlan plan) async {
    final details = plan.purchaseHandle;
    if (details == null) return false;
    // Para assinaturas o Android usa buyNonConsumable; o offerToken vem do
    // GooglePlayProductDetails (oferta com teste grátis ou plano base).
    return _iap.buyNonConsumable(
      purchaseParam: GooglePlayPurchaseParam(productDetails: details),
    );
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    try {
      // No Android isso faz o acknowledge (obrigatório em até 3 dias, senão
      // o Google reembolsa).
      await _iap.completePurchase(purchase);
    } catch (e) {
      debugPrint('Billing: completePurchase falhou: $e');
    }
  }

  @override
  Future<OwnedQuery> queryOwned() async {
    try {
      final addition = _iap
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      if (response.error != null) {
        return OwnedQuery(error: response.error!.message);
      }
      return OwnedQuery(
        purchases: [
          for (final p in response.pastPurchases)
            if (p.productID == premiumProductId &&
                p.billingClientPurchase.purchaseState ==
                    PurchaseStateWrapper.purchased)
              p,
        ],
      );
    } catch (e) {
      debugPrint('Billing: queryPastPurchases falhou: $e');
      return OwnedQuery(error: '$e');
    }
  }

  @override
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Billing: restorePurchases falhou: $e');
    }
  }
}

/// Gancho para validação no servidor.
///
/// TODO(billing): enviar `purchase.verificationData.serverVerificationData`
/// (purchaseToken) + productID para `POST /subscriptions/verify/google` do
/// backend (androidpublisher v3) quando houver domínio público e login.
/// Por enquanto aceita a compra confirmada pelo Google Play no aparelho.
Future<bool> verifyPurchase(PurchaseDetails purchase) async => true;
