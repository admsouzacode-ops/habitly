import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/achievements.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/screens/achievements_screen.dart';
import 'package:habitly/theme/habitly_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fonts.dart';

void main() {
  setUpAll(loadRealFonts);

  test('as 12 conquistas são distintas (id, título e descrição)', () {
    expect(achievements, hasLength(12));
    expect(achievements.map((a) => a.id).toSet(), hasLength(12));
    expect(achievements.map((a) => a.title).toSet(), hasLength(12));
    expect(achievements.map((a) => a.description).toSet(), hasLength(12));
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    required double width,
    required double textScale,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Metade desbloqueada para testar os dois estilos de card.
    final ledger = AchievementLedger({
      for (final a in achievements.take(6)) a.id: DateTime(2026, 11, 16),
    });
    SharedPreferences.setMockInitialValues({
      AchievementLedger.prefKey: ledger.encode(),
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          habitSnapshotProvider.overrideWith(
            (ref) =>
                Stream.value(const HabitSnapshot(habits: [], completions: [])),
          ),
        ],
        child: MaterialApp(
          theme: buildHabitlyTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const AchievementsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  void expectNoClipping(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    for (final a in achievements) {
      // Cada conquista aparece uma única vez.
      expect(find.byKey(ValueKey('achievement-${a.id}')), findsOneWidget);
      expect(find.text(a.title), findsOneWidget);
      final desc = find.text(a.description);
      expect(desc, findsOneWidget);
      final para = tester.renderObject<RenderParagraph>(desc);
      expect(para.didExceedMaxLines, isFalse, reason: a.description);

      // Nenhuma palavra do título é quebrada no meio.
      final titlePara = tester.renderObject<RenderParagraph>(
        find.text(a.title),
      );
      final style = (titlePara.text as TextSpan).style;
      for (final word in a.title.split(' ')) {
        final tp = TextPainter(
          text: TextSpan(text: word, style: style),
          textDirection: TextDirection.ltr,
          textScaler: titlePara.textScaler,
        )..layout();
        expect(
          tp.width <= titlePara.size.width + 0.5,
          isTrue,
          reason: '"$word" (${tp.width}) > ${titlePara.size.width}',
        );
        tp.dispose();
      }
    }
  }

  for (final width in [360.0, 400.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('sem overflow em ${width.toInt()}dp, texto x$scale', (
        tester,
      ) async {
        await pumpScreen(tester, width: width, textScale: scale);
        expectNoClipping(tester);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
