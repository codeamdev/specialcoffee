// Smoke test — verifies the app builds without runtime errors on first frame.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // runAsync exits the fake-async zone so background Futures from providers
    // (_loadPersistedSession, etc.) complete in real async and don't leave
    // pending fake timers that would fail _verifyInvariants.
    await tester.runAsync(() async {
      await tester.pumpWidget(const ProviderScope(child: SpecialCoffeeApp()));
      await tester.pump();
    });
  });
}
