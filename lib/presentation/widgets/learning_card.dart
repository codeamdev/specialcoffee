import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/presentation/providers/settings_provider.dart';

/// Muestra contenido educativo solo cuando el modo aprendizaje está activo.
/// En modo experto renderiza SizedBox.shrink() — cero overhead en el árbol.
///
/// Uso:
/// ```dart
/// LearningCard(
///   title: 'Grados Brix',
///   content: 'Miden la concentración de azúcar...',
///   terms: [('Refractómetro', 'Instrumento para medir Brix')],
/// )
/// ```
class LearningCard extends ConsumerWidget {
  const LearningCard({
    super.key,
    required this.content,
    this.title,
    this.terms,
    this.tip,
  });

  final String  content;
  final String? title;

  /// Pares (término, definición) que se muestran como glosario al pie.
  final List<(String, String)>? terms;

  /// Consejo práctico resaltado al final de la tarjeta.
  final String? tip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(learningModeProvider)) return const SizedBox.shrink();

    return Container(
      margin:  const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.learningBg,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.learningBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded,
                  size: 16, color: AppColors.learningIcon),
              const SizedBox(width: 6),
              Text(
                title ?? 'Aprende más',
                style: AppTextStyles.labelMedium.copyWith(
                  color:      AppColors.learningIcon,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: AppTextStyles.bodySmall),

          if (terms != null && terms!.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.learningBorder),
            const SizedBox(height: 8),
            ...terms!.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t.$1}: ',
                      style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Text(t.$2, style: AppTextStyles.bodySmall),
                  ),
                ],
              ),
            )),
          ],

          if (tip != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color:        AppColors.learningBorder.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_outlined,
                      size: 14, color: AppColors.learningIcon),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tip!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
