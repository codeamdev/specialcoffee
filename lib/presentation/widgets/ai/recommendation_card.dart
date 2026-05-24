import 'package:flutter/material.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';

class RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final bool isTopCard;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.isTopCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(recommendation.alertLevel);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTopCard ? AppColors.aiBlue : levelColor.withValues(alpha: 0.35),
          width: isTopCard ? 2.0 : 1.0,
        ),
        boxShadow: isTopCard
            ? [
                BoxShadow(
                  color: AppColors.aiBlue.withValues(alpha: 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(rec: recommendation, levelColor: levelColor, isTop: isTopCard),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recommendation.explanation, style: AppTextStyles.bodyMedium),
                if (recommendation.suggestedActions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...recommendation.suggestedActions.map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right_rounded,
                              size: 16, color: AppColors.aiBlue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(action, style: AppTextStyles.bodySmall),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _levelColor(AlertLevel level) => switch (level) {
        AlertLevel.critical => AppColors.error,
        AlertLevel.high => AppColors.warning,
        AlertLevel.warning => const Color(0xFFE65100),
        AlertLevel.info => AppColors.info,
        AlertLevel.none => AppColors.aiBlue,
      };
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.rec,
    required this.levelColor,
    required this.isTop,
  });

  final Recommendation rec;
  final Color levelColor;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isTop
            ? AppColors.aiBlueContainer
            : levelColor.withValues(alpha: 0.07),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        children: [
          Icon(_levelIcon(rec.alertLevel), size: 18, color: levelColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _prettyAction(rec.action),
              style: AppTextStyles.labelLarge.copyWith(color: levelColor),
            ),
          ),
          _ConfidencePill(confidence: rec.confidence),
        ],
      ),
    );
  }

  IconData _levelIcon(AlertLevel level) => switch (level) {
        AlertLevel.critical => Icons.error_rounded,
        AlertLevel.high => Icons.warning_amber_rounded,
        AlertLevel.warning => Icons.info_outline_rounded,
        AlertLevel.info => Icons.lightbulb_outline_rounded,
        AlertLevel.none => Icons.auto_awesome_rounded,
      };

  String _prettyAction(String action) => action
      .replaceAll('_', ' ')
      .toLowerCase()
      .replaceFirstMapped(RegExp(r'^\w'), (m) => m[0]!.toUpperCase());
}

class _ConfidencePill extends StatelessWidget {
  const _ConfidencePill({required this.confidence});
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    final color = pct >= 85
        ? AppColors.success
        : pct >= 70
            ? AppColors.warning
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$pct%',
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
