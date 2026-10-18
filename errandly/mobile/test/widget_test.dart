import 'package:flutter_test/flutter_test.dart';
import 'package:errandly/main.dart';

void main() {
  testWidgets('Errandly app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ErrandlyApp());
    expect(find.text('Errand'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
  });
}
