import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App boots to onboarding screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ZatcaExampleApp());
    await tester.pump();

    expect(find.text('Set up your EGS device'), findsOneWidget);
    expect(
      find.text('Fill form with known-good sandbox data'),
      findsOneWidget,
    );
  });

  testWidgets('Environment switcher is visible', (WidgetTester tester) async {
    await tester.pumpWidget(const ZatcaExampleApp());
    await tester.pump();

    expect(find.text('Sandbox'), findsWidgets);
    expect(find.text('Simulation'), findsWidgets);
    expect(find.text('Production'), findsWidgets);
  });
}
