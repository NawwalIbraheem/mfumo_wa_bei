import 'package:flutter_test/flutter_test.dart';
import 'package:mfumo_wa_bei/app.dart';

void main() {
  testWidgets('shows retry state when public API data cannot load', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MfumoWaBeiApp());
    await tester.pumpAndSettle();

    expect(find.text('Jaribu tena'), findsOneWidget);
  });
}
