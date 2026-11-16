import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Carrega fontes reais nos testes (o padrão do flutter_test é a Ahem, bem
/// mais larga): Roboto do repositório, Material Icons do bundle e, se o
/// sistema tiver, Noto Color Emoji.
Future<void> loadRealFonts({bool emoji = false}) async {
  final roboto = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    final bytes = File('test/fonts/Roboto-$w.ttf').readAsBytesSync();
    roboto.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await roboto.load();

  try {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    for (final entry in manifest.cast<Map<String, dynamic>>()) {
      final family = (entry['family'] as String).replaceFirst(
        RegExp(r'^packages/[^/]+/'),
        '',
      );
      final loader = FontLoader(family);
      for (final f in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
        loader.addFont(rootBundle.load(f['asset'] as String));
      }
      await loader.load();
    }
  } catch (_) {
    // Sem manifest: ícones viram quadrados, sem impacto no layout.
  }

  if (emoji) {
    const path = '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf';
    final file = File(path);
    if (file.existsSync()) {
      final loader = FontLoader('NotoColorEmoji')
        ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      await loader.load();
    }
  }
}
