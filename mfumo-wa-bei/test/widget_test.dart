import 'package:flutter_test/flutter_test.dart';
import 'package:mfumo_wa_bei/app.dart';

void main() {
  testWidgets('shows the login page content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MfumoWaBeiApp());

    expect(find.text('Mfumo wa Bei'), findsOneWidget);
    expect(find.text('Ingia kwenye akaunti yako'), findsOneWidget);
    expect(find.text('JISAJILI SASA'), findsOneWidget);
  });
}
