import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:habitly/providers/providers.dart';

/// Banner do AdMob, visível só no plano gratuito e depois do consentimento UMP.
///
/// Em debug/profile usa o ID de teste do Google; em release, a unidade real.
class HabitlyAdBanner extends ConsumerStatefulWidget {
  const HabitlyAdBanner({super.key});

  @override
  ConsumerState<HabitlyAdBanner> createState() => _HabitlyAdBannerState();
}

class _HabitlyAdBannerState extends ConsumerState<HabitlyAdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _loading = false;

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  void _loadIfNeeded() {
    final premium = ref.read(premiumProvider);
    final adsEnabled = ref.read(adsEnabledProvider);
    final consent = ref.read(adsConsentProvider);
    if (premium ||
        !adsEnabled ||
        !consent.canRequestAds ||
        !consent.adsInitialized ||
        _loading ||
        _ad != null) {
      return;
    }
    _loading = true;
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: bannerAdUnitId(),
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _ad = null;
          _loading = false;
          if (kDebugMode) {
            debugPrint('Banner não carregou: $error');
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumProvider);
    final adsEnabled = ref.watch(adsEnabledProvider);
    final consent = ref.watch(adsConsentProvider);

    ref.listen(adsConsentProvider, (_, _) => _loadIfNeeded());
    ref.listen(premiumProvider, (_, _) => _loadIfNeeded());

    if (!premium &&
        adsEnabled &&
        consent.canRequestAds &&
        consent.adsInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadIfNeeded();
      });
    }

    if (premium || !adsEnabled || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: _ad!.size.height.toDouble(),
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}
