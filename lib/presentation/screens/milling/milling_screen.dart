import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/milling_session.dart';
import 'package:special_coffee/presentation/providers/cosecha_pase_provider.dart';
import 'package:special_coffee/presentation/providers/milling_provider.dart';
import 'package:special_coffee/presentation/widgets/ai/recommendation_card.dart';

class MillingScreen extends ConsumerStatefulWidget {
  const MillingScreen({super.key, required this.lotId, this.paseId});

  final String  lotId;
  final String? paseId;

  @override
  ConsumerState<MillingScreen> createState() => _MillingScreenState();
}

class _MillingScreenState extends ConsumerState<MillingScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _inputCtrl    = TextEditingController();
  final _outputCtrl   = TextEditingController();
  final _notesCtrl    = TextEditingController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _outputCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(millingProvider(widget.lotId));

    ref.listen(millingProvider(widget.lotId), (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
        ));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Trilla')),
      body: state.isComplete
          ? _ResultView(
              session:         state.session!,
              recommendations: state.recommendations,
              lotId:           widget.lotId,
              paseId:          widget.paseId,
            )
          : _FormView(
              formKey:    _formKey,
              inputCtrl:  _inputCtrl,
              outputCtrl: _outputCtrl,
              notesCtrl:  _notesCtrl,
              isLoading:  state.isLoading,
              onSubmit:   _submit,
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(millingProvider(widget.lotId).notifier).register(
      inputKgParchment: double.parse(_inputCtrl.text.trim()),
      outputKgGreen:    double.parse(_outputCtrl.text.trim()),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
  }
}

// ── Form view ──────────────────────────────────────────────────────────────

class _FormView extends StatefulWidget {
  const _FormView({
    required this.formKey,
    required this.inputCtrl,
    required this.outputCtrl,
    required this.notesCtrl,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState>  formKey;
  final TextEditingController inputCtrl;
  final TextEditingController outputCtrl;
  final TextEditingController notesCtrl;
  final bool                  isLoading;
  final VoidCallback          onSubmit;

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  double? _previewYield;

  void _updateYield() {
    final input  = double.tryParse(widget.inputCtrl.text.trim());
    final output = double.tryParse(widget.outputCtrl.text.trim());
    setState(() {
      _previewYield = (input != null && output != null && input > 0)
          ? (output / input) * 100.0
          : null;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.inputCtrl.addListener(_updateYield);
    widget.outputCtrl.addListener(_updateYield);
  }

  @override
  void dispose() {
    widget.inputCtrl.removeListener(_updateYield);
    widget.outputCtrl.removeListener(_updateYield);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
            key: widget.formKey,
            child: Column(
              children: [
                _card(
                  title: 'Pesaje de Trilla',
                  icon:  Icons.scale_outlined,
                  children: [
                    _numField(
                      ctrl:  widget.inputCtrl,
                      label: 'Pergamino seco entrada (kg)',
                      hint:  '100.0',
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Ingrese un peso válido (> 0 kg)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _numField(
                      ctrl:  widget.outputCtrl,
                      label: 'Almendra verde salida (kg)',
                      hint:  '19.5',
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Ingrese un peso válido (> 0 kg)';
                        final input = double.tryParse(widget.inputCtrl.text.trim());
                        if (input != null && n >= input) return 'Salida debe ser menor que entrada';
                        return null;
                      },
                    ),
                    if (_previewYield != null) ...[
                      const SizedBox(height: 16),
                      _YieldPreview(yieldPct: _previewYield!),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _card(
                  title: 'Notas',
                  icon:  Icons.notes_outlined,
                  children: [
                    TextFormField(
                      controller: widget.notesCtrl,
                      decoration: _decor('Observaciones (opcional)'),
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
              onPressed: widget.isLoading ? null : widget.onSubmit,
              icon: widget.isLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.precision_manufacturing_outlined, size: 18),
              label: Text(
                widget.isLoading ? 'Registrando...' : 'Registrar trilla',
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

  static Widget _numField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required String? Function(String?) validator,
  }) =>
      TextFormField(
        controller: ctrl,
        decoration: _decor(label, hint: hint),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppTextStyles.numericSmall.copyWith(color: AppColors.onSurface),
        validator: validator,
      );

  static Widget _card({
    required String       title,
    required IconData     icon,
    required List<Widget> children,
  }) =>
      Container(
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
              Icon(icon, size: 18, color: AppColors.aiBlue),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.labelLarge),
            ]),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  static InputDecoration _decor(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText:  hint,
        labelStyle: AppTextStyles.labelMedium,
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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

// ── Yield preview ──────────────────────────────────────────────────────────

class _YieldPreview extends StatelessWidget {
  const _YieldPreview({required this.yieldPct});

  final double yieldPct;

  @override
  Widget build(BuildContext context) {
    final isLow  = yieldPct < 18.0;
    final isHigh = yieldPct > 22.0;
    final color = isLow
        ? AppColors.error
        : isHigh
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_outlined, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rendimiento estimado: ${yieldPct.toStringAsFixed(1)}%'
              '${isLow ? ' — por debajo del mínimo SCA (18%)' : isHigh ? ' — por encima del máximo SCA (22%)' : ' — dentro del rango SCA (18–22%)'}',
              style: AppTextStyles.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result view ────────────────────────────────────────────────────────────

class _ResultView extends ConsumerWidget {
  const _ResultView({
    required this.session,
    required this.recommendations,
    required this.lotId,
    this.paseId,
  });

  final MillingSession        session;
  final List<Recommendation>  recommendations;
  final String                lotId;
  final String?               paseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryCard(session: session),
          const SizedBox(height: 20),
          if (recommendations.isNotEmpty) ...[
            Row(children: [
              Container(
                width: 4, height: 24,
                decoration: BoxDecoration(
                    color: AppColors.aiBlue,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Text('Recomendaciones IA',
                  style: AppTextStyles.displaySmall.copyWith(fontSize: 20)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.aiBlueContainer,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${recommendations.length}',
                    style: AppTextStyles.aiCaption
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 14),
            ...recommendations.indexed.map(
                (e) => RecommendationCard(recommendation: e.$2, isTopCard: e.$1 == 0)),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: paseId != null
                  ? () async {
                      final router = GoRouter.of(context);
                      await ref
                          .read(cosechaPaseLocalRepoProvider)
                          .completar(paseId!);
                      ref.invalidate(paseByIdProvider(paseId!));
                      ref.invalidate(pasesByLotProvider(lotId));
                      if (!context.mounted) return;
                      router.pop();
                    }
                  : () => context.go(AppRoutes.cupping.replaceFirst(':id', lotId)),
              icon: Icon(
                paseId != null
                    ? Icons.check_circle_outline
                    : Icons.coffee_outlined,
                size: 18,
              ),
              label: Text(
                paseId != null ? 'Completar pase →' : 'Iniciar catación →',
                style: AppTextStyles.buttonLarge,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.aiBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  context.go(AppRoutes.lotDetail.replaceFirst(':id', lotId)),
              child: const Text('Volver al lote'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.session});

  final MillingSession session;

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
          const Row(children: [
            Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
            SizedBox(width: 8),
            Text('Trilla registrada', style: AppTextStyles.labelLarge),
          ]),
          const SizedBox(height: 16),
          _Row('Pergamino entrada', '${session.inputKgParchment.toStringAsFixed(1)} kg'),
          _Row('Almendra salida',   '${session.outputKgGreen.toStringAsFixed(1)} kg'),
          _Row('Rendimiento',       '${session.yieldPct.toStringAsFixed(1)} %'),
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
            Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
