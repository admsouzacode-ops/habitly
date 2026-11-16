import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'billing_gateway.dart';
import 'premium_plans.dart';

/// Assinatura confirmada pelo Google Play (salva para funcionar offline).
const premiumPurchasedPrefKey = 'premium_purchased';

/// Chave antiga do toggle de teste. Só vale em builds de debug.
const premiumMockPrefKey = 'is_premium';

enum StoreStatus { loading, available, unavailable }

class PremiumState {
  const PremiumState({
    this.purchased = false,
    this.mock = false,
    this.store = StoreStatus.loading,
    this.plans = const [],
    this.plansNotFound = false,
    this.plansError,
    this.busy = false,
    this.pending = false,
    this.message,
    this.messageId = 0,
  });

  final bool purchased;
  final bool mock;
  final StoreStatus store;
  final List<PremiumPlan> plans;
  final bool plansNotFound;
  final String? plansError;

  /// Compra/restauração em andamento.
  final bool busy;

  /// Pagamento pendente (ex.: boleto) aguardando confirmação.
  final bool pending;

  /// Mensagem curta para SnackBar; [messageId] muda a cada nova mensagem.
  final String? message;
  final int messageId;

  bool get isPremium => purchased || (kDebugMode && mock);

  PremiumState copyWith({
    bool? purchased,
    bool? mock,
    StoreStatus? store,
    List<PremiumPlan>? plans,
    bool? plansNotFound,
    String? Function()? plansError,
    bool? busy,
    bool? pending,
    String? message,
  }) {
    return PremiumState(
      purchased: purchased ?? this.purchased,
      mock: mock ?? this.mock,
      store: store ?? this.store,
      plans: plans ?? this.plans,
      plansNotFound: plansNotFound ?? this.plansNotFound,
      plansError: plansError != null ? plansError() : this.plansError,
      busy: busy ?? this.busy,
      pending: pending ?? this.pending,
      message: message ?? this.message,
      messageId: message != null ? messageId + 1 : messageId,
    );
  }
}

/// Estado da assinatura Premium: escuta o purchaseStream, confirma
/// (acknowledge) as compras e revalida na Play a cada abertura do app.
class PremiumController extends StateNotifier<PremiumState> {
  PremiumController(this._prefs, this._gateway)
    : super(
        PremiumState(
          purchased: _prefs.getBool(premiumPurchasedPrefKey) ?? false,
          mock: kDebugMode && (_prefs.getBool(premiumMockPrefKey) ?? false),
        ),
      );

  final SharedPreferences _prefs;
  final BillingGateway _gateway;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _started = false;
  bool _restoring = false;
  bool _restoredSomething = false;

  /// Chamado uma vez na abertura do app.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _sub = _gateway.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) => debugPrint('Billing: stream erro $e'),
    );
    await refresh(recheckOwned: true);
  }

  /// Consulta disponibilidade, planos e (opcional) assinaturas ativas.
  Future<void> refresh({bool recheckOwned = false}) async {
    if (!mounted) return;
    state = state.copyWith(store: StoreStatus.loading);
    final available = await _gateway.isAvailable();
    if (!mounted) return;
    if (!available) {
      state = state.copyWith(store: StoreStatus.unavailable);
      return;
    }
    state = state.copyWith(store: StoreStatus.available);
    if (recheckOwned) await _recheckOwned();
    final q = await _gateway.queryPlans();
    if (!mounted) return;
    state = state.copyWith(
      plans: q.plans,
      plansNotFound: q.notFound,
      plansError: () => q.error,
    );
  }

  /// Sincroniza com as assinaturas ativas da conta Google Play. Se a consulta
  /// falhar, mantém o último estado salvo (funciona offline).
  Future<bool?> _recheckOwned() async {
    final owned = await _gateway.queryOwned();
    if (!owned.ok) return null;
    var active = false;
    for (final p in owned.purchases) {
      if (await verifyPurchase(p)) active = true;
      if (p.pendingCompletePurchase) await _gateway.completePurchase(p);
    }
    await _setPurchased(active);
    return active;
  }

  Future<void> buy(PremiumPlan plan) async {
    if (state.busy) return;
    state = state.copyWith(busy: true);
    try {
      final launched = await _gateway.buy(plan);
      if (!launched) {
        state = state.copyWith(
          busy: false,
          message: 'Não foi possível abrir o pagamento. Tente novamente.',
        );
      }
      // O resultado chega pelo purchaseStream.
    } catch (e) {
      debugPrint('Billing: buy falhou: $e');
      state = state.copyWith(busy: false, message: _friendlyError('$e'));
    }
  }

  /// Botão "Restaurar compras".
  Future<void> restore() async {
    if (state.busy) return;
    state = state.copyWith(busy: true);
    final available = await _gateway.isAvailable();
    if (!available) {
      state = state.copyWith(
        busy: false,
        store: StoreStatus.unavailable,
        message: 'Google Play indisponível. Verifique sua conexão.',
      );
      return;
    }
    _restoring = true;
    _restoredSomething = false;
    await _gateway.restorePurchases();
    final active = await _recheckOwned();
    _restoring = false;
    if (!mounted) return;
    final found = active ?? _restoredSomething;
    state = state.copyWith(
      busy: false,
      message: active == null && !found
          ? 'Não foi possível consultar o Google Play agora.'
          : found
          ? 'Assinatura Premium restaurada!'
          : 'Nenhuma assinatura ativa encontrada nesta conta Google.',
    );
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.productID != premiumProductId) {
        if (p.pendingCompletePurchase) await _gateway.completePurchase(p);
        continue;
      }
      switch (p.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(
            pending: true,
            busy: false,
            message:
                'Pagamento pendente. O Premium é liberado assim que o '
                'Google Play confirmar.',
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final valid = await verifyPurchase(p);
          if (valid) {
            await _setPurchased(true);
            if (p.status == PurchaseStatus.restored) _restoredSomething = true;
          }
          if (!mounted) return;
          state = state.copyWith(
            pending: false,
            busy: _restoring,
            message: p.status == PurchaseStatus.purchased
                ? (valid
                      ? 'Bem-vindo ao Premium! 🎉'
                      : 'Não foi possível validar a compra.')
                : null,
          );
        case PurchaseStatus.error:
          state = state.copyWith(
            busy: false,
            pending: false,
            message: _friendlyError(p.error?.message ?? ''),
          );
        case PurchaseStatus.canceled:
          state = state.copyWith(busy: false, pending: false);
      }
      if (p.pendingCompletePurchase) await _gateway.completePurchase(p);
    }
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('itemalreadyowned') || lower.contains('already')) {
      return 'Você já tem essa assinatura. Toque em "Restaurar compras".';
    }
    if (lower.contains('network') || lower.contains('service')) {
      return 'Sem conexão com o Google Play. Tente novamente.';
    }
    return 'Não foi possível concluir a compra. Tente novamente.';
  }

  Future<void> _setPurchased(bool value) async {
    await _prefs.setBool(premiumPurchasedPrefKey, value);
    if (mounted && state.purchased != value) {
      state = state.copyWith(purchased: value);
    }
  }

  /// Só em debug: simula o Premium sem cobrar.
  Future<void> setMock(bool value) async {
    if (!kDebugMode) return;
    await _prefs.setBool(premiumMockPrefKey, value);
    state = state.copyWith(mock: value);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
