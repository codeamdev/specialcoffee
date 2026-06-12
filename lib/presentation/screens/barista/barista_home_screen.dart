import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/coffee_reference.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/coffee_reference_provider.dart';
import 'package:special_coffee/presentation/screens/barista/coffee_reference_form.dart';

class BaristaHomeScreen extends ConsumerWidget {
  const BaristaHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final refsAsync = ref.watch(coffeeReferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          user != null ? 'Hola, ${user.displayName.split(' ').first}' : 'Mi café',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.coffee),
            tooltip: 'Nueva preparación',
            onPressed: () => context.push(AppRoutes.baristaWizard),
          ),
        ],
      ),
      body: refsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (refs) => refs.isEmpty
            ? _EmptyState(onAdd: () => _showForm(context, ref))
            : _ReferenceList(refs: refs, onAdd: () => _showForm(context, ref)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        backgroundColor: AppColors.roleBarista,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar café'),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref) {
    ref.read(coffeeReferenceProvider.notifier).reset();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CoffeeReferenceForm(),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.coffee_outlined, size: 64, color: AppColors.outline),
            const SizedBox(height: 16),
            Text(
              'Sin referencias de café',
              style: AppTextStyles.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primer café para empezar a preparar y registrar sesiones.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar café'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reference list ────────────────────────────────────────────────────────────

class _ReferenceList extends StatelessWidget {
  const _ReferenceList({required this.refs, required this.onAdd});

  final List<CoffeeReference> refs;
  final VoidCallback          onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mis cafés', style: AppTextStyles.displaySmall),
              TextButton.icon(
                onPressed: () => context.push(AppRoutes.baristaWizard),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Preparar'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            itemCount: refs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ReferenceCard(ref: refs[i]),
          ),
        ),
      ],
    );
  }
}

// ── Reference card ────────────────────────────────────────────────────────────

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({required this.ref});

  final CoffeeReference ref;

  @override
  Widget build(BuildContext context) {
    final days   = ref.daysSinceRoast;
    final status = _statusLabel(ref.status);
    final statusColor = _statusColor(ref.status);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.brew, extra: {'reference': ref}),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:        AppColors.roleBarista.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.coffee, color: AppColors.roleBarista, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ref.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                if (ref.origin != null)
                  Text(ref.origin!, style: AppTextStyles.bodySmall),
                Row(
                  children: [
                    _Chip(label: _roastLabel(ref.roastLevel)),
                    if (days != null) ...[
                      const SizedBox(width: 6),
                      _Chip(label: '$days días'),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:        statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: AppTextStyles.labelSmall.copyWith(color: statusColor),
            ),
          ),
        ],
      ),
    ),
    );
  }

  String _roastLabel(String level) => switch (level) {
    'light'  => 'Claro',
    'medium' => 'Medio',
    'dark'   => 'Oscuro',
    _        => level,
  };

  String _statusLabel(String status) => switch (status) {
    'active'   => 'Activo',
    'inactive' => 'Inactivo',
    'depleted' => 'Agotado',
    'expired'  => 'Vencido',
    _          => status,
  };

  Color _statusColor(String status) => switch (status) {
    'active'   => AppColors.success,
    'inactive' => AppColors.onSurfaceVariant,
    'depleted' => AppColors.warning,
    'expired'  => AppColors.error,
    _          => AppColors.onSurfaceVariant,
  };
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:        AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: AppTextStyles.labelSmall),
    );
  }
}
