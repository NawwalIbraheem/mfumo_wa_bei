import 'package:flutter_test/flutter_test.dart';
import 'package:mfumo_wa_bei/main.dart';

void main() {
  testWidgets('shows the Mfumo wa Bei starter content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MfumoWaBeiApp());

    expect(find.text('Mfumo wa Bei'), findsOneWidget);
    expect(
      find.text('Pricing system starter for your Django backend.'),
      findsOneWidget,
    );
    expect(find.text('Django API connection'), findsOneWidget);
  });
}
