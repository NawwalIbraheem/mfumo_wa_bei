import 'package:flutter_test/flutter_test.dart';
import 'package:mfumo_wa_bei/app.dart';

void main() {
  testWidgets('shows public market content with login entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MfumoWaBeiApp());

    expect(find.text('Mfumo wa Bei'), findsOneWidget);
    expect(find.text('Bei za mchele na maharage karibu nawe'), findsOneWidget);
    expect(find.byTooltip('Ingia'), findsOneWidget);
  });
}
