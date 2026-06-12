import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/presentation/providers/drying_provider.dart';
import 'package:special_coffee/presentation/widgets/ai/gemini_status_banner.dart';
import 'package:special_coffee/presentation/widgets/ai/recommendation_card.dart';
import 'package:special_coffee/presentation/widgets/guides/process_guide_card.dart';

// ── Screen ──────────────────────────────────────────────────────────────────

class DryingScreen extends ConsumerStatefulWidget {
  const DryingScreen({super.key, required this.lotId});

  final String lotId;

  @override
  ConsumerState<DryingScreen> createState() => _DryingScreenState();
}

class _DryingScreenState extends ConsumerState<DryingScreen> {
  static const _methods = [
    ('patio',            'Patio'),
    ('camas_africanas',  'Camas africanas'),
    ('mecanico',         'Mecánico'),
  ];

  final _formKey      = GlobalKey<FormState>();
  final _moistureCtrl = TextEditingController();
  final _tempCtrl     = TextEditingController();
  final _humCtrl      = TextEditingController();
  final _uvCtrl       = TextEditingController();
  final _scrollCtrl   = ScrollController();

  DryingNotifier get _notifier =>
      ref.read(dryingProvider(widget.lotId).notifier);

  @override
  void dispose() {
    _moistureCtrl.dispose();
    _tempCtrl.dispose();
    _humCtrl.dispose();
    _uvCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dryingProvider(widget.lotId));

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
            if (state.isAtTarget) ...[
              _CompleteCard(lotId: widget.lotId),
              const SizedBox(height: 12),
            ] else if (state.isOverDried) ...[
              _OverDriedBanner(),
              const SizedBox(height: 12),
            ],
            _buildMethodSection(state),
            const SizedBox(height: 12),
            if (state.hasReadings) ...[
              _MoistureGauge(reading: state.lastReading!),
              const SizedBox(height: 12),
              DryingPhaseCard(moisturePct: state.lastReading!.moisturePct),
              const SizedBox(height: 12),
            ],
            const _HumidityGuide(),
            const SizedBox(height: 12),
            _buildReadingForm(state),
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

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(DryingState state) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Secado'),
          Text(
            'Lote ${widget.lotId}${state.hasReadings ? " · Día ${state.lastReading!.dayNumber}" : ""}',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        if (state.hasReadings)
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reiniciar sesión',
            onPressed: () => _notifier.reset(),
          ),
      ],
    );
  }

  // ── Method selector ────────────────────────────────────────────────────────

  Widget _buildMethodSection(DryingState state) {
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
            const Icon(Icons.wb_sunny_outlined, size: 16, color: AppColors.caramel),
            const SizedBox(width: 8),
            Text('Método de secado', style: AppTextStyles.labelLarge),
            if (state.hasReadings) ...[
              const Spacer(),
              const Icon(Icons.lock_outline, size: 14, color: AppColors.disabled),
            ],
          ]),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _methods.map((m) {
                final selected  = state.dryingMethod == m.$1;
                final canChange = !state.hasReadings;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: canChange ? () => _notifier.changeDryingMethod(m.$1) : null,
                    child: ChoiceChip(
                      label: Text(m.$2),
                      selected: selected,
                      selectedColor: AppColors.warningContainer,
                      disabledColor: AppColors.surfaceVariant,
                      labelStyle: AppTextStyles.labelMedium.copyWith(
                        color: !canChange
                            ? AppColors.disabled
                            : selected
                                ? AppColors.warning
                                : AppColors.onSurfaceVariant,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      onSelected: canChange ? (_) => _notifier.changeDryingMethod(m.$1) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (state.hasReadings)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'El método no puede modificarse con lecturas activas.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  // ── Reading form ───────────────────────────────────────────────────────────

  Widget _buildReadingForm(DryingState state) {
    final last = state.lastReading;
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
              Text(
                last == null
                    ? 'Registro del día 1'
                    : 'Registro del día ${last.dayNumber + 1}',
                style: AppTextStyles.labelLarge,
              ),
              if (last != null) ...[
                const Spacer(),
                Text(
                  'Ayer: ${last.moisturePct.toStringAsFixed(1)}%',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ]),
            const SizedBox(height: 14),

            // Moisture + Temp
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _MoistureField(controller: _moistureCtrl, lastValue: last?.moisturePct)),
                const SizedBox(width: 10),
                Expanded(child: _NumberField(controller: _tempCtrl, label: 'Temp °C', hint: '28', min: 0, max: 60)),
              ],
            ),
            const SizedBox(height: 10),

            // Ambient humidity + UV
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _NumberField(controller: _humCtrl, label: 'Humedad %', hint: '65', min: 0, max: 100)),
                const SizedBox(width: 10),
                Expanded(child: _UvField(controller: _uvCtrl)),
              ],
            ),
            const SizedBox(height: 16),

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
                  state.isAnalyzing ? 'Analizando...' : 'Registrar y analizar',
                  style: AppTextStyles.buttonMedium,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.caramel,
                  foregroundColor: Colors.white,
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

  // ── Logic ──────────────────────────────────────────────────────────────────

  Future<void> _registerReading() async {
    if (!_formKey.currentState!.validate()) return;
    await _notifier.addReading(
      moisturePct: double.parse(_moistureCtrl.text.trim()),
      ambientTempC: double.parse(_tempCtrl.text.trim()),
      ambientHumidityPct: double.parse(_humCtrl.text.trim()),
      uvIndex: double.tryParse(_uvCtrl.text.trim()) ?? 0.0,
    );
    _moistureCtrl.clear();
    _tempCtrl.clear();
    _humCtrl.clear();
    _uvCtrl.clear();
  }
}

// ── Status banners ─────────────────────────────────────────────────────────

class _CompleteCard extends StatelessWidget {
  const _CompleteCard({required this.lotId});
  final String lotId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Secado completado',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.success)),
                  const SizedBox(height: 2),
                  Text(
                    'Humedad dentro del rango SCA (10.5–12.0%). Listo para almacenamiento o trilla.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Ir al detalle del lote'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HumidityGuide extends StatefulWidget {
  const _HumidityGuide();

  @override
  State<_HumidityGuide> createState() => _HumidityGuideState();
}

class _HumidityGuideState extends State<_HumidityGuide> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE1F5FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF01579B).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                const Icon(Icons.water_drop_outlined,
                    size: 15, color: Color(0xFF01579B)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('¿Cómo medir la humedad del café y ambiental?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF01579B),
                      )),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: const Color(0xFF01579B),
                ),
              ]),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GuideItem(
                    icon: Icons.grain,
                    title: 'Humedad del café (higrómetro de grano)',
                    body:
                        'Usa un higrómetro de inserción para grano (Wile 55, Pfeuffer HE 50, '
                        'Draminski o similar). Introduce la sonda directamente en el grano '
                        'pergamino húmedo, presiona firmemente y mantén 30 s. Lee el % y '
                        'anota. Meta SCA: 10.5–12.0 %. Calibra el equipo mensualmente con '
                        'estándar certificado.',
                  ),
                  const SizedBox(height: 8),
                  _GuideItem(
                    icon: Icons.thermostat_outlined,
                    title: 'Humedad ambiental (higrómetro / datalogger)',
                    body:
                        'Usa un termohigrómetro digital (Govee, Inkbird IBS-TH2, AcuRite) o '
                        'datalogger. Ubícalo a la sombra, a 1–1.5 m del suelo y lejos de '
                        'superficies de secado. Suspende secado al aire libre si HR > 80 %; '
                        'riesgo de rehidratación y hongos si HR > 85 %.\n'
                        'Fuente: Manual del Cafetero Colombiano (FNC/Cenicafé).',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  const _GuideItem({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String   title;
  final String   body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF01579B)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF01579B))),
              const SizedBox(height: 2),
              Text(body,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF01579B),
                      height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverDriedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_rounded, color: AppColors.error, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sobredesecado detectado',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.error)),
              const SizedBox(height: 2),
              Text(
                'Humedad por debajo del 10%. Retirar del área de secado inmediatamente.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Moisture gauge ─────────────────────────────────────────────────────────

class _MoistureGauge extends StatelessWidget {
  const _MoistureGauge({required this.reading});

  final DryingReading reading;

  static const _startPct = 55.0;
  static const _targetLow  = 10.5;
  static const _targetHigh = 12.0;

  @override
  Widget build(BuildContext context) {
    final progress = ((reading.moisturePct - _targetLow) /
            (_startPct - _targetLow))
        .clamp(0.0, 1.0);
    final isOnTarget = reading.moisturePct >= _targetLow &&
        reading.moisturePct <= _targetHigh;
    final isOver = reading.moisturePct < _targetLow;
    final color = isOver
        ? AppColors.error
        : isOnTarget
            ? AppColors.success
            : reading.moisturePct < 20
                ? AppColors.warning
                : AppColors.caramel;

    return Container(
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
            const Icon(Icons.water_drop_outlined,
                size: 16, color: AppColors.caramel),
            const SizedBox(width: 8),
            Text('Progreso de secado', style: AppTextStyles.labelLarge),
            const Spacer(),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '${reading.moisturePct.toStringAsFixed(1)}%',
                  style: AppTextStyles.numericMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' humedad',
                  style: AppTextStyles.bodySmall,
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Meta: 10.5–12%',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.success)),
              Text('Día ${reading.dayNumber}',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.onSurfaceVariant)),
              Text('Inicio: ~55%',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Form fields ────────────────────────────────────────────────────────────

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
        borderSide: const BorderSide(color: AppColors.caramel, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );

class _MoistureField extends StatelessWidget {
  const _MoistureField({required this.controller, this.lastValue});
  final TextEditingController controller;
  final double? lastValue;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: _fieldDecor('Humedad café %', hint: '35.0'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTextStyles.numericMedium,
      validator: (v) {
        final n = double.tryParse(v ?? '');
        if (n == null || n < 0 || n > 60) return '0–60%';
        if (lastValue != null && n > lastValue!) return '< ${lastValue!.toStringAsFixed(1)}';
        return null;
      },
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.min,
    required this.max,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: _fieldDecor(label, hint: hint),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTextStyles.numericMedium,
      validator: (v) {
        final n = double.tryParse(v ?? '');
        if (n == null || n < min || n > max) return '$min–$max';
        return null;
      },
    );
  }
}

class _UvField extends StatelessWidget {
  const _UvField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: _fieldDecor('UV (opcional)', hint: '6'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTextStyles.numericMedium,
    );
  }
}

// ── AI Recommendations ─────────────────────────────────────────────────────

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
          Text('Recomendaciones IA',
              style: AppTextStyles.displaySmall.copyWith(fontSize: 19)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.aiBlueContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${recommendations.length}',
              style:
                  AppTextStyles.aiCaption.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Basadas en el día de secado y condiciones ambientales.',
            style: AppTextStyles.bodySmall),
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
  final List<DryingReading> readings;

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
            '${readings.length} ${readings.length == 1 ? "día" : "días"}',
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
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Expanded(child: Text('Día', style: AppTextStyles.labelSmall)),
                Expanded(
                  child: Center(
                      child: Text('Humedad', style: AppTextStyles.labelSmall)),
                ),
                Expanded(
                  child: Center(
                      child: Text('Temp °C', style: AppTextStyles.labelSmall)),
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
            ...readings.reversed.indexed.map(
              (e) => _ReadingRow(reading: e.$2, isLatest: e.$1 == 0),
            ),
          ]),
        ),
      ],
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.reading, required this.isLatest});
  final DryingReading reading;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _status(reading.moisturePct);

    return Container(
      color: isLatest ? AppColors.warningContainer.withValues(alpha: 0.5) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(
          child: Text('Día ${reading.dayNumber}',
              style: AppTextStyles.numericSmall),
        ),
        Expanded(
          child: Center(
            child: Text(
              '${reading.moisturePct.toStringAsFixed(1)}%',
              style: AppTextStyles.numericSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text('${reading.ambientTempC.toStringAsFixed(1)}°',
                style: AppTextStyles.numericSmall),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(label,
                  style: AppTextStyles.labelSmall.copyWith(color: color)),
            ),
          ),
        ),
      ]),
    );
  }

  (String, Color) _status(double m) => switch (m) {
        < 10.0 => ('Sobre-sec.', AppColors.error),
        < 10.5 => ('Límite',    AppColors.warning),
        <= 12.0 => ('Óptimo',   AppColors.success),
        < 20.0 => ('Casi',      AppColors.caramel),
        < 35.0 => ('Progreso',  AppColors.info),
        _ =>      ('Inicial',   AppColors.onSurfaceVariant),
      };
}
