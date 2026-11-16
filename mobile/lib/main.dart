import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/app.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/services/ads_consent.dart';
import 'package:habitly/services/home_widget_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  final prefs = await SharedPreferences.getInstance();
  final adsConsent = AdsConsent();
  // Widget da tela inicial: callback em segundo plano para marcar hábitos.
  unawaited(registerHomeWidgetCallback());
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        adsConsentProvider.overrideWith((ref) => adsConsent),
      ],
      child: const HabitlyApp(),
    ),
  );
  // Consentimento UMP e Mobile Ads depois de abrir o app, pra não bloquear
  // a tela inicial se estiver offline.
  unawaited(adsConsent.gatherAndInitialize());
}
