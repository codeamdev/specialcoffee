import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/models/alert.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/presentation/providers/fermentation_provider.dart';
import 'package:special_coffee/presentation/widgets/ai/gemini_status_banner.dart';
import 'package:special_coffee/presentation/widgets/ai/recommendation_card.dart';
import 'package:special_coffee/presentation/widgets/guides/process_guide_card.dart';

// ── Screen ─────────────────────────────────────────────────────────────────

class FermentationScreen extends ConsumerStatefulWidget {
  const FermentationScreen({super.key, required this.lotId});

  final String lotId;

  @override
  ConsumerState<FermentationScreen> createState() => _FermentationScreenState();
}

class _FermentationScreenState extends ConsumerState<FermentationScreen> {
  static const _processes = [
    ('lavado',           'Lavado'),
    ('natural',          'Natural'),
    ('anaerobic_lactic', 'Anaeróbico'),
    ('honey_yellow',     'Honey'),
  ];

  static const _mucilageOptions = [
    ('',           'N/A'),
    ('liquid',     'Líquido'),
    ('viscous',    'Viscoso'),
    ('gelatinous', 'Gelatinoso'),
    ('dry',        'Seco'),
  ];

  final _formKey      = GlobalKey<FormState>();
  final _scrollCtrl   = ScrollController();
  final _alertsKey    = GlobalKey();
  final _phCtrl       = TextEditingController();
  final _tempCtrl     = TextEditingController();
  final _hoursCtrl    = TextEditingController();
  String _mucilage    = '';

  FermentationNotifier get _notifier =>
      ref.read(fermentationProvider(widget.lotId).notifier);

  @override
  void dispose() {
    _phCtrl.dispose();
    _tempCtrl.dispose();
    _hoursCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fermentationProvider(widget.lotId));

    ref.listen(fermentationProvider(widget.lotId), (prev, next) {
      if (next.activeAlerts.isNotEmpty &&
          prev?.activeAlerts.length != next.activeAlerts.length) {
        _scrollToAlerts();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(state),
      body: SingleChildScrollView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GeminiStatusBanner(),
            _buildProcessSection(state),
            const SizedBox(height: 12),
            if (state.hasReadings)
              FermentationPhaseCard(
                ph: state.lastReading!.phValue,
                hoursElapsed: state.lastReading!.hoursElapsed,
              )
            else
              ProcessTypeGuideCard(
                key: ValueKey(state.processType),
                processType: state.processType,
              ),
            const SizedBox(height: 12),
            _buildReadingForm(state),
            if (state.activeAlerts.isNotEmpty) ...[
              const SizedBox(height: 16),
              _AlertSection(key: _alertsKey, alerts: state.activeAlerts),
            ],
            if (state.projectedHoursRemaining != null) ...[
              const SizedBox(height: 12),
              _ProjectionCard(hours: state.projectedHoursRemaining!),
            ],
            if (state.recommendations.isNotEmpty) ...[
              const SizedBox(height: 20),
              _RecsSection(recommendations: state.recommendations),
            ],
            if (state.hasReadings) ...[
              const SizedBox(height: 20),
              _ReadingHistory(readings: state.readings),
            ],
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(FermentationState state) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fermentación activa'),
          Text(
            'Lote ${widget.lotId}',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        if (state.hasCriticalAlert)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.warning_rounded, color: AppColors.error),
          ),
        if (state.hasReadings)
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reiniciar sesión',
            onPressed: () => _notifier.reset(),
          ),
      ],
    );
  }

  // ── Process selector ──────────────────────────────────────────────────────

  Widget _buildProcessSection(FermentationState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.science_outlined, size: 16, color: AppColors.caramel),
            const SizedBox(width: 8),
            Text('Tipo de proceso', style: AppTextStyles.labelLarge),
            if (state.hasReadings) ...[
              const Spacer(),
              const Icon(Icons.lock_outline, size: 14, color: AppColors.disabled),
            ],
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _processes.map((p) {
              final selected  = state.processType == p.$1;
              final canChange = !state.hasReadings;
              return GestureDetector(
                onTap: canChange ? () => _notifier.changeProcessType(p.$1) : null,
                child: ChoiceChip(
                  label: Text(p.$2),
                  selected: selected,
                  selectedColor: AppColors.aiBlueContainer,
                  disabledColor: AppColors.surfaceVariant,
                  labelStyle: AppTextStyles.labelMedium.copyWith(
                    color: !canChange
                        ? AppColors.disabled
                        : selected
                            ? AppColors.aiBlue
                            : AppColors.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  onSelected: canChange ? (_) => _notifier.changeProcessType(p.$1) : null,
                ),
              );
            }).toList(),
          ),
          if (state.hasReadings)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'El proceso no puede modificarse con lecturas activas.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  // ── Reading form ──────────────────────────────────────────────────────────

  Widget _buildReadingForm(FermentationState state) {
    final lastReading = state.lastReading;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.add_chart_outlined,
                  size: 16, color: AppColors.caramel),
              const SizedBox(width: 8),
              Text('Nueva lectura', style: AppTextStyles.labelLarge),
              if (lastReading != null) ...[
                const Spacer(),
                Text(
                  'Última: ${lastReading.hoursElapsed.toStringAsFixed(1)}h — '
                  'pH ${lastReading.phValue.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ]),
            const SizedBox(height: 14),

            // ── Main fields row ─────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _PhField(controller: _phCtrl)),
                const SizedBox(width: 10),
                Expanded(child: _TempField(controller: _tempCtrl)),
                const SizedBox(width: 10),
                Expanded(
                  child: _HoursField(
                    controller: _hoursCtrl,
                    lastReading: lastReading,
                  ),
                ),
              ],
            ),

            // ── Live pH scale ───────────────────────────────────────────
            _PhScaleIndicator(phController: _phCtrl),

            const SizedBox(height: 14),

            // ── Mucilage state ──────────────────────────────────────────
            Row(children: [
              Text('Estado del mucílago:', style: AppTextStyles.labelMedium),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _mucilageOptions.map((m) {
                final selected = _mucilage == m.$1;
                return ChoiceChip(
                  label: Text(m.$2),
                  selected: selected,
                  selectedColor: AppColors.aiBlueContainer,
                  labelStyle: AppTextStyles.labelSmall.copyWith(
                    color: selected
                        ? AppColors.aiBlue
                        : AppColors.onSurfaceVariant,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  onSelected: (_) =>
                      setState(() => _mucilage = selected ? '' : m.$1),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // ── Submit ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isAnalyzing ? null : _registerReading,
                icon: state.isAnalyzing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text(
                  state.isAnalyzing
                      ? 'Analizando...'
                      : 'Registrar y analizar',
                  style: AppTextStyles.buttonMedium,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.aiBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.aiBlue.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logic ─────────────────────────────────────────────────────────────────

  Future<void> _registerReading() async {
    if (!_formKey.currentState!.validate()) return;

    await _notifier.addReading(
      ph: double.parse(_phCtrl.text.trim()),
      tempC: double.parse(_tempCtrl.text.trim()),
      hoursElapsed: double.parse(_hoursCtrl.text.trim()),
      mucilageState: _mucilage,
    );

    // Clear the numeric fields but keep mucilage state for convenience
    _phCtrl.clear();
    _tempCtrl.clear();
    _hoursCtrl.clear();
  }

  void _scrollToAlerts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _alertsKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOut);
      }
    });
  }
}

// ── Form field widgets ────────────────────────────────────────────────────

InputDecoration _fieldDecor(String label, {String? hint}) => InputDecoration(
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
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );

class _PhField extends StatelessWidget {
  const _PhField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: _fieldDecor('pH', hint: '4.2'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTextStyles.numericMedium,
      validator: (v) {
        final n = double.tryParse(v ?? '');
        if (n == null || n < 2.0 || n > 8.0) return '2.0–8.0';
        return null;
      },
    );
  }
}

class _TempField extends StatelessWidget {
  const _TempField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: _fieldDecor('Temp °C', hint: '24'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTextStyles.numericMedium,
      validator: (v) {
        final n = double.tryParse(v ?? '');
        if (n == null || n < 10 || n > 50) return '10–50';
        return null;
      },
    );
  }
}

class _HoursField extends StatelessWidget {
  const _HoursField({required this.controller, required this.lastReading});
  final TextEditingController controller;
  final FermentationReading? lastReading;

  @override
  Widget build(BuildContext context) {
    final prevH = lastReading?.hoursElapsed;
    return TextFormField(
      controller: controller,
      decoration:
          _fieldDecor('Horas', hint: prevH != null ? '${prevH + 4}' : '12'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTextStyles.numericMedium,
      validator: (v) {
        final n = double.tryParse(v ?? '');
        if (n == null || n < 0) return '≥ 0';
        if (prevH != null && n <= prevH) return '> ${prevH}h';
        return null;
      },
    );
  }
}

// ── pH scale indicator ────────────────────────────────────────────────────

class _PhScaleIndicator extends StatelessWidget {
  const _PhScaleIndicator({required this.phController});
  final TextEditingController phController;

  static const _gradient = LinearGradient(colors: [
    Color(0xFFC62828), // pH 2.0 — critical
    Color(0xFFF57F17), // pH 3.5 — high alert
    Color(0xFFFFD54F), // pH 5.0 — normal
    Color(0xFF66BB6A), // pH 7.0 — neutral
  ]);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: phController,
      builder: (_, value, __) {
        final ph = double.tryParse(value.text);
        if (ph == null || ph < 2.0 || ph > 8.0) {
          return const SizedBox(height: 8);
        }
        final position = ((ph - 2.0) / 6.0).clamp(0.0, 1.0);
        final levelColor = _levelColor(ph);

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(builder: (context, constraints) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: _gradient,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Positioned(
                      left: (position * constraints.maxWidth - 8).clamp(
                          0.0, constraints.maxWidth - 16),
                      top: -4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: levelColor, width: 2.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4)
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('2.0',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.error)),
                  Text(
                    'pH ${ph.toStringAsFixed(2)} — ${_levelLabel(ph)}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: levelColor, fontWeight: FontWeight.w600),
                  ),
                  Text('8.0',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.info)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _levelColor(double ph) {
    if (ph < 3.5) return AppColors.error;
    if (ph < 4.0) return AppColors.warning;
    if (ph < 5.5) return AppColors.success;
    return AppColors.info;
  }

  String _levelLabel(double ph) {
    if (ph < 3.5) return 'Crítico — detener';
    if (ph < 4.0) return 'Alerta — monitorear';
    if (ph < 5.0) return 'Óptimo';
    if (ph < 6.0) return 'Normal';
    return 'Inicial';
  }
}

// ── Alert section ──────────────────────────────────────────────────────────

class _AlertSection extends StatelessWidget {
  const _AlertSection({super.key, required this.alerts});
  final List<Alert> alerts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(
            Icons.notifications_active_rounded,
            size: 18,
            color: alerts.any((a) => a.level == AlertLevel.critical)
                ? AppColors.error
                : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Text(
            'Alertas activas',
            style: AppTextStyles.labelLarge.copyWith(
              color: alerts.any((a) => a.level == AlertLevel.critical)
                  ? AppColors.error
                  : AppColors.warning,
            ),
          ),
        ]),
        const SizedBox(height: 8),
        ...alerts.map((a) => _AlertBanner(alert: a)),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.alert});
  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final isCritical = alert.level == AlertLevel.critical;
    final color = switch (alert.level) {
      AlertLevel.critical => AppColors.error,
      AlertLevel.high     => AppColors.warning,
      AlertLevel.warning  => const Color(0xFFE65100),
      _                   => AppColors.info,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: isCritical
            ? [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 8)]
            : null,
      ),
      child: Row(
        children: [
          Icon(
            isCritical
                ? Icons.error_rounded
                : Icons.warning_amber_rounded,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(alert.type),
                  style: AppTextStyles.labelLarge.copyWith(color: color),
                ),
                const SizedBox(height: 3),
                Row(children: [
                  Text('Valor: ', style: AppTextStyles.bodySmall),
                  Text(
                    alert.triggerValue.toStringAsFixed(2),
                    style: AppTextStyles.numericSmall.copyWith(
                        color: color, fontWeight: FontWeight.w700),
                  ),
                  Text('  Umbral: ', style: AppTextStyles.bodySmall),
                  Text(
                    alert.threshold.toStringAsFixed(2),
                    style: AppTextStyles.numericSmall,
                  ),
                ]),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              alert.level.name.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                  color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _title(AlertType type) => switch (type) {
        AlertType.phCritical   => 'pH crítico — detener fermentación',
        AlertType.phHigh       => 'pH bajo — monitorear cada hora',
        AlertType.tempCritical => 'Temperatura crítica del mucílago',
        AlertType.tempHigh     => 'Temperatura elevada del mucílago',
        AlertType.humidityHigh => 'Humedad ambiental elevada',
      };
}

// ── Projection card ────────────────────────────────────────────────────────

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.hours});
  final double hours;

  @override
  Widget build(BuildContext context) {
    final isNegative = hours <= 0;
    final color = isNegative ? AppColors.error : AppColors.success;
    final containerColor = isNegative
        ? AppColors.errorContainer
        : AppColors.successContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.timer_outlined, size: 26, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proyección de fin (regresión lineal)',
                style: AppTextStyles.labelMedium,
              ),
              const SizedBox(height: 3),
              isNegative
                  ? Text(
                      'pH ya superó el punto crítico — acción inmediata',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.error),
                    )
                  : RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: hours.toStringAsFixed(1),
                          style: AppTextStyles.numericLarge
                              .copyWith(color: color, fontSize: 28),
                        ),
                        TextSpan(
                          text: ' h restantes',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: color),
                        ),
                      ]),
                    ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── AI Recommendations section ─────────────────────────────────────────────

class _RecsSection extends StatelessWidget {
  const _RecsSection({required this.recommendations});
  final List<Recommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.aiBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Recomendaciones IA',
            style: AppTextStyles.displaySmall.copyWith(fontSize: 19),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.aiBlueContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${recommendations.length}',
              style: AppTextStyles.aiCaption
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          'Basadas en el contexto completo de fermentación.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 12),
        ...recommendations.indexed.map(
          (e) => RecommendationCard(
            recommendation: e.$2,
            isTopCard: e.$1 == 0,
          ),
        ),
      ],
    );
  }
}

// ── Reading history ────────────────────────────────────────────────────────

class _ReadingHistory extends StatelessWidget {
  const _ReadingHistory({required this.readings});
  final List<FermentationReading> readings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.history_rounded, size: 18, color: AppColors.caramel),
          const SizedBox(width: 8),
          Text('Historial de lecturas', style: AppTextStyles.labelLarge),
          const Spacer(),
          Text(
            '${readings.length} ${readings.length == 1 ? "registro" : "registros"}',
            style: AppTextStyles.bodySmall,
          ),
        ]),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Expanded(
                    child: Text('Horas', style: AppTextStyles.labelSmall),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('pH', style: AppTextStyles.labelSmall),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Temp °C', style: AppTextStyles.labelSmall),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('Estado', style: AppTextStyles.labelSmall),
                    ),
                  ),
                ]),
              ),
              const Divider(height: 1, color: AppColors.divider),
              // Rows — latest first
              ...readings.reversed.indexed.map((e) => _ReadingRow(
                    reading: e.$2,
                    isLatest: e.$1 == 0,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.reading, required this.isLatest});
  final FermentationReading reading;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final phColor = reading.phValue < 3.5
        ? AppColors.error
        : reading.phValue < 4.0
            ? AppColors.warning
            : AppColors.success;

    return Container(
      color:
          isLatest ? AppColors.aiBlueContainer.withValues(alpha: 0.45) : null,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(
          child: Text(
            '${reading.hoursElapsed.toStringAsFixed(1)}h',
            style: AppTextStyles.numericSmall,
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              reading.phValue.toStringAsFixed(2),
              style: AppTextStyles.numericSmall.copyWith(
                color: phColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              '${reading.tempC.toStringAsFixed(1)}°',
              style: AppTextStyles.numericSmall,
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: _PhStatusChip(ph: reading.phValue),
          ),
        ),
      ]),
    );
  }
}

class _PhStatusChip extends StatelessWidget {
  const _PhStatusChip({required this.ph});
  final double ph;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (ph) {
      < 3.5 => ('Crítico', AppColors.error),
      < 4.0 => ('Alerta',  AppColors.warning),
      < 5.0 => ('Óptimo',  AppColors.success),
      < 6.0 => ('Normal',  AppColors.info),
      _     => ('Inicial', AppColors.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}
