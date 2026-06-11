import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/domain/entities/lot.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';
import 'package:special_coffee/presentation/screens/lot/lot_detail_screen.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildScreen(String lotId, {Lot? lot}) => ProviderScope(
      overrides: [
        lotByIdProvider(lotId).overrideWith((_) async => lot),
      ],
      child: MaterialApp(home: LotDetailScreen(lotId: lotId)),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LotDetailScreen', () {
    testWidgets('shows app bar title "Detalle del lote"', (tester) async {
      await tester.pumpWidget(_buildScreen('lot-1'));
      await tester.pumpAndSettle();

      expect(find.text('Detalle del lote'), findsOneWidget);
    });

    testWidgets('shows "Lote no encontrado" when lot is null', (tester) async {
      await tester.pumpWidget(_buildScreen('lot-2'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Lote no encontrado'), findsOneWidget);
    });

    testWidgets('shows QR and PDF action icons in app bar', (tester) async {
      await tester.pumpWidget(_buildScreen('lot-3'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.qr_code_outlined), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    });
  });
}
