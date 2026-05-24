import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/ai_engine/ai_engine.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';

/// Banner compacto que aparece cuando Gemini no está disponible.
/// Se oculta automáticamente cuando el estado vuelve a [GeminiStatus.active].
class GeminiStatusBanner extends ConsumerWidget {
  const GeminiStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(geminiStatusProvider);

    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) => switch (status) {
        GeminiStatus.active => const SizedBox.shrink(),
        GeminiStatus.rateLimited => _Banner(
          icon: Icons.hourglass_top_rounded,
          color: AppColors.warning,
          message: 'Gemini en pausa breve — usando motor local.',
        ),
        GeminiStatus.dailyQuotaExhausted => _Banner(
          icon: Icons.cloud_off_rounded,
          color: AppColors.onSurfaceVariant,
          message: 'Cuota Gemini agotada hoy — análisis con reglas locales.',
        ),
        GeminiStatus.offline => _Banner(
          icon: Icons.wifi_off_rounded,
          color: AppColors.onSurfaceVariant,
          message: 'Sin conexión — análisis con motor local.',
        ),
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color    color;
  final String   message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(color: color),
          ),
        ),
      ]),
    );
  }
}
