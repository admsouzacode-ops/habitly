# Habitly (app Flutter)

App offline-first de hábitos (Drift/SQLite + Riverpod, Material 3, pt-BR).
Android `br.com.souzacode.habitly`.

## Novidades 1.0.0+8
- **Premium real (Google Play Billing, `in_app_purchase`)**: assinatura
  `habitly_premium` com planos base `mensal` e `anual` (oferta de teste
  grátis é usada quando o usuário é elegível). Preços sempre vêm do
  `ProductDetails`. Código em `lib/billing/`: `premium_plans.dart` (escolhe
  plano/oferta), `billing_gateway.dart` (plugin + gancho `verifyPurchase`
  TODO para `POST /subscriptions/verify/google`) e `premium_controller.dart`
  (purchaseStream, `completePurchase`/acknowledge, restaurar e revalidação na
  abertura via `queryPastPurchases`; offline mantém o último estado salvo em
  `premium_purchased`). Paywall em `lib/screens/paywall_screen.dart`. O toggle
  de Premium simulado só existe em builds de debug.
- **Conquistas**: cards com altura automática (linhas de 2 com
  `IntrinsicHeight`), descrição inteira e título que diminui em vez de quebrar
  palavra (`NoBreakTitle`). Testes em 360/400dp com texto x1.3.
- **Assets da loja**: `STORE_SHOTS=<dir>/raw flutter test test/store_screenshots_test.dart`
  renderiza as telas reais com dados de demonstração, e `python3 tool/gen_store_assets.py <dir>`
  gera o ícone 512, as alternativas, o gráfico de recursos e as capturas com
  legenda (cópia em `../store/`).

## Funções (1.0.0+7)
- **Metas flexíveis** (schema Drift v4): por dias da semana, *X vezes por
  semana* (qualquer dia) ou *quantidade por dia* com meta, unidade e
  incremento (ex.: 2 litros, +0,5). Quantidade grava o valor do dia em
  `habit_amounts` e marca a conclusão em `completions` ao atingir a meta.
- **Sequências**: atual e recorde por hábito. Diária/quantidade contam dias
  agendados (dias fora da agenda não quebram; hoje pendente não quebra).
  Semanal conta semanas ISO (seg–dom) com a meta batida; a semana atual só
  entra quando bate a meta. Tela de detalhes do hábito ao tocar no card.
- **Conquistas**: 12 medalhas calculadas dos dados (`lib/logic/achievements.dart`);
  as já celebradas ficam em SharedPreferences (`achievements_unlocked`) com a
  data. SnackBar ao desbloquear. Tela em Estatísticas (ícone 🏆) e Configurações.
- **Widget da tela inicial** (`home_widget`): até 5 hábitos de hoje, ✓ para
  marcar e +N para quantidade sem abrir o app. O toque chama
  `habitlyWidgetCallback` (Dart em segundo plano), que grava no banco e
  redesenha. O app atualiza o widget a cada mudança, recarrega o banco ao
  voltar para o primeiro plano e agenda atualização logo após a meia-noite.
  Nativo: `android/app/src/main/kotlin/.../HabitlyWidgetProvider.kt`,
  `res/layout/habitly_widget.xml`, `res/xml/habitly_widget_info.xml`.
- Notas do dia (v3), lembretes (v2), limite de 5 hábitos no plano grátis com
  anúncios de teste do AdMob.

## Desenvolvimento
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift
flutter analyze && flutter test
flutter build appbundle --release   # precisa de android/key.properties
```
Migrações testadas em `test/migration_test.dart` (v1/v2/v3 → v4).
