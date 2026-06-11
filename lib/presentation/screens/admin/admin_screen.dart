import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/presentation/providers/settings_provider.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Administración'),
        backgroundColor: AppColors.roleAdmin,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        children: [
          _SectionHeader(
            icon:  Icons.tune_rounded,
            label: 'Experiencia de usuario',
          ),
          const SizedBox(height: 12),

          _SettingTile(
            icon:        Icons.menu_book_rounded,
            iconColor:   AppColors.learningIcon,
            title:       'Modo aprendizaje',
            subtitle:    settings.learningMode
                ? 'Activo — se muestran explicaciones, glosarios y consejos en todas las pantallas'
                : 'Inactivo — vista experta sin información adicional',
            trailing: Switch(
              value:    settings.learningMode,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setLearningMode(v),
              activeThumbColor: AppColors.learningIcon,
              activeTrackColor: AppColors.learningBorder,
            ),
            onTap: () => ref
                .read(settingsProvider.notifier)
                .setLearningMode(!settings.learningMode),
          ),

          const SizedBox(height: 8),
          _LearningModeDetail(active: settings.learningMode),

          const SizedBox(height: 32),
          _SectionHeader(
            icon:  Icons.construction_rounded,
            label: 'Próximamente',
          ),
          const SizedBox(height: 12),
          _SettingTile(
            icon:      Icons.language_outlined,
            iconColor: AppColors.onSurfaceVariant,
            title:     'Idioma de la interfaz',
            subtitle:  'Español (predeterminado)',
            enabled:   false,
          ),
          _SettingTile(
            icon:      Icons.sync_rounded,
            iconColor: AppColors.onSurfaceVariant,
            title:     'Sincronización automática',
            subtitle:  'Configurar frecuencia de sync con el servidor',
            enabled:   false,
          ),
          _SettingTile(
            icon:      Icons.bar_chart_rounded,
            iconColor: AppColors.onSurfaceVariant,
            title:     'Umbrales personalizados',
            subtitle:  'Ajustar rangos óptimos de pH, temperatura, Brix…',
            enabled:   false,
          ),
        ],
      ),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            color:          AppColors.onSurfaceVariant,
            fontWeight:     FontWeight.w700,
            letterSpacing:  0.8,
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color    iconColor;
  final String   title;
  final String   subtitle;
  final Widget?  trailing;
  final VoidCallback? onTap;
  final bool     enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: AppColors.outlineVariant),
        ),
        child: ListTile(
          onTap:        enabled ? onTap : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width:  38,
            height: 38,
            decoration: BoxDecoration(
              color:        iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          title:    Text(title,    style: AppTextStyles.bodyMedium),
          subtitle: Text(subtitle, style: AppTextStyles.bodySmall, maxLines: 2),
          trailing: trailing ?? (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant)
              : null),
        ),
      ),
    );
  }
}

class _LearningModeDetail extends StatelessWidget {
  const _LearningModeDetail({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        active ? AppColors.learningBg : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? AppColors.learningBorder : AppColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            active ? '¿Qué verás con el modo activo?' : '¿Qué se oculta en modo experto?',
            style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  active ? Icons.check_circle_outline_rounded
                          : Icons.remove_circle_outline_rounded,
                  size:  15,
                  color: active ? AppColors.learningIcon : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: AppTextStyles.bodySmall)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  static const _items = [
    'Explicación de términos técnicos (Brix, pH, aw, TDS…)',
    'Paso a paso de cada proceso productivo',
    'Palabras clave y glosario de café de especialidad',
    'Consejos prácticos y buenas prácticas SCA/Cenicafé',
    'Contexto de por qué cada parámetro importa',
  ];
}
