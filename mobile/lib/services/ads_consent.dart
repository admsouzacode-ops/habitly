import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Estado do consentimento UMP e da inicialização do Mobile Ads.
class AdsConsentState {
  const AdsConsentState({
    this.ready = false,
    this.canRequestAds = false,
    this.adsInitialized = false,
    this.privacyOptionsRequired = false,
  });

  /// O fluxo de consentimento terminou (sucesso, falha ou timeout).
  final bool ready;

  /// O SDK permite pedir anúncios com o consentimento atual (pode vir do cache).
  final bool canRequestAds;

  /// [MobileAds.initialize] já rodou com sucesso nesta sessão.
  final bool adsInitialized;

  /// A Play / UMP exige um atalho para as opções de privacidade.
  final bool privacyOptionsRequired;

  AdsConsentState copyWith({
    bool? ready,
    bool? canRequestAds,
    bool? adsInitialized,
    bool? privacyOptionsRequired,
  }) {
    return AdsConsentState(
      ready: ready ?? this.ready,
      canRequestAds: canRequestAds ?? this.canRequestAds,
      adsInitialized: adsInitialized ?? this.adsInitialized,
      privacyOptionsRequired:
          privacyOptionsRequired ?? this.privacyOptionsRequired,
    );
  }
}

/// Google UMP (ConsentInformation / ConsentForm) + inicialização do Mobile Ads.
///
/// Nunca relança exceção: offline, plugin ausente ou timeout só impedem
/// os anúncios, sem travar a abertura do app.
class AdsConsent extends StateNotifier<AdsConsentState> {
  AdsConsent({
    ConsentInformation? consentInformation,
    Future<void> Function()? initializeAds,
    Future<FormError?> Function()? loadAndShowConsentFormIfRequired,
    Future<FormError?> Function()? showPrivacyOptionsForm,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _consent = consentInformation ?? ConsentInformation.instance,
       _initializeAds =
           initializeAds ??
           (() async {
             await MobileAds.instance.initialize();
           }),
       _loadAndShow = loadAndShowConsentFormIfRequired ?? _platformLoadAndShow,
       _showPrivacyOptions =
           showPrivacyOptionsForm ?? _platformShowPrivacyOptions,
       super(const AdsConsentState());

  final ConsentInformation _consent;
  final Future<void> Function() _initializeAds;
  final Future<FormError?> Function() _loadAndShow;
  final Future<FormError?> Function() _showPrivacyOptions;
  final Duration requestTimeout;

  bool _started = false;
  Future<void>? _inFlight;

  static Future<FormError?> _platformLoadAndShow() async {
    FormError? error;
    await ConsentForm.loadAndShowConsentFormIfRequired((e) => error = e);
    return error;
  }

  static Future<FormError?> _platformShowPrivacyOptions() async {
    FormError? error;
    await ConsentForm.showPrivacyOptionsForm((e) => error = e);
    return error;
  }

  /// Idempotente: roda o fluxo UMP e, se permitido, inicializa o SDK.
  Future<void> gatherAndInitialize() {
    _inFlight ??= _run();
    return _inFlight!;
  }

  Future<void> _run() async {
    if (_started) return;
    _started = true;
    try {
      await _refreshFlags();
      if (state.canRequestAds) {
        await _initAds();
      }

      final updated = await _requestConsentInfoUpdate();
      if (updated) {
        try {
          final formError = await _loadAndShow();
          if (formError != null) {
            debugPrint('UMP formulário: ${formError.message}');
          }
        } catch (error, stack) {
          debugPrint('UMP loadAndShow falhou: $error\n$stack');
        }
      }

      await _refreshFlags();
      if (state.canRequestAds) {
        await _initAds();
      }
    } catch (error, stack) {
      debugPrint('UMP: fluxo de consentimento falhou: $error\n$stack');
      try {
        await _refreshFlags();
        if (state.canRequestAds) await _initAds();
      } catch (_) {}
    } finally {
      if (!state.ready) {
        state = state.copyWith(ready: true);
      }
    }
  }

  /// Atualiza o info de consentimento. Devolve true se a atualização obteve
  /// sucesso; false em falha, exceção ou timeout (não bloqueia o app).
  Future<bool> _requestConsentInfoUpdate() async {
    final done = Completer<bool>();
    try {
      _consent.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!done.isCompleted) done.complete(true);
        },
        (FormError error) {
          debugPrint('UMP requestConsentInfoUpdate: ${error.message}');
          if (!done.isCompleted) done.complete(false);
        },
      );
    } catch (error, stack) {
      debugPrint('UMP requestConsentInfoUpdate lançou: $error\n$stack');
      if (!done.isCompleted) done.complete(false);
    }
    try {
      return await done.future.timeout(requestTimeout);
    } on TimeoutException {
      debugPrint('UMP: tempo esgotado ao pedir consentimento, seguindo.');
      return false;
    }
  }

  Future<void> _refreshFlags() async {
    var canRequest = state.canRequestAds;
    var required = state.privacyOptionsRequired;
    try {
      canRequest = await _consent.canRequestAds();
    } catch (error) {
      debugPrint('UMP canRequestAds: $error');
    }
    try {
      final status = await _consent.getPrivacyOptionsRequirementStatus();
      required = status == PrivacyOptionsRequirementStatus.required;
    } catch (error) {
      debugPrint('UMP privacyOptions: $error');
    }
    state = state.copyWith(
      canRequestAds: canRequest,
      privacyOptionsRequired: required,
    );
  }

  Future<void> _initAds() async {
    if (state.adsInitialized) return;
    try {
      await _initializeAds();
      state = state.copyWith(adsInitialized: true);
    } catch (error, stack) {
      debugPrint('Mobile Ads não inicializou: $error\n$stack');
    }
  }

  /// Abre o formulário de opções de privacidade quando a UMP exige.
  /// Devolve uma mensagem em pt-BR para o SnackBar, ou null se deu certo.
  Future<String?> showPrivacyOptions() async {
    try {
      await _refreshFlags();
      if (!state.privacyOptionsRequired) {
        return 'Não é necessário ajustar a privacidade dos anúncios '
            'neste momento.';
      }
      final error = await _showPrivacyOptions();
      await _refreshFlags();
      if (state.canRequestAds) {
        await _initAds();
      }
      if (error != null) {
        return 'Não foi possível abrir as opções de privacidade. '
            'Tente de novo com internet.';
      }
      return null;
    } catch (error, stack) {
      debugPrint('UMP privacy options: $error\n$stack');
      return 'Não foi possível abrir as opções de privacidade. '
          'Tente de novo com internet.';
    }
  }
}
