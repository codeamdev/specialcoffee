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
import 'package:special_coffee/presentation/providers/lot_steps_provider.dart';

class LotDetailScreen extends ConsumerWidget {
  const LotDetailScreen({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotAsync = ref.watch(lotByIdProvider(lotId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Detalle del lote'),
        actions: [
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
        ]),
        const SizedBox(height: 20),
        if (lot.notes != null && lot.notes!.isNotEmpty) ...[
          _SectionTitle('Notas'),
          const SizedBox(height: 8),
          _NotesCard(lot.notes!),
          const SizedBox(height: 20),
        ],
        _SectionTitle('Etapas del proceso'),
        const SizedBox(height: 16),
        _LotStepper(lotId: lot.id),
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

// ── Stepper ────────────────────────────────────────────────────────────────

class _LotStepper extends ConsumerWidget {
  const _LotStepper({required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(lotStepsProvider(lotId));
    return stepsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) => Column(
        children: [
          for (int i = 0; i < state.steps.length; i++)
            _StepTile(
              step:   state.steps[i],
              isLast: i == state.steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step, required this.isLast});

  final LotStep step;
  final bool    isLast;

  @override
  Widget build(BuildContext context) {
    final isNext = step.status == StepStatus.next;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 36,
            child: Column(
              children: [
                _StepCircle(status: step.status),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: step.status == StepStatus.done
                            ? AppColors.success.withValues(alpha: 0.5)
                            : AppColors.outlineVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Step card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: InkWell(
                onTap: () => context.go(step.route),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isNext
                        ? AppColors.aiBlue.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isNext
                          ? AppColors.aiBlue.withValues(alpha: 0.35)
                          : AppColors.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(step.label,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: step.status == StepStatus.pending
                                          ? AppColors.onSurfaceVariant
                                          : AppColors.onSurface,
                                    )),
                                if (isNext) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.aiBlue,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Siguiente',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _subtitle(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: step.status == StepStatus.pending
                            ? AppColors.outlineVariant
                            : AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle() => switch (step.status) {
    StepStatus.done    => 'Completado',
    StepStatus.active  => 'En progreso',
    StepStatus.next    => 'Acción recomendada',
    StepStatus.pending => 'Pendiente',
  };
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.status});

  final StepStatus status;

  @override
  Widget build(BuildContext context) => switch (status) {
    StepStatus.done => Container(
      width: 28, height: 28,
      decoration: const BoxDecoration(
        color: AppColors.success, shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
    ),
    StepStatus.active => Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.warning, width: 2),
      ),
      child: Center(
        child: Container(
          width: 10, height: 10,
          decoration: const BoxDecoration(
            color: AppColors.warning, shape: BoxShape.circle,
          ),
        ),
      ),
    ),
    StepStatus.next => Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: AppColors.aiBlue.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.aiBlue, width: 2),
      ),
      child: const Icon(Icons.arrow_forward_rounded,
          size: 14, color: AppColors.aiBlue),
    ),
    StepStatus.pending => Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outlineVariant, width: 2),
      ),
    ),
  };
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

