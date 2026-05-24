// Smoke test — verifies the app builds without runtime errors on first frame.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpecialCoffeeApp()));
    await tester.pump();
    // If no exception was thrown, the smoke test passes.
  });
}
