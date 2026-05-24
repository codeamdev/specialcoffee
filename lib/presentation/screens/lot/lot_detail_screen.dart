import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/lot.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

class LotDetailScreen extends ConsumerWidget {
  const LotDetailScreen({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotAsync = ref.watch(lotByIdProvider(lotId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Detalle del lote')),
      body: lotAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error al cargar el lote', style: AppTextStyles.bodyLarge),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(lotByIdProvider(lotId)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (lot) => lot == null
            ? Center(child: Text('Lote no encontrado', style: AppTextStyles.bodyLarge))
            : _LotDetail(lot: lot),
      ),
    );
  }
}

class _LotDetail extends StatelessWidget {
  const _LotDetail({required this.lot});

  final Lot lot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
      children: [
        _HeaderCard(lot: lot),
        const SizedBox(height: 16),
        _SectionTitle('Condiciones ambientales'),
        const SizedBox(height: 8),
        _InfoGrid([
          _InfoItem(Icons.thermostat_outlined, 'Temperatura', '${lot.ambientTempC.toStringAsFixed(1)} °C'),
          _InfoItem(Icons.water_drop_outlined, 'Humedad', '${lot.ambientHumidityPct.toStringAsFixed(0)} %'),
          _InfoItem(Icons.umbrella_outlined, 'Lluvia', '${lot.rainProbabilityPct.toStringAsFixed(0)} %'),
          _InfoItem(Icons.terrain_outlined, 'Altitud', '${lot.altitudeMasl} m.s.n.m.'),
        ]),
        const SizedBox(height: 20),
        if (lot.notes != null && lot.notes!.isNotEmpty) ...[
          _SectionTitle('Notas'),
          const SizedBox(height: 8),
          _NotesCard(lot.notes!),
          const SizedBox(height: 20),
        ],
        _SectionTitle('Procesos'),
        const SizedBox(height: 12),
        _ProcessButton(
          icon: Icons.science_outlined,
          label: 'Iniciar / Ver fermentación',
          color: AppColors.aiBlue,
          onTap: () => context.go(
            AppRoutes.fermentation.replaceFirst(':id', lot.id),
          ),
        ),
        const SizedBox(height: 10),
        _ProcessButton(
          icon: Icons.wb_sunny_outlined,
          label: 'Iniciar / Ver secado',
          color: AppColors.caramel,
          onTap: () => context.go(
            AppRoutes.drying.replaceFirst(':id', lot.id),
          ),
        ),
        const SizedBox(height: 10),
        _ProcessButton(
          icon: Icons.grass_outlined,
          label: 'Iniciar / Ver recolección',
          color: AppColors.roleFarmer,
          onTap: () => context.go(
            AppRoutes.harvest.replaceFirst(':id', lot.id),
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.lot});

  final Lot lot;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusInfo(lot.status);
    final (processLabel, _) = _processInfo(lot.processType);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(lot.varietyName, style: AppTextStyles.displaySmall),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$processLabel · ${lot.region.isNotEmpty ? lot.region : "—"}',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Creado: ${_formatDate(lot.createdAt)}',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  (String, Color) _statusInfo(String status) => switch (status) {
    'pending'    => ('Pendiente',   AppColors.warning),
    'fermenting' => ('Fermentando', AppColors.aiBlue),
    'drying'     => ('Secando',     AppColors.caramel),
    'milling'    => ('Trillando',   AppColors.roleProcessor),
    'ready'      => ('Listo',       AppColors.success),
    _            => (status,        AppColors.onSurfaceVariant),
  };

  (String, IconData) _processInfo(String process) => switch (process) {
    'lavado'    => ('Lavado',    Icons.water_drop_outlined),
    'natural'   => ('Natural',   Icons.wb_sunny_outlined),
    'honey'     => ('Honey',     Icons.hexagon_outlined),
    'anaerobio' => ('Anaerobio', Icons.science_outlined),
    _           => (process,     Icons.filter_outlined),
  };

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(color: AppColors.onSurfaceVariant),
      );
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid(this.items);

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: items.map((item) => _InfoItemCard(item: item)).toList(),
    );
  }
}

class _InfoItem {
  const _InfoItem(this.icon, this.label, this.value);

  final IconData icon;
  final String   label;
  final String   value;
}

class _InfoItemCard extends StatelessWidget {
  const _InfoItemCard({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: AppColors.caramel),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.label, style: AppTextStyles.bodySmall),
                Text(
                  item.value,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
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

class _NotesCard extends StatelessWidget {
  const _NotesCard(this.notes);

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(notes, style: AppTextStyles.bodyMedium),
    );
  }
}

class _ProcessButton extends StatelessWidget {
  const _ProcessButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      label: Text(label, style: AppTextStyles.buttonMedium.copyWith(color: color)),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

