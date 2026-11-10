import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:habitly/providers/providers.dart';

/// Banner de teste oficial do Google, visível só no plano gratuito.
class HabitlyAdBanner extends ConsumerStatefulWidget {
  const HabitlyAdBanner({super.key});

  @override
  ConsumerState<HabitlyAdBanner> createState() => _HabitlyAdBannerState();
}

class _HabitlyAdBannerState extends ConsumerState<HabitlyAdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(adsEnabledProvider)) {
      _load();
    }
  }

  void _load() {
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: testBannerAdUnitId,
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
          if (kDebugMode) {
            debugPrint('Banner de teste não carregou: $error');
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumProvider);
    final adsEnabled = ref.watch(adsEnabledProvider);
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
