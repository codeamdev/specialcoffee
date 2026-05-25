import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/classification_session.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/presentation/providers/classification_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';
import 'package:special_coffee/presentation/widgets/ai/recommendation_card.dart';

class ClassificationScreen extends ConsumerStatefulWidget {
  const ClassificationScreen({super.key, required this.lotId});

  final String lotId;

  @override
  ConsumerState<ClassificationScreen> createState() =>
      _ClassificationScreenState();
}

class _ClassificationScreenState extends ConsumerState<ClassificationScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _kgEntradaCtrl  = TextEditingController();
  final _brixCtrl       = TextEditingController();
  final _kgFlotCtrl     = TextEditingController(text: '0.0');
  final _kgManualCtrl   = TextEditingController(text: '0.0');
  final _notesCtrl      = TextEditingController();

  @override
  void dispose() {
    _kgEntradaCtrl.dispose();
    _brixCtrl.dispose();
    _kgFlotCtrl.dispose();
    _kgManualCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Computed preview ──────────────────────────────────────────────────────

  double get _kgEntrada       => double.tryParse(_kgEntradaCtrl.text) ?? 0;
  double get _kgFlot          => double.tryParse(_kgFlotCtrl.text) ?? 0;
  double get _kgManual        => double.tryParse(_kgManualCtrl.text) ?? 0;
  double get _kgSeleccionado  => (_kgEntrada - _kgFlot - _kgManual).clamp(0, _kgEntrada);
  double get _pctAprov        => _kgEntrada > 0 ? (_kgSeleccionado / _kgEntrada * 100) : 0;
  double get _pctFlot         => _kgEntrada > 0 ? (_kgFlot / _kgEntrada * 100) : 0;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classificationProvider(widget.lotId));

    ref.listen(classificationProvider(widget.lotId), (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
        ));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Clasificación de cerezas')),
      body: state.isComplete
          ? _ResultView(
              session:         state.session!,
              recommendations: state.recommendations,
              lotId:           widget.lotId,
            )
          : _FormView(
              formKey:       _formKey,
              kgEntradaCtrl: _kgEntradaCtrl,
              brixCtrl:      _brixCtrl,
              kgFlotCtrl:    _kgFlotCtrl,
              kgManualCtrl:  _kgManualCtrl,
              notesCtrl:     _notesCtrl,
              kgSeleccionado: _kgSeleccionado,
              pctAprov:       _pctAprov,
              pctFlot:        _pctFlot,
              isLoading:      state.isLoading,
              onChanged:      () => setState(() {}),
              onSubmit:       _submit,
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(classificationProvider(widget.lotId).notifier).classify(
      kgEntrada:        _kgEntrada,
      kgFlotantes:      _kgFlot,
      kgDescarteManual: _kgManual,
      brixCereza:       _brixCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_brixCtrl.text.trim()),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
  }
}

// ── Form view ──────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  const _FormView({
    required this.formKey,
    required this.kgEntradaCtrl,
    required this.brixCtrl,
    required this.kgFlotCtrl,
    required this.kgManualCtrl,
    required this.notesCtrl,
    required this.kgSeleccionado,
    required this.pctAprov,
    required this.pctFlot,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState>    formKey;
  final TextEditingController   kgEntradaCtrl;
  final TextEditingController   brixCtrl;
  final TextEditingController   kgFlotCtrl;
  final TextEditingController   kgManualCtrl;
  final TextEditingController   notesCtrl;
  final double                  kgSeleccionado;
  final double                  pctAprov;
  final double                  pctFlot;
  final bool                    isLoading;
  final VoidCallback            onChanged;
  final VoidCallback            onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Intro(),
          const SizedBox(height: 16),
          Form(
            key: formKey,
            onChanged: onChanged,
            child: Column(
              children: [
                _InputCard(
                  title: 'Entrada y Brix',
                  icon: Icons.scale_outlined,
                  children: [
                    _field(kgEntradaCtrl, 'Kg totales que entran', required: true,
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Ingresa un peso válido';
                          return null;
                        }),
                    const SizedBox(height: 12),
                    _field(brixCtrl, '°Brix de cereza (opcional)',
                        hint: '18–24 = óptimo specialty',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final n = double.tryParse(v);
                          if (n == null || n < 5 || n > 35) return '5–35 °Brix';
                          return null;
                        }),
                  ],
                ),
                const SizedBox(height: 12),
                _InputCard(
                  title: 'Descartes',
                  icon: Icons.water_drop_outlined,
                  subtitle: 'Deja en 0 si no aplica',
                  children: [
                    _field(kgFlotCtrl, 'Kg flotantes (flotación)',
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n < 0) return '≥ 0';
                          return null;
                        }),
                    const SizedBox(height: 12),
                    _field(kgManualCtrl, 'Kg descarte manual (selección)',
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n < 0) return '≥ 0';
                          return null;
                        }),
                  ],
                ),
                const SizedBox(height: 12),
                _LiveSummaryCard(
                  kgSeleccionado: kgSeleccionado,
                  pctAprov:       pctAprov,
                  pctFlot:        pctFlot,
                ),
                const SizedBox(height: 12),
                _InputCard(
                  title: 'Notas',
                  icon: Icons.notes_outlined,
                  children: [
                    TextFormField(
                      controller: notesCtrl,
                      decoration: _decor('Observaciones adicionales (opcional)'),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onSubmit,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                isLoading ? 'Analizando...' : 'Registrar clasificación y ver recomendaciones',
                style: AppTextStyles.buttonLarge,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.aiBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.aiBlue.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static TextFormField _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    bool required = false,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        decoration: _decor(label, hint: hint),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppTextStyles.numericSmall.copyWith(color: AppColors.onSurface),
        validator: validator,
      );

  static InputDecoration _decor(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText:  hint,
        labelStyle: AppTextStyles.labelMedium,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.aiBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ── Live summary card ──────────────────────────────────────────────────────

class _LiveSummaryCard extends StatelessWidget {
  const _LiveSummaryCard({
    required this.kgSeleccionado,
    required this.pctAprov,
    required this.pctFlot,
  });

  final double kgSeleccionado;
  final double pctAprov;
  final double pctFlot;

  @override
  Widget build(BuildContext context) {
    final aprovColor = pctAprov >= 60
        ? AppColors.success
        : pctAprov >= 45
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.aiBlueContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.aiBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calculate_outlined, size: 16, color: AppColors.aiBlue),
            const SizedBox(width: 6),
            Text('Resumen en tiempo real', style: AppTextStyles.labelMedium.copyWith(color: AppColors.aiBlue)),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              _Metric('Kg seleccionados', '${kgSeleccionado.toStringAsFixed(1)} kg', AppColors.onSurface),
              const SizedBox(width: 16),
              _Metric('Aprovechamiento', '${pctAprov.toStringAsFixed(1)}%', aprovColor),
              const SizedBox(width: 16),
              _Metric('Flotación', '${pctFlot.toStringAsFixed(1)}%', AppColors.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color  color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.bodySmall),
            Text(value,
                style: AppTextStyles.numericSmall.copyWith(
                    color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

// ── Result view ────────────────────────────────────────────────────────────

class _ResultView extends ConsumerWidget {
  const _ResultView({
    required this.session,
    required this.recommendations,
    required this.lotId,
  });

  final ClassificationSession session;
  final List<Recommendation>  recommendations;
  final String                lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotAsync = ref.watch(lotByIdProvider(lotId));
    final processType = lotAsync.asData?.value?.processType ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryResultCard(session: session),
          const SizedBox(height: 20),
          if (recommendations.isNotEmpty) ...[
            Row(children: [
              Container(width: 4, height: 24,
                decoration: BoxDecoration(color: AppColors.aiBlue, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text('Recomendaciones IA', style: AppTextStyles.displaySmall.copyWith(fontSize: 20)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.aiBlueContainer,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${recommendations.length}',
                    style: AppTextStyles.aiCaption.copyWith(fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 14),
            ...recommendations.indexed.map((e) =>
                RecommendationCard(recommendation: e.$2, isTopCard: e.$1 == 0)),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _navigateToProcess(context, processType),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(_processButtonLabel(processType), style: AppTextStyles.buttonLarge),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.roleFarmer,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go(AppRoutes.lotDetail.replaceFirst(':id', lotId)),
              child: const Text('Volver al lote'),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProcess(BuildContext context, String processType) {
    final route = switch (processType) {
      // Non-natural processes: classification → depulping → fermentation → drying
      'lavado' || 'honey_yellow' || 'anaerobic_lactic' =>
          AppRoutes.depulping.replaceFirst(':id', lotId),
      // Natural: classification → drying directly (no depulping/fermentation)
      'natural' => AppRoutes.drying.replaceFirst(':id', lotId),
      _ => AppRoutes.lotDetail.replaceFirst(':id', lotId),
    };
    context.go(route);
  }

  String _processButtonLabel(String processType) => switch (processType) {
    'lavado'           => 'Ir al despulpado →',
    'honey_yellow'     => 'Ir al despulpado →',
    'anaerobic_lactic' => 'Ir al despulpado →',
    'natural'          => 'Iniciar secado natural →',
    _                  => 'Continuar al proceso →',
  };
}

class _SummaryResultCard extends StatelessWidget {
  const _SummaryResultCard({required this.session});

  final ClassificationSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            const Text('Clasificación registrada', style: AppTextStyles.labelLarge),
          ]),
          const SizedBox(height: 16),
          _Row('Kg entrada',        '${session.kgEntrada.toStringAsFixed(1)} kg'),
          _Row('Kg seleccionados',  '${session.kgSeleccionado.toStringAsFixed(1)} kg'),
          _Row('Aprovechamiento',   '${session.pctAprovechamiento.toStringAsFixed(1)}%'),
          _Row('Flotación',         '${session.pctFlotacion.toStringAsFixed(1)}%'),
          if (session.brixCereza != null)
            _Row('Brix cereza',     '${session.brixCereza!.toStringAsFixed(1)}°'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyMedium),
            Text(value,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// ── Small helpers ──────────────────────────────────────────────────────────

class _Intro extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
        'Registra los resultados de flotación y selección manual. '
        'El Brix confirma la madurez antes de iniciar el proceso.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
      );
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
  });

  final String        title;
  final IconData      icon;
  final String?       subtitle;
  final List<Widget>  children;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: AppColors.caramel),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.labelLarge),
            ]),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: AppTextStyles.bodySmall),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
}
