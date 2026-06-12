import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/cosecha_pase.dart';
import 'package:special_coffee/presentation/providers/cosecha_pase_provider.dart';

class PaseDetailScreen extends ConsumerWidget {
  const PaseDetailScreen({super.key, required this.paseId});
  final String paseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paseAsync = ref.watch(paseByIdProvider(paseId));
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Pase de cosecha'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: paseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (pase) => pase == null
            ? const Center(child: Text('Pase no encontrado'))
            : _PaseBody(pase: pase),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _PaseBody extends ConsumerWidget {
  const _PaseBody({required this.pase});
  final CosechaPase pase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
      children: [
        _HeaderCard(pase: pase),
        const SizedBox(height: 20),
        _SectionLabel('Etapas del proceso'),
        const SizedBox(height: 12),
        _PaseStepper(pase: pase),
        if (pase.isActive) ...[
          const SizedBox(height: 24),
          if (pase.etapaActual == 'clasificacion')
            _ClasificacionCard(pase: pase)
          else
            _EtapaCard(pase: pase),
        ],
        if (pase.pesoCerezaKg > 0) ...[
          const SizedBox(height: 20),
          _DataCard(pase: pase),
        ],
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.pase});
  final CosechaPase pase;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusInfo(pase.status);
    return Container(
      padding: const EdgeInsets.all(18),
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
                child: Text(pase.tipoProcesoLabel,
                    style: AppTextStyles.displaySmall),
              ),
              _Chip(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _fmtDate(pase.fechaRecoleccion),
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            '${pase.pesoCerezaKg.toStringAsFixed(1)} kg cereza',
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.caramel.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Etapa: ${pase.etapaLabel}',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.caramel),
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _statusInfo(String s) => switch (s) {
        'activo'     => ('Activo',     AppColors.success),
        'completado' => ('Completado', AppColors.aiBlue),
        'abandonado' => ('Abandonado', AppColors.error),
        _            => (s,            AppColors.onSurfaceVariant),
      };

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: AppTextStyles.labelSmall.copyWith(
                color: color, fontWeight: FontWeight.w700)),
      );
}

// ── Stepper ───────────────────────────────────────────────────────────────────

class _PaseStepper extends StatelessWidget {
  const _PaseStepper({required this.pase});
  final CosechaPase pase;

  @override
  Widget build(BuildContext context) {
    final stages     = pase.stages;
    final isComplete = pase.isCompleted;
    final curIdx     = isComplete ? stages.length : stages.indexOf(pase.etapaActual);
    return Column(
      children: [
        for (int i = 0; i < stages.length; i++)
          _StepRow(
            etapa:  stages[i],
            status: i < curIdx
                ? _S.done
                : i == curIdx
                    ? _S.active
                    : _S.pending,
            isLast: i == stages.length - 1,
          ),
      ],
    );
  }
}

enum _S { done, active, pending }

class _StepRow extends StatelessWidget {
  const _StepRow(
      {required this.etapa, required this.status, required this.isLast});
  final String etapa;
  final _S     status;
  final bool   isLast;

  @override
  Widget build(BuildContext context) {
    final isActive = status == _S.active;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                _Circle(status: status),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: status == _S.done
                            ? AppColors.success.withValues(alpha: 0.5)
                            : AppColors.outlineVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.caramel.withValues(alpha: 0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? AppColors.caramel.withValues(alpha: 0.4)
                        : AppColors.outlineVariant,
                  ),
                ),
                child: Text(
                  CosechaPase.labelForEtapa(etapa),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: status == _S.pending
                        ? AppColors.onSurfaceVariant
                        : AppColors.onSurface,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.status});
  final _S status;

  @override
  Widget build(BuildContext context) => switch (status) {
        _S.done => Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(
              color: AppColors.success, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded,
              size: 16, color: Colors.white),
        ),
        _S.active => Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color:  AppColors.caramel.withValues(alpha: 0.12),
            shape:  BoxShape.circle,
            border: Border.all(color: AppColors.caramel, width: 2),
          ),
          child: Center(
            child: Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(
                  color: AppColors.caramel, shape: BoxShape.circle),
            ),
          ),
        ),
        _S.pending => Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color:  Colors.white,
            shape:  BoxShape.circle,
            border: Border.all(color: AppColors.outlineVariant, width: 2),
          ),
        ),
      };
}

// ── Clasificación inline ──────────────────────────────────────────────────────

class _ClasificacionCard extends ConsumerStatefulWidget {
  const _ClasificacionCard({required this.pase});
  final CosechaPase pase;

  @override
  ConsumerState<_ClasificacionCard> createState() =>
      _ClasificacionCardState();
}

class _ClasificacionCardState extends ConsumerState<_ClasificacionCard> {
  final _formKey       = GlobalKey<FormState>();
  final _flotacionCtrl = TextEditingController();
  final _pctCtrl       = TextEditingController();
  final _pergCtrl      = TextEditingController();
  final _horasCtrl     = TextEditingController();
  bool _saving = false;

  bool get _needsDespulpado =>
      !const {'natural', 'honey_yellow', 'honey_red'}
          .contains(widget.pase.tipoProceso);

  @override
  void dispose() {
    _flotacionCtrl.dispose();
    _pctCtrl.dispose();
    _pergCtrl.dispose();
    _horasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextEtapa = widget.pase.stages[
        widget.pase.stages.indexOf('clasificacion') + 1];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.caramel.withValues(alpha: 0.3)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clasificación',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.caramel)),
            const SizedBox(height: 12),
            _InlineField(
              ctrl:    _flotacionCtrl,
              label:   'Peso flotantes (kg)',
              hint:    'ej. 12.5',
            ),
            const SizedBox(height: 10),
            _InlineField(
              ctrl:    _pctCtrl,
              label:   '% flotación',
              hint:    'ej. 3.2',
            ),
            if (_needsDespulpado) ...[
              const SizedBox(height: 16),
              Text('Despulpado',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.caramel)),
              const SizedBox(height: 12),
              _InlineField(
                ctrl:    _pergCtrl,
                label:   'Peso pergamino húmedo (kg)',
                hint:    'ej. 380',
                required: true,
                validator: (v) =>
                    (v == null || double.tryParse(v.trim().replaceAll(',', '.')) == null)
                        ? 'Requerido'
                        : null,
              ),
              const SizedBox(height: 10),
              _InlineField(
                ctrl:  _horasCtrl,
                label: 'Horas hasta despulpe',
                hint:  'ej. 6',
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : () => _confirm(nextEtapa),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: AppColors.caramel,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Confirmar y pasar a '
                      '${CosechaPase.labelForEtapa(nextEtapa)}',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _norm(String s) => s.trim().replaceAll(',', '.');

  Future<void> _confirm(String nextEtapa) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Capture repo before any async gap — avoids autoDispose issues.
    final repo = ref.read(cosechaPaseLocalRepoProvider);
    try {
      final pesoFlot = double.tryParse(_norm(_flotacionCtrl.text));
      final pctFlot  = double.tryParse(_norm(_pctCtrl.text));

      if (pesoFlot != null) {
        await repo.updateClasificacion(widget.pase.id,
            pesoFlotacionKg: pesoFlot, pctFlotacion: pctFlot);
      }

      if (_needsDespulpado) {
        final perg  = double.tryParse(_norm(_pergCtrl.text));
        final horas = double.tryParse(_norm(_horasCtrl.text));
        if (perg != null) {
          await repo.updateDespulpado(widget.pase.id,
              pesoPergaminoHumedoKg: perg,
              horasHastaDespulpe: horas);
        }
      }

      await repo.advanceEtapa(widget.pase.id, nextEtapa);

      if (mounted) {
        ref.invalidate(paseByIdProvider(widget.pase.id));
        ref.invalidate(pasesByLotProvider(widget.pase.lotId));
        ref.invalidate(activePasesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.required = false,
    this.validator,
  });
  final TextEditingController      ctrl;
  final String                     label;
  final String                     hint;
  final bool                       required;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller:   ctrl,
        keyboardType: TextInputType.number,
        validator:    validator,
        decoration: InputDecoration(
          labelText:   label,
          hintText:    hint,
          border:      OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
          filled:      true,
          fillColor:   AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense:     true,
        ),
      );
}

// ── Etapa en curso (no clasificacion) ─────────────────────────────────────────

class _EtapaCard extends ConsumerWidget {
  const _EtapaCard({required this.pase});
  final CosechaPase pase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = _routeFor(pase);

    // When the stage has its own screen, that screen owns the transition.
    // Only show the bypass buttons for unhandled stages (route == null).
    if (route != null) {
      return FilledButton.icon(
        onPressed: () => context.push(route),
        icon:  const Icon(Icons.play_arrow_rounded),
        label: Text('Ir a ${pase.etapaLabel}'),
        style: FilledButton.styleFrom(
          minimumSize:     const Size.fromHeight(52),
          shape:           RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          backgroundColor: AppColors.caramel,
        ),
      );
    }

    // Fallback for stages without a dedicated screen
    final stages    = pase.stages;
    final curIdx    = stages.indexOf(pase.etapaActual);
    final isLast    = curIdx == stages.length - 1;
    final nextEtapa = isLast ? null : stages[curIdx + 1];

    return Column(
      children: [
        if (nextEtapa != null)
          OutlinedButton.icon(
            onPressed: () => _advance(context, ref, nextEtapa),
            icon:  const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text('Pasar a ${CosechaPase.labelForEtapa(nextEtapa)}'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () => _complete(context, ref),
            icon:  const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text('Marcar pase como completado'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }

  String? _routeFor(CosechaPase p) {
    final base = '${AppRoutes.lots}/${p.lotId}';
    return switch (p.etapaActual) {
      'fermentacion' => '$base/fermentation?paseId=${p.id}',
      'lavado'       => '$base/washing?paseId=${p.id}',
      'secado'       => '$base/drying?paseId=${p.id}',
      'trilla'       => '$base/milling?paseId=${p.id}',
      _              => null,
    };
  }

  Future<void> _advance(
      BuildContext ctx, WidgetRef ref, String nextEtapa) async {
    final repo = ref.read(cosechaPaseLocalRepoProvider);
    try {
      await repo.advanceEtapa(pase.id, nextEtapa);
      if (ctx.mounted) {
        ref.invalidate(paseByIdProvider(pase.id));
        ref.invalidate(pasesByLotProvider(pase.lotId));
        ref.invalidate(activePasesProvider);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Avanzado a ${CosechaPase.labelForEtapa(nextEtapa)}')),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Error: $e'), duration: const Duration(seconds: 6)),
        );
      }
    }
  }

  Future<void> _complete(BuildContext ctx, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Completar pase'),
        content: const Text(
            '¿Confirmas que este pase ha finalizado todo el proceso?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok != true || !ctx.mounted) return;
    final repo = ref.read(cosechaPaseLocalRepoProvider);
    try {
      await repo.completar(pase.id);
      if (ctx.mounted) {
        ref.invalidate(paseByIdProvider(pase.id));
        ref.invalidate(pasesByLotProvider(pase.lotId));
        ref.invalidate(activePasesProvider);
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Pase completado')),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Error: $e'), duration: const Duration(seconds: 6)),
        );
      }
    }
  }
}

// ── Datos registrados ─────────────────────────────────────────────────────────

class _DataCard extends StatelessWidget {
  const _DataCard({required this.pase});
  final CosechaPase pase;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      if (pase.brixPromedio != null)
        ('Brix', '${pase.brixPromedio!.toStringAsFixed(1)} °Bx'),
      if (pase.pctMadurezVisual != null)
        ('% Madurez', '${pase.pctMadurezVisual!.toStringAsFixed(0)} %'),
      if (pase.pesoFlotacionKg != null)
        ('Peso flotantes',
            '${pase.pesoFlotacionKg!.toStringAsFixed(1)} kg'),
      if (pase.pctFlotacion != null)
        ('% Flotación',
            '${pase.pctFlotacion!.toStringAsFixed(1)} %'),
      if (pase.pesoPergaminoHumedoKg != null)
        ('Pergamino húmedo',
            '${pase.pesoPergaminoHumedoKg!.toStringAsFixed(1)} kg'),
      if (pase.horasHastaDespulpe != null)
        ('Horas hasta despulpe',
            '${pase.horasHastaDespulpe!.toStringAsFixed(1)} h'),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Datos registrados'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(items[i].$1,
                        style: AppTextStyles.bodySmall),
                    Text(items[i].$2,
                        style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                if (i < items.length - 1)
                  const Divider(height: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTextStyles.labelLarge
          .copyWith(color: AppColors.onSurfaceVariant));
}
