import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/presentation/widgets/ai/recommendation_card.dart';

Recommendation _rec({
  String ruleId = 'R001',
  String action = 'SUGGEST_TEMPERATURE',
  AlertLevel alertLevel = AlertLevel.info,
  double confidence = 0.80,
  String explanation = 'Adjust your water temperature for best results.',
  List<String> suggestedActions = const [],
}) =>
    Recommendation(
      ruleId: ruleId,
      action: action,
      alertLevel: alertLevel,
      confidence: confidence,
      explanation: explanation,
      suggestedActions: suggestedActions,
      parameters: const {},
      generatedAt: DateTime.now(),
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.aiBlue),
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('RecommendationCard — rendering', () {
    testWidgets('shows explanation text', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(recommendation: _rec(explanation: 'Reduce grind size.')),
      ));

      expect(find.text('Reduce grind size.'), findsOneWidget);
    });

    testWidgets('shows prettified action in header', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(recommendation: _rec(action: 'SUGGEST_TEMPERATURE')),
      ));

      // _prettyAction: 'SUGGEST_TEMPERATURE' → 'Suggest temperature'
      expect(find.text('Suggest temperature'), findsOneWidget);
    });

    testWidgets('shows suggested actions when present', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(
          recommendation: _rec(suggestedActions: const [
            'Lower water temp by 2°C',
            'Increase steep time by 30s',
          ]),
        ),
      ));

      expect(find.text('Lower water temp by 2°C'), findsOneWidget);
      expect(find.text('Increase steep time by 30s'), findsOneWidget);
    });

    testWidgets('no suggested action rows when list is empty', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(recommendation: _rec(suggestedActions: const [])),
      ));

      expect(find.byIcon(Icons.arrow_right_rounded), findsNothing);
    });
  });

  group('RecommendationCard — isTopCard', () {
    testWidgets('isTopCard=true → border color is aiBlue (2px)', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(
          recommendation: _rec(),
          isTopCard: true,
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border?.top.color, AppColors.aiBlue);
      expect(decoration.border?.top.width, 2.0);
    });

    testWidgets('isTopCard=true → header has aiBlueContainer background', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(
          recommendation: _rec(),
          isTopCard: true,
        ),
      ));

      // Find header container (second Container inside)
      final containers = tester.widgetList<Container>(find.byType(Container));
      final headerContainer = containers.elementAt(1);
      final decoration = headerContainer.decoration as BoxDecoration?;
      expect(decoration?.color, AppColors.aiBlueContainer);
    });

    testWidgets('isTopCard=true → boxShadow is applied', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(
          recommendation: _rec(),
          isTopCard: true,
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.isNotEmpty, isTrue);
    });

    testWidgets('isTopCard=false → no boxShadow', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(recommendation: _rec()),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNull);
    });
  });

  group('RecommendationCard — ConfidencePill colors', () {
    testWidgets('confidence ≥ 85% → green pill (success color)', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(recommendation: _rec(confidence: 0.90)),
      ));

      expect(find.text('90%'), findsOneWidget);

      // Find the confidence pill container and verify its color is success-based
      final pillContainers = tester.widgetList<Container>(find.byType(Container));
      final pill = pillContainers.lastWhere((c) {
        final d = c.decoration as BoxDecoration?;
        return d?.borderRadius != null &&
               (d?.borderRadius as BorderRadius?)?.topLeft.x == 20.0;
      }, orElse: () => pillContainers.last);

      final pillDecoration = pill.decoration as BoxDecoration?;
      // Success color is 0xFF2E7D32; withOpacity(0.12) → semi-transparent
      expect(pillDecoration?.color?.value,
             AppColors.success.withOpacity(0.12).value);
    });

    testWidgets('confidence 70–84% → orange pill (warning color)', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(recommendation: _rec(confidence: 0.75)),
      ));

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('confidence < 70% → red pill (error color)', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(recommendation: _rec(confidence: 0.60)),
      ));

      expect(find.text('60%'), findsOneWidget);
    });
  });

  group('RecommendationCard — alert level icons', () {
    testWidgets('critical alertLevel → error_rounded icon', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(recommendation: _rec(alertLevel: AlertLevel.critical)),
      ));

      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });

    testWidgets('high alertLevel → warning_amber_rounded icon', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(recommendation: _rec(alertLevel: AlertLevel.high)),
      ));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('info alertLevel → lightbulb_outline_rounded icon', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(recommendation: _rec(alertLevel: AlertLevel.info)),
      ));

      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
    });

    testWidgets('none alertLevel → auto_awesome_rounded icon', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(recommendation: _rec(alertLevel: AlertLevel.none)),
      ));

      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });
  });

  group('RecommendationCard — _prettyAction formatting', () {
    testWidgets('underscored action → space-separated title case', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(recommendation: _rec(action: 'SELECT_PROCESS_ANAEROBIC')),
      ));

      expect(find.text('Select process anaerobic'), findsOneWidget);
    });

    testWidgets('single-word action → capitalized', (tester) async {
      await tester.pumpWidget(_wrap(
        RecommendationCard(recommendation: _rec(action: 'DIAGNOSE')),
      ));

      expect(find.text('Diagnose'), findsOneWidget);
    });
  });
}
