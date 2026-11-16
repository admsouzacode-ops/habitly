import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/services/ads_consent.dart';

class _FakeConsentInformation implements ConsentInformation {
  _FakeConsentInformation({
    this.updateSucceeds = true,
    this.canRequest = false,
    this.status = PrivacyOptionsRequirementStatus.notRequired,
    this.throwOnUpdate = false,
    this.throwOnCanRequest = false,
  });

  bool updateSucceeds;
  bool canRequest;
  PrivacyOptionsRequirementStatus status;
  bool throwOnUpdate;
  bool throwOnCanRequest;
  int updateCalls = 0;

  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener successListener,
    OnConsentInfoUpdateFailureListener failureListener,
  ) {
    updateCalls++;
    if (throwOnUpdate) {
      throw Exception('offline');
    }
    if (updateSucceeds) {
      successListener();
    } else {
      failureListener(FormError(errorCode: 1, message: 'offline'));
    }
  }

  @override
  Future<bool> canRequestAds() async {
    if (throwOnCanRequest) {
      throw Exception('offline');
    }
    return canRequest;
  }

  @override
  Future<PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async {
    return status;
  }

  @override
  Future<bool> isConsentFormAvailable() async =>
      status == PrivacyOptionsRequirementStatus.required;

  @override
  Future<ConsentStatus> getConsentStatus() async => ConsentStatus.unknown;

  @override
  Future<void> reset() async {}
}

void main() {
  test('banner de debug/profile usa o ID de teste do Google', () {
    expect(bannerAdUnitId(release: false), testBannerAdUnitId);
    expect(testBannerAdUnitId, 'ca-app-pub-3940256099942544/6300978111');
  });

  test('banner de release usa a unidade real do Habitly', () {
    expect(bannerAdUnitId(release: true), releaseBannerAdUnitId);
    expect(releaseBannerAdUnitId, 'ca-app-pub-4353657138842648/3412628718');
  });

  test(
    'consentimento com sucesso inicializa o SDK quando pode pedir anúncios',
    () async {
      var initialized = 0;
      final consentInfo = _FakeConsentInformation(canRequest: true);
      final ads = AdsConsent(
        consentInformation: consentInfo,
        initializeAds: () async {
          initialized++;
        },
        loadAndShowConsentFormIfRequired: () async => null,
        showPrivacyOptionsForm: () async => null,
      );

      await ads.gatherAndInitialize();

      expect(ads.state.ready, isTrue);
      expect(ads.state.canRequestAds, isTrue);
      expect(ads.state.adsInitialized, isTrue);
      expect(initialized, 1);
      expect(consentInfo.updateCalls, 1);
    },
  );

  test('falha offline não relança e não bloqueia o app', () async {
    var initialized = 0;
    final ads = AdsConsent(
      consentInformation: _FakeConsentInformation(
        updateSucceeds: false,
        canRequest: false,
      ),
      initializeAds: () async {
        initialized++;
      },
      loadAndShowConsentFormIfRequired: () async => throw Exception('sem rede'),
      showPrivacyOptionsForm: () async => throw Exception('sem rede'),
    );

    await ads.gatherAndInitialize();

    expect(ads.state.ready, isTrue);
    expect(ads.state.canRequestAds, isFalse);
    expect(ads.state.adsInitialized, isFalse);
    expect(initialized, 0);
  });

  test('exceção no requestConsentInfoUpdate não derruba o fluxo', () async {
    final ads = AdsConsent(
      consentInformation: _FakeConsentInformation(throwOnUpdate: true),
      initializeAds: () async {},
      loadAndShowConsentFormIfRequired: () async => null,
      showPrivacyOptionsForm: () async => null,
    );

    await ads.gatherAndInitialize();
    expect(ads.state.ready, isTrue);
    expect(ads.state.adsInitialized, isFalse);
  });

  test('canRequestAds offline no cache não impede terminar o fluxo', () async {
    final ads = AdsConsent(
      consentInformation: _FakeConsentInformation(
        throwOnCanRequest: true,
        updateSucceeds: false,
      ),
      initializeAds: () async {},
      loadAndShowConsentFormIfRequired: () async => null,
      showPrivacyOptionsForm: () async => null,
    );

    await ads.gatherAndInitialize();
    expect(ads.state.ready, isTrue);
  });

  test('opções de privacidade só abrem quando a UMP exige', () async {
    var shown = 0;
    final ads = AdsConsent(
      consentInformation: _FakeConsentInformation(
        status: PrivacyOptionsRequirementStatus.notRequired,
      ),
      initializeAds: () async {},
      loadAndShowConsentFormIfRequired: () async => null,
      showPrivacyOptionsForm: () async {
        shown++;
        return null;
      },
    );

    final message = await ads.showPrivacyOptions();
    expect(shown, 0);
    expect(message, contains('Não é necessário ajustar a privacidade'));
  });

  test('opções de privacidade abrem o formulário quando exigidas', () async {
    var shown = 0;
    final ads = AdsConsent(
      consentInformation: _FakeConsentInformation(
        status: PrivacyOptionsRequirementStatus.required,
        canRequest: true,
      ),
      initializeAds: () async {},
      loadAndShowConsentFormIfRequired: () async => null,
      showPrivacyOptionsForm: () async {
        shown++;
        return null;
      },
    );

    final message = await ads.showPrivacyOptions();
    expect(shown, 1);
    expect(message, isNull);
    expect(ads.state.privacyOptionsRequired, isTrue);
  });

  test(
    'erro ao abrir as opções de privacidade vira mensagem amigável',
    () async {
      final ads = AdsConsent(
        consentInformation: _FakeConsentInformation(
          status: PrivacyOptionsRequirementStatus.required,
        ),
        initializeAds: () async {},
        loadAndShowConsentFormIfRequired: () async => null,
        showPrivacyOptionsForm: () async => throw Exception('offline'),
      );

      final message = await ads.showPrivacyOptions();
      expect(message, contains('Tente de novo com internet'));
    },
  );

  test('timeout no update de consentimento não trava', () async {
    final hanging = _HangingConsentInformation();
    final ads = AdsConsent(
      consentInformation: hanging,
      initializeAds: () async {},
      loadAndShowConsentFormIfRequired: () async => null,
      showPrivacyOptionsForm: () async => null,
      requestTimeout: const Duration(milliseconds: 30),
    );

    await ads.gatherAndInitialize();
    expect(ads.state.ready, isTrue);
  });
}

class _HangingConsentInformation implements ConsentInformation {
  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener successListener,
    OnConsentInfoUpdateFailureListener failureListener,
  ) {
    // Nunca chama os listeners: simula plugin travado / sem rede.
  }

  @override
  Future<bool> canRequestAds() async => false;

  @override
  Future<PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async =>
      PrivacyOptionsRequirementStatus.unknown;

  @override
  Future<bool> isConsentFormAvailable() async => false;

  @override
  Future<ConsentStatus> getConsentStatus() async => ConsentStatus.unknown;

  @override
  Future<void> reset() async {}
}
