import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/depulping_session.dart';
import 'package:special_coffee/presentation/providers/depulping_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';
import 'package:special_coffee/presentation/widgets/ai/recommendation_card.dart';

class DepulpingScreen extends ConsumerStatefulWidget {
  const DepulpingScreen({super.key, required this.lotId});

  final String lotId;

  @override
  ConsumerState<DepulpingScreen> createState() => _DepulpingScreenState();
}

class _DepulpingScreenState extends ConsumerState<DepulpingScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _kgCtrl     = TextEditingController();
  final _notesCtrl  = TextEditingController();
  DateTime _depulpedAt = DateTime.now();

  @override
  void dispose() {
    _kgCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(depulpingProvider(widget.lotId));
    final lotAsync = ref.watch(lotByIdProvider(widget.lotId));
    final processType = lotAsync.asData?.value?.processType ?? '';

    ref.listen(depulpingProvider(widget.lotId), (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
        ));
      }
    });

    // Pre-fill kg once from classification
    if (_kgCtrl.text.isEmpty && state.kgPreFilled != null) {
      _kgCtrl.text = state.kgPreFilled!.toStringAsFixed(1);
    }

    // Natural process: no depulping needed — redirect to drying
    if (processType == 'natural') {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(title: const Text('Despulpado')),
        body: _NaturalRedirect(lotId: widget.lotId),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Despulpado')),
      body: state.isComplete
          ? _ResultView(
              session:         state.session!,
              recommendations: state.recommendations,
              lotId:           widget.lotId,
              processType:     processType,
            )
          : _FormView(
              formKey:     _formKey,
              kgCtrl:      _kgCtrl,
              notesCtrl:   _notesCtrl,
              depulpedAt:  _depulpedAt,
              state:       state,
              isLoading:   state.isLoading,
              onDatePicked: (dt) => setState(() => _depulpedAt = dt),
              onSubmit:    _submit,
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(depulpingProvider(widget.lotId).notifier).register(
      kgDepulped: double.parse(_kgCtrl.text.trim()),
      depulpedAt: _depulpedAt,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
  }
}

// ── Natural redirect ───────────────────────────────────────────────────────

class _NaturalRedirect extends StatelessWidget {
  const _NaturalRedirect({required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wb_sunny_outlined, size: 64, color: AppColors.caramel),
          const SizedBox(height: 20),
          Text(
            'El proceso natural no requiere despulpado',
            style: AppTextStyles.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'La cereza entera pasa directamente al secado, '
            'donde el mucílago se seca sobre el grano.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go(
                AppRoutes.drying.replaceFirst(':id', lotId),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Ir al secado natural →'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go(
                AppRoutes.lotDetail.replaceFirst(':id', lotId),
              ),
              child: const Text('Volver al lote'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Form view ──────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  const _FormView({
    required this.formKey,
    required this.kgCtrl,
    required this.notesCtrl,
    required this.depulpedAt,
    required this.state,
    required this.isLoading,
    required this.onDatePicked,
    required this.onSubmit,
  });

  final GlobalKey<FormState>  formKey;
  final TextEditingController kgCtrl;
  final TextEditingController notesCtrl;
  final DateTime              depulpedAt;
  final DepulpingState        state;
  final bool                  isLoading;
  final void Function(DateTime) onDatePicked;
  final VoidCallback          onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.hasReference) _DelayCard(state: state),
          const SizedBox(height: 16),
          Form(
            key: formKey,
            child: Column(
              children: [
                _card(
                  title:    'Registro de despulpado',
                  icon:     Icons.settings_outlined,
                  children: [
                    TextFormField(
                      controller: kgCtrl,
                      decoration: _decor('Kg despulpados'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: AppTextStyles.numericSmall.copyWith(color: AppColors.onSurface),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Ingresa un peso válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _DateTimeField(
                      value:    depulpedAt,
                      onPicked: onDatePicked,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _card(
                  title:    'Notas',
                  icon:     Icons.notes_outlined,
                  children: [
                    TextFormField(
                      controller: notesCtrl,
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
              onPressed: isLoading ? null : onSubmit,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: Text(
                isLoading ? 'Registrando...' : 'Registrar despulpado',
                style: AppTextStyles.buttonLarge,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roleProcessor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.roleProcessor.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
              Icon(icon, size: 18, color: AppColors.caramel),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.labelLarge),
            ]),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  static InputDecoration _decor(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelMedium,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.roleProcessor, width: 2),
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

// ── Delay alert card ───────────────────────────────────────────────────────

class _DelayCard extends StatelessWidget {
  const _DelayCard({required this.state});

  final DepulpingState state;

  @override
  Widget build(BuildContext context) {
    final hours = state.hoursElapsed;
    final Color bg;
    final Color border;
    final IconData icon;
    final String label;

    if (hours >= 8) {
      bg     = AppColors.error.withValues(alpha: 0.08);
      border = AppColors.error.withValues(alpha: 0.4);
      icon   = Icons.error_outline;
      label  = 'Crítico';
    } else if (hours >= 6) {
      bg     = AppColors.warning.withValues(alpha: 0.08);
      border = AppColors.warning.withValues(alpha: 0.4);
      icon   = Icons.warning_amber_outlined;
      label  = 'Advertencia';
    } else {
      bg     = AppColors.success.withValues(alpha: 0.08);
      border = AppColors.success.withValues(alpha: 0.3);
      icon   = Icons.check_circle_outline;
      label  = 'A tiempo';
    }

    final refLabel = state.referenceSource == 'classification'
        ? 'desde clasificación'
        : 'desde último pase de cosecha';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:  bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28,
              color: hours >= 8
                  ? AppColors.error
                  : hours >= 6
                      ? AppColors.warning
                      : AppColors.success),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$label — ${hours.toStringAsFixed(1)} h $refLabel',
                    style: AppTextStyles.labelMedium),
                const SizedBox(height: 2),
                Text(
                  hours >= 8
                      ? 'Supera el límite crítico de 8 h (C-1). Despulpar de inmediato.'
                      : hours >= 6
                          ? 'Superando las 6 h preventivas. Despulpe pronto.'
                          : 'Dentro del rango seguro. Despulpe antes de las ${8.0.toStringAsFixed(0)} h.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── DateTime picker field ──────────────────────────────────────────────────

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({required this.value, required this.onPicked});

  final DateTime              value;
  final void Function(DateTime) onPicked;

  @override
  Widget build(BuildContext context) {
    final label =
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
        '  ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now().subtract(const Duration(days: 3)),
          lastDate: DateTime.now(),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        if (time == null) return;
        onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha/hora del despulpado',
          labelStyle: AppTextStyles.labelMedium,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.outlineVariant),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        child: Text(label, style: AppTextStyles.bodyMedium),
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
    required this.processType,
  });

  final DepulpingSession     session;
  final List<Recommendation> recommendations;
  final String               lotId;
  final String               processType;

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
            ...recommendations.indexed
                .map((e) => RecommendationCard(recommendation: e.$2, isTopCard: e.$1 == 0)),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go(_nextRoute()),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(_nextLabel(), style: AppTextStyles.buttonLarge),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.aiBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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

  String _nextRoute() => switch (processType) {
    'natural' => AppRoutes.drying.replaceFirst(':id', lotId),
    _         => AppRoutes.fermentation.replaceFirst(':id', lotId),
  };

  String _nextLabel() => switch (processType) {
    'honey_yellow'     => 'Iniciar fermentación Honey →',
    'anaerobic_lactic' => 'Iniciar fermentación anaeróbica →',
    'natural'          => 'Iniciar secado natural →',
    _                  => 'Iniciar fermentación →',
  };
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.session});

  final DepulpingSession session;

  @override
  Widget build(BuildContext context) {
    final refLabel = switch (session.referenceSource) {
      'classification' => 'clasificación',
      'harvest_pass'   => 'último pase',
      _                => null,
    };

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
            Text('Despulpado registrado', style: AppTextStyles.labelLarge),
          ]),
          const SizedBox(height: 16),
          _Row('Kg despulpados', '${session.kgDepulped.toStringAsFixed(1)} kg'),
          if (session.hoursFromReference != null && refLabel != null)
            _Row('Tiempo desde $refLabel',
                '${session.hoursFromReference!.toStringAsFixed(1)} h'),
          _Row('Referencia usada', _refSourceLabel(session.referenceSource)),
        ],
      ),
    );
  }

  String _refSourceLabel(String src) => switch (src) {
    'classification' => 'Clasificación de cerezas',
    'harvest_pass'   => 'Último pase de cosecha',
    _                => 'Sin referencia',
  };
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
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
