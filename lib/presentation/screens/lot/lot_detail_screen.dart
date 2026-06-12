import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/lot.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/cupping_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

class LotDetailScreen extends ConsumerWidget {
  const LotDetailScreen({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotAsync = ref.watch(lotByIdProvider(lotId));
    final role     = ref.watch(currentUserProvider)?.role ?? '';
    const editRoles = {'producer_integral', 'producer', 'farmer', 'admin', 'processor'};

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Detalle del lote'),
        actions: [
          if (editRoles.contains(role))
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar lote',
              onPressed: () {
                final lot = lotAsync.value;
                if (lot != null) context.push('/lots/${lot.id}/edit', extra: lot);
              },
            ),
          IconButton(
            icon: const Icon(Icons.qr_code_outlined),
            tooltip: 'QR del lote',
            onPressed: () => _showQr(context),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Exportar PDF',
            onPressed: () => _exportPdf(context, ref, lotAsync.value),
          ),
        ],
      ),
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

  void _showQr(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('QR del Lote'),
        content: SizedBox(
          width: 220,
          height: 220,
          child: QrImageView(data: lotId, version: QrVersions.auto, size: 200),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref, Lot? lot) async {
    if (lot == null) return;
    final userId  = ref.read(currentUserIdProvider);
    final stats   = await ref.read(userStatsProvider(userId).future);
    final doc     = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Reporte de Lote — SpecialCoffee AI',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Variedad: ${lot.varietyName}'),
            pw.Text('Región: ${lot.region}'),
            pw.Text('Proceso: ${lot.processType}'),
            pw.Text('Altitud: ${lot.altitudeMasl} m.s.n.m.'),
            pw.Text('Creado: ${_fmtDate(lot.createdAt)}'),
            pw.SizedBox(height: 16),
            pw.Text('Estadísticas del productor',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Lotes catados: ${stats.lotsCupped}'),
            if (stats.isReliable) ...[
              pw.Text('SCA promedio: ${stats.avgScaScore.toStringAsFixed(1)} pts'),
              pw.Text('Mejor puntaje: ${stats.bestScore.toStringAsFixed(1)} pts'),
            ],
            pw.SizedBox(height: 24),
            pw.Text('Generado por SpecialCoffee AI · ${_fmtDate(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'lote_${lot.id.substring(0, 8)}.pdf');
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
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
          if (lot.latitude != null)
            _InfoItem(Icons.gps_fixed_outlined, 'Latitud', lot.latitude!.toStringAsFixed(6)),
          if (lot.longitude != null)
            _InfoItem(Icons.gps_fixed_outlined, 'Longitud', lot.longitude!.toStringAsFixed(6)),
        ]),
        const SizedBox(height: 20),
        if (lot.notes != null && lot.notes!.isNotEmpty) ...[
          _SectionTitle('Notas'),
          const SizedBox(height: 8),
          _NotesCard(lot.notes!),
          const SizedBox(height: 20),
        ],
        _BatchInsightsCard(lotId: lot.id),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.lot});

  final Lot lot;

  @override
  Widget build(BuildContext context) {
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
          Text(lot.varietyName, style: AppTextStyles.displaySmall),
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

  (String, IconData) _processInfo(String process) => switch (process) {
    'lavado'    => ('Lavado',    Icons.water_drop_outlined),
    'natural'   => ('Natural',   Icons.wb_sunny_outlined),
    'honey_yellow'     => ('Honey',     Icons.hexagon_outlined),
    'anaerobic_lactic' => ('Anaerobio', Icons.science_outlined),
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

// ── Batch Insights Card ───────────────────────────────────────────────────────

class _BatchInsightsCard extends ConsumerWidget {
  const _BatchInsightsCard({required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<DbLotInsight?>(
      future: ref.read(appDatabaseProvider).batchInsightsDao.getByLotId(lotId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final insight = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Análisis del proceso'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.aiBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.aiBlue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.auto_awesome_outlined,
                          size: 16, color: AppColors.aiBlue),
                      const SizedBox(width: 6),
                      Text(
                        'SCA ${insight.scaScore.toStringAsFixed(1)} pts',
                        style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.aiBlue),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      insight.insightText,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

