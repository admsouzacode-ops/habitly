import 'package:flutter_test/flutter_test.dart';
import 'package:habitly/main.dart';

void main() {
  testWidgets('Habitly abre a tela inicial sem crashar', (tester) async {
    await tester.pumpWidget(const HabitlyApp());
    expect(find.textContaining('Habitly'), findsWidgets);
    expect(find.textContaining('Em construção'), findsOneWidget);
  });
}
