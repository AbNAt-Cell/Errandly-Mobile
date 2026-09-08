import 'package:flutter_test/flutter_test.dart';
import 'package:errandly/main.dart';

void main() {
  testWidgets('Errandly app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ErrandlyApp());
    await tester.pump();
    expect(find.text('Errandly'), findsWidgets);
  });
}
