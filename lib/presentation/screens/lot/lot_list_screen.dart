import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/lot.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

class LotListScreen extends ConsumerWidget {
  const LotListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotsAsync = ref.watch(userLotsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Mis Lotes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.lotCreate),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo lote'),
      ),
      body: lotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error al cargar lotes', style: AppTextStyles.bodyLarge),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(userLotsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (lots) => lots.isEmpty
            ? _EmptyState(onAdd: () => context.go(AppRoutes.lotCreate))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(userLotsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: lots.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _LotCard(
                    lot: lots[i],
                    onTap: () => context.go(
                      AppRoutes.lotDetail.replaceFirst(':id', lots[i].id),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          Text('Sin lotes registrados', style: AppTextStyles.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer lote para empezar\na recibir recomendaciones de IA.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo lote'),
          ),
        ],
      ),
    );
  }
}

class _LotCard extends StatelessWidget {
  const _LotCard({required this.lot, required this.onTap});

  final Lot         lot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusInfo(lot.status);
    final (processLabel, processIcon) = _processInfo(lot.processType);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lot.varietyName,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusChip(label: statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(processIcon, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(processLabel, style: AppTextStyles.bodySmall),
                  const SizedBox(width: 16),
                  const Icon(Icons.place_outlined, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lot.region.isNotEmpty ? lot.region : '—',
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.terrain_outlined, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${lot.altitudeMasl} m', style: AppTextStyles.bodySmall),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(lot.createdAt),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _statusInfo(String status) => switch (status) {
    'pending'      => ('Pendiente',     AppColors.warning),
    'fermenting'   => ('Fermentando',   AppColors.aiBlue),
    'drying'       => ('Secando',       AppColors.caramel),
    'milling'      => ('Trillando',     AppColors.roleProcessor),
    'ready'        => ('Listo',         AppColors.success),
    _              => (status,          AppColors.onSurfaceVariant),
  };

  (String, IconData) _processInfo(String process) => switch (process) {
    'lavado'    => ('Lavado',    Icons.water_drop_outlined),
    'natural'   => ('Natural',   Icons.wb_sunny_outlined),
    'honey_yellow'     => ('Honey',     Icons.hexagon_outlined),
    'anaerobic_lactic' => ('Anaerobio', Icons.science_outlined),
    _           => (process,     Icons.filter_outlined),
  };

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color:      color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
