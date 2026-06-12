import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/settings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final (roleLabel, roleColor) = _roleInfo(user.role);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        children: [
          _Avatar(name: user.displayName),
          const SizedBox(height: 16),
          Center(
            child: Text(user.displayName, style: AppTextStyles.displaySmall),
          ),
          const SizedBox(height: 8),
          Center(
            child: _RoleBadge(label: roleLabel, color: roleColor),
          ),
          const SizedBox(height: 32),
          _InfoTile(
            icon:  Icons.email_outlined,
            label: 'Correo',
            value: user.email,
          ),
          if (user.region.isNotEmpty)
            _InfoTile(
              icon:  Icons.place_outlined,
              label: 'Región',
              value: user.region,
            ),
          _InfoTile(
            icon:  Icons.flag_outlined,
            label: 'País',
            value: user.country,
          ),
          _InfoTile(
            icon:  Icons.language_outlined,
            label: 'Idioma',
            value: user.language == 'es' ? 'Español' : user.language,
          ),
          const SizedBox(height: 40),
          if (user.role == 'admin') ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.admin),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Panel de administración'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.roleAdmin,
                  side: const BorderSide(color: AppColors.roleAdmin),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _LearningModeIndicator(),
          const SizedBox(height: 12),
          _GlossaryTile(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go(AppRoutes.login);
              },
              icon:  const Icon(Icons.logout),
              label: const Text('Cerrar sesión', style: AppTextStyles.buttonLarge),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _roleInfo(String role) => switch (role) {
    'farmer'       => ('Caficultor',    AppColors.roleFarmer),
    'processor'    => ('Procesador',    AppColors.roleProcessor),
    'barista'      => ('Barista',       AppColors.roleBarista),
    'entrepreneur' => ('Empresario',    AppColors.roleEntrepreneur),
    'admin'        => ('Administrador', AppColors.roleAdmin),
    _              => (role,            AppColors.onSurfaceVariant),
  };
}

// ── Widgets privados ─────────────────────────────────────────────────────────

class _LearningModeIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(learningModeProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: active ? AppColors.learningBg : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? AppColors.learningBorder : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 18,
            color: active ? AppColors.learningIcon : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modo aprendizaje',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(
                  active ? 'Activo — explicaciones visibles' : 'Inactivo — vista experta',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: active,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setLearningMode(v),
            activeThumbColor: AppColors.learningIcon,
            activeTrackColor: AppColors.learningBorder,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final parts    = name.trim().split(' ');
    final initials = switch (parts) {
      [final a, final b, ...] when a.isNotEmpty && b.isNotEmpty =>
        '${a[0]}${b[0]}'.toUpperCase(),
      [final a, ...] when a.isNotEmpty => a[0].toUpperCase(),
      _ => '?',
    };

    return Center(
      child: CircleAvatar(
        radius: 44,
        backgroundColor: AppColors.caramel,
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.color});

  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color:      color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GlossaryTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.glossary),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_outlined,
                size: 20, color: AppColors.caramel),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Base de investigación',
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500)),
                  Text(
                    'Glosario científico + preguntas a la IA',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String   label;
  final String   value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySmall),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color:      AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
