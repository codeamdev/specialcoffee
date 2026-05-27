import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/washing_session.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';
import 'package:special_coffee/presentation/providers/washing_provider.dart';
import 'package:special_coffee/presentation/widgets/ai/recommendation_card.dart';

class WashingScreen extends ConsumerStatefulWidget {
  const WashingScreen({super.key, required this.lotId});

  final String lotId;

  @override
  ConsumerState<WashingScreen> createState() => _WashingScreenState();
}

class _WashingScreenState extends ConsumerState<WashingScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _tempCtrl      = TextEditingController();
  final _changesCtrl   = TextEditingController();
  final _phCtrl        = TextEditingController();
  final _durationCtrl  = TextEditingController();
  final _notesCtrl     = TextEditingController();
  DateTime _washedAt   = DateTime.now();

  @override
  void dispose() {
    _tempCtrl.dispose();
    _changesCtrl.dispose();
    _phCtrl.dispose();
    _durationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state       = ref.watch(washingProvider(widget.lotId));
    final lotAsync    = ref.watch(lotByIdProvider(widget.lotId));
    final processType = lotAsync.asData?.value?.processType ?? '';

    ref.listen(washingProvider(widget.lotId), (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
        ));
      }
    });

    // Natural process: no washing — redirect to drying
    if (processType == 'natural') {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(title: const Text('Lavado')),
        body: _NaturalRedirect(lotId: widget.lotId),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Lavado')),
      body: state.isComplete
          ? _ResultView(
              session:         state.session!,
              recommendations: state.recommendations,
              lotId:           widget.lotId,
            )
          : _FormView(
              formKey:       _formKey,
              tempCtrl:      _tempCtrl,
              changesCtrl:   _changesCtrl,
              phCtrl:        _phCtrl,
              durationCtrl:  _durationCtrl,
              notesCtrl:     _notesCtrl,
              washedAt:      _washedAt,
              isLoading:     state.isLoading,
              processType:   processType,
              onDatePicked:  (dt) => setState(() => _washedAt = dt),
              onSubmit:      _submit,
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(washingProvider(widget.lotId).notifier).register(
      waterTempC:      double.parse(_tempCtrl.text.trim()),
      waterChanges:    int.parse(_changesCtrl.text.trim()),
      effluentPhFinal: double.parse(_phCtrl.text.trim()),
      durationH:       double.parse(_durationCtrl.text.trim()),
      washedAt:        _washedAt,
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
            'El proceso natural no requiere lavado',
            style: AppTextStyles.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'La cereza natural pasa directamente al secado '
            'sin etapa de lavado.',
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
              label: const Text('Ir al secado →'),
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
    required this.tempCtrl,
    required this.changesCtrl,
    required this.phCtrl,
    required this.durationCtrl,
    required this.notesCtrl,
    required this.washedAt,
    required this.isLoading,
    required this.processType,
    required this.onDatePicked,
    required this.onSubmit,
  });

  final GlobalKey<FormState>    formKey;
  final TextEditingController   tempCtrl;
  final TextEditingController   changesCtrl;
  final TextEditingController   phCtrl;
  final TextEditingController   durationCtrl;
  final TextEditingController   notesCtrl;
  final DateTime                washedAt;
  final bool                    isLoading;
  final String                  processType;
  final void Function(DateTime) onDatePicked;
  final VoidCallback            onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (processType == 'honey_yellow') _HoneyInfoBanner(),
          const SizedBox(height: 8),
          Form(
            key: formKey,
            child: Column(
              children: [
                _card(
                  title: 'Parámetros de lavado',
                  icon: Icons.water_drop_outlined,
                  children: [
                    _numField(
                      ctrl: tempCtrl,
                      label: 'Temperatura del agua (°C)',
                      hint: '20.0',
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0 || n > 60) {
                          return 'Temperatura entre 1 y 60 °C';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _numField(
                      ctrl: changesCtrl,
                      label: 'Número de cambios de agua',
                      hint: '2',
                      decimal: false,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1 || n > 20) {
                          return 'Entre 1 y 20 cambios';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _numField(
                      ctrl: phCtrl,
                      label: 'pH del agua de enjuague final',
                      hint: '4.5',
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 2.0 || n > 9.0) {
                          return 'pH entre 2.0 y 9.0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _numField(
                      ctrl: durationCtrl,
                      label: 'Duración del lavado (horas)',
                      hint: '1.5',
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0 || n > 24) {
                          return 'Entre 0.1 y 24 h';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _DateTimeField(value: washedAt, onPicked: onDatePicked),
                  ],
                ),
                const SizedBox(height: 12),
                _card(
                  title: 'Notas',
                  icon: Icons.notes_outlined,
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
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.water_drop_rounded, size: 18),
              label: Text(
                isLoading ? 'Registrando...' : 'Registrar lavado',
                style: AppTextStyles.buttonLarge,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.aiBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.aiBlue.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
    bool decimal = true,
    required String? Function(String?) validator,
  }) =>
      TextFormField(
        controller: ctrl,
        decoration: _decor(label, hint: hint),
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
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

  static InputDecoration _decor(String label, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ── Honey info banner ──────────────────────────────────────────────────────

class _HoneyInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.caramel.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.caramel.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.caramel),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Proceso Honey: el lavado es parcial o mínimo. '
              'Registre los datos que apliquen.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ── DateTime picker ────────────────────────────────────────────────────────

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({required this.value, required this.onPicked});

  final DateTime                value;
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
          labelText: 'Fecha/hora del lavado',
          labelStyle: AppTextStyles.labelMedium,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.outlineVariant),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
  });

  final WashingSession       session;
  final List<Recommendation> recommendations;
  final String               lotId;

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
                width: 4,
                height: 24,
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
              onPressed: () => context.go(
                AppRoutes.drying.replaceFirst(':id', lotId),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text('Iniciar secado →', style: AppTextStyles.buttonLarge),
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
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.session});

  final WashingSession session;

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
            Text('Lavado registrado', style: AppTextStyles.labelLarge),
          ]),
          const SizedBox(height: 16),
          _Row('Temperatura del agua', '${session.waterTempC.toStringAsFixed(1)} °C'),
          _Row('Cambios de agua', '${session.waterChanges}'),
          _Row('pH efluente final', session.effluentPhFinal.toStringAsFixed(2)),
          _Row('Duración', '${session.durationH.toStringAsFixed(1)} h'),
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
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
